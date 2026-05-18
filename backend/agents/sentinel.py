"""
CIRO Agent — The Sentinel
Agent 1: Real-time anomaly detection using a two-stage pipeline.
  Stage 1: Keyword pre-filter (cheap, deterministic)
  Stage 2: Gemini 3 Flash LLM classifier (only for signals passing Stage 1)

Runs as an async loop polling every 5 seconds via the ciro-signals MCP server.
Outputs Triage Artifacts to Firestore `triage_queue/{id}`.
"""

import re
import json
import asyncio
import yaml
import structlog
from pathlib import Path
from typing import List, Optional
from datetime import datetime

from backend.config import get_settings
from backend.models.signal import Signal
from backend.models.triage import TriageArtifact
from backend.services.gemini_client import get_gemini_client
from backend.services import firestore_client

log = structlog.get_logger()

# ── Module State ─────────────────────────────────────────────────
_sentinel_running = False
_sentinel_task: Optional[asyncio.Task] = None

# ── Event bus for SSE streaming ──────────────────────────────────
sentinel_events: asyncio.Queue = asyncio.Queue(maxsize=100)


class SentinelAgent:
    """Two-stage crisis detection pipeline."""

    def __init__(self):
        settings = get_settings()
        self.poll_interval = settings.sentinel_poll_interval_sec
        self.confidence_threshold = settings.sentinel_confidence_threshold
        self.gemini = get_gemini_client()
        self.lexicon = self._load_lexicon()
        self.system_prompt = self._load_prompt()
        self._processed_ids: set = set()  # Avoid reprocessing same signals

    def _load_lexicon(self) -> dict:
        """Load the crisis keyword lexicon from YAML."""
        settings = get_settings()
        lexicon_path = Path(settings.lexicon_path)
        if not lexicon_path.exists():
            log.warning("lexicon_not_found", path=str(lexicon_path))
            return {}
        with open(lexicon_path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)

    def _load_prompt(self) -> str:
        """Load the Sentinel system prompt."""
        settings = get_settings()
        prompt_path = Path(settings.prompts_dir) / "sentinel.txt"
        if not prompt_path.exists():
            log.warning("sentinel_prompt_not_found", path=str(prompt_path))
            return ""
        with open(prompt_path, "r", encoding="utf-8") as f:
            return f.read()

    def _build_patterns(self) -> List[re.Pattern]:
        """Compile regex patterns from the lexicon for fast matching."""
        patterns = []
        for crisis_type, languages in self.lexicon.items():
            if not isinstance(languages, dict):
                continue
            for lang, phrases in languages.items():
                if not isinstance(phrases, list):
                    continue
                for phrase in phrases:
                    try:
                        patterns.append(
                            (re.compile(re.escape(phrase.lower())), crisis_type)
                        )
                    except re.error:
                        pass
        return patterns

    def keyword_prefilter(self, signal: Signal) -> Optional[str]:
        """
        Stage 1: Cheap keyword matching.
        Returns the matched crisis_type or None if no match.
        """
        text_lower = signal.text.lower()
        patterns = self._build_patterns()
        for pattern, crisis_type in patterns:
            if pattern.search(text_lower):
                return crisis_type
        return None

    async def classify_with_llm(self, signals: List[Signal]) -> List[dict]:
        """
        Stage 2: Gemini 3 Flash classification.
        Takes signals that passed the keyword filter and classifies them.
        """
        if not signals:
            return []

        # Format signals for the LLM
        signal_batch = json.dumps([
            {
                "signal_id": s.signal_id,
                "source": s.source,
                "text": s.text,
                "timestamp": s.timestamp.isoformat(),
                "geo": s.geo,
                "language": s.language,
            }
            for s in signals
        ], ensure_ascii=False)

        result = await self.gemini.classify_signal(self.system_prompt, signal_batch)

        # Handle list vs dict response
        if isinstance(result, dict) and "results" in result:
            return result["results"]
        elif isinstance(result, list):
            return result
        elif isinstance(result, dict):
            return [result]
        return []

    async def process_signals(self, signals: List[Signal]) -> List[TriageArtifact]:
        """
        Full two-stage pipeline: keyword filter → LLM classify → write Triage Artifacts.
        Returns list of created TriageArtifacts.
        """
        if not signals:
            return []

        # Filter out already-processed signals
        new_signals = [s for s in signals if s.signal_id not in self._processed_ids]
        if not new_signals:
            return []

        await self._emit_event("polling", f"Processing {len(new_signals)} new signals...")

        # Stage 1: Keyword pre-filter
        keyword_hits = []
        for signal in new_signals:
            matched_type = self.keyword_prefilter(signal)
            if matched_type:
                keyword_hits.append((signal, matched_type))
                log.info(
                    "keyword_hit",
                    signal_id=signal.signal_id,
                    crisis_type=matched_type,
                    text_preview=signal.text[:80],
                )

        await self._emit_event(
            "keyword_filter",
            f"Stage 1: {len(keyword_hits)}/{len(new_signals)} signals passed keyword filter"
        )

        if not keyword_hits:
            for s in new_signals:
                self._processed_ids.add(s.signal_id)
            return []

        # Stage 2: LLM classification
        await self._emit_event("llm_classify", "Stage 2: Sending to Gemini 3 Flash for classification...")
        
        classified = await self.classify_with_llm([s for s, _ in keyword_hits])

        # Build Triage Artifacts from classified results
        triages = []
        for classification in classified:
            if not classification.get("is_crisis", False):
                continue

            urgency = classification.get("urgency_signal", 0.0)
            if urgency < self.confidence_threshold:
                log.info(
                    "below_threshold",
                    signal_id=classification.get("signal_id"),
                    urgency=urgency,
                )
                continue

            # Find the original signal
            original_signal = None
            for s, _ in keyword_hits:
                if s.signal_id == classification.get("signal_id"):
                    original_signal = s
                    break

            triage = TriageArtifact(
                signal_id=classification.get("signal_id", "unknown"),
                crisis_type=classification.get("crisis_type", "unknown"),
                location_text=classification.get("location_text"),
                geo=original_signal.geo if original_signal else None,
                language_detected=classification.get("language_detected"),
                urgency_signal=urgency,
                evidence_phrase=classification.get("evidence_phrase"),
                source_text=original_signal.text if original_signal else None,
                media_url=original_signal.media_url if original_signal else None,
            )

            # Write to Firestore
            try:
                firestore_client.write_triage(triage.to_firestore())
                triages.append(triage)
                await self._emit_event(
                    "triage_created",
                    f"🚨 Crisis detected: {triage.crisis_type} at {triage.location_text} "
                    f"(urgency: {triage.urgency_signal:.2f})"
                )
            except Exception as e:
                log.error("triage_write_failed", error=str(e), triage_id=triage.triage_id)

        # Mark all processed
        for s in new_signals:
            self._processed_ids.add(s.signal_id)

        log.info(
            "sentinel_cycle_complete",
            signals_processed=len(new_signals),
            keyword_hits=len(keyword_hits),
            triages_created=len(triages),
        )

        return triages

    async def _emit_event(self, step: str, message: str):
        """Push an event to the SSE stream for the Live Reasoning Stadium."""
        event = {
            "agent": "sentinel",
            "step": step,
            "message": message,
            "timestamp": datetime.utcnow().isoformat(),
        }
        try:
            sentinel_events.put_nowait(event)
        except asyncio.QueueFull:
            # Drop oldest if queue is full
            try:
                sentinel_events.get_nowait()
                sentinel_events.put_nowait(event)
            except asyncio.QueueEmpty:
                pass


# ── Singleton ────────────────────────────────────────────────────
_agent: Optional[SentinelAgent] = None


def get_sentinel() -> SentinelAgent:
    """Get or create the singleton Sentinel agent."""
    global _agent
    if _agent is None:
        _agent = SentinelAgent()
    return _agent
