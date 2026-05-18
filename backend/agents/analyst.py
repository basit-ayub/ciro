"""
CIRO Agent — The Analyst
Agent 2: Deep reasoning and crisis assessment.
Reads Triage Artifacts from Sentinel, gathers multi-modal context (weather, traffic, vision, history),
and uses Gemini 3 Pro (Thinking mode) to assess severity, impact, and calculate a 5-factor confidence score.
Outputs Situation Artifacts.
"""

import asyncio
import json
import structlog
from datetime import datetime
from typing import Optional, List

from backend.config import get_settings
from backend.models.triage import TriageArtifact
from backend.models.situation import SituationArtifact, ConfidenceBreakdown, ImpactEstimate
from backend.services.gemini_client import get_gemini_client
from backend.services import firestore_client
from backend.services.confidence import calculate_confidence, ConfidenceInputs
from backend.routers.stream import analyst_events

log = structlog.get_logger()

class AnalystAgent:
    """The deep reasoning crisis assessor."""

    def __init__(self):
        self.gemini = get_gemini_client()
        self.settings = get_settings()
        self.system_prompt = self._load_prompt()

    def _load_prompt(self) -> str:
        with open(f"{self.settings.prompts_dir}/analyst.txt", "r", encoding="utf-8") as f:
            return f.read()

    async def _gather_context(self, triage: dict) -> dict:
        """Gather context from mock sources/MCPs based on location."""
        # For hackathon demo, we simulate fetching context from the MCP servers.
        # In a full MCP host setup, we'd use the mcp client to call poll_weather etc.
        geo = triage.get("geo", {})
        lat = geo.get("lat")
        lon = geo.get("lon")
        
        await self._emit_event("gathering_context", f"Fetching weather, traffic, and history for {triage.get('location_text', 'unknown area')}")
        
        # Simulated context gathering
        # Normally this would be: mcp.call_tool("ciro-signals", "poll_weather", {"area": "..."})
        # We will load from mock data directly to simulate the Analyst receiving it.
        context = {
            "weather": {"status": "normal"},
            "traffic": {"status": "normal"},
            "history": []
        }
        
        # Load mock weather
        try:
            import json
            from pathlib import Path
            mock_dir = Path("mock-data")
            if (mock_dir / "weather_payloads.json").exists():
                with open(mock_dir / "weather_payloads.json", "r") as f:
                    weather_data = json.load(f)
                    # Pick first for simplicity if area not matched, else match area
                    context["weather"] = weather_data[0] 
        except Exception:
            pass

        # Load mock traffic
        try:
            import json
            from pathlib import Path
            mock_dir = Path("mock-data")
            if (mock_dir / "traffic_edges.json").exists():
                with open(mock_dir / "traffic_edges.json", "r") as f:
                    traffic_data = json.load(f)
                    context["traffic"] = traffic_data[:2]
        except Exception:
            pass
            
        return context

    async def assess_crisis(self, triage_id: str) -> Optional[SituationArtifact]:
        """Process a single Triage Artifact into a Situation Artifact."""
        triage_dict = firestore_client.get_triage(triage_id)
        if not triage_dict:
            log.error("triage_not_found", triage_id=triage_id)
            return None
            
        await self._emit_event("assessment_started", f"Analyzing triage {triage_id} ({triage_dict.get('crisis_type')})")
        
        # Update status to analyzing
        firestore_client.update_triage_status(triage_id, "analyzing")
        
        context = await self._gather_context(triage_dict)
        
        # Prepare context for Gemini
        llm_context = json.dumps({
            "triage": triage_dict,
            "weather_context": context.get("weather"),
            "traffic_context": context.get("traffic"),
            "historical_context": context.get("history")
        }, default=str)
        
        await self._emit_event("reasoning", "Thinking... Cross-referencing multi-modal context.")
        
        # Call Gemini 3 Pro with Thinking mode
        result = await self.gemini.analyze_situation(
            system_prompt=self.system_prompt,
            context=llm_context,
            image_url=triage_dict.get("media_url")
        )
        
        if "error" in result:
            await self._emit_event("error", f"Reasoning failed: {result['error']}")
            firestore_client.update_triage_status(triage_id, "failed")
            return None
            
        # Extract fields
        incident_type = result.get("incident_type", triage_dict.get("crisis_type"))
        severity = result.get("severity", 1)
        reasoning = result.get("reasoning_trace", "Assessed via Gemini 3 Pro.")
        impact_est = result.get("impact_estimate", {})
        
        # Calculate confidence using the specific formula
        # We derive inputs based on the LLM's assessment of the context
        cb = result.get("confidence_breakdown", {})
        inputs = ConfidenceInputs(
            independent_signal_count=2, # Mocked
            weather_matches_precursor=bool(cb.get("weather_concordance", 0) > 0),
            traffic_shows_anomaly=bool(cb.get("traffic_concordance", 0) > 0),
            visual_confirmation=float(cb.get("visual_confirmation", 0.0)),
            historical_similarity=float(cb.get("historical_match", 0.0))
        )
        conf_result = calculate_confidence(inputs)
        
        await self._emit_event("confidence_calculated", f"Confidence score: {conf_result['confidence']:.2f} (Severity: {severity})")
        
        # Build Situation Artifact
        situation = SituationArtifact(
            triage_id=triage_id,
            incident_type=incident_type,
            confidence=conf_result["confidence"],
            confidence_breakdown=ConfidenceBreakdown(**conf_result["breakdown"]),
            severity=severity,
            geo=result.get("geo", triage_dict.get("geo", {"lat": 0, "lon": 0, "radius_m": 1000})),
            impact_estimate=ImpactEstimate(
                persons_at_risk=impact_est.get("persons_at_risk", 0),
                vehicles_likely_affected=impact_est.get("vehicles_likely_affected", 0),
                infrastructure_threatened=impact_est.get("infrastructure_threatened", []),
                estimated_duration_min=impact_est.get("estimated_duration_min", 60)
            ),
            reasoning_trace=reasoning,
            language_for_alerts=result.get("language_for_alerts", triage_dict.get("language_detected", "ur-Latn-PK")),
            evidence_links=[triage_dict.get("media_url")] if triage_dict.get("media_url") else []
        )
        
        # Write to Firestore
        firestore_client.write_situation(situation.to_firestore())
        firestore_client.update_triage_status(triage_id, "resolved")
        
        await self._emit_event("assessment_complete", f"Situation {situation.situation_id} created. Handing off to Commander.")
        return situation

    async def _emit_event(self, step: str, message: str):
        """Push an event to the SSE stream."""
        event = {
            "agent": "analyst",
            "step": step,
            "message": message,
            "timestamp": datetime.utcnow().isoformat(),
        }
        try:
            analyst_events.put_nowait(event)
        except asyncio.QueueFull:
            try:
                analyst_events.get_nowait()
                analyst_events.put_nowait(event)
            except asyncio.QueueEmpty:
                pass

# Singleton
_agent: Optional[AnalystAgent] = None

def get_analyst() -> AnalystAgent:
    global _agent
    if _agent is None:
        _agent = AnalystAgent()
    return _agent
