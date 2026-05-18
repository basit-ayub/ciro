"""
CIRO Models — Situation Artifact
Output of the Analyst agent. Represents a fully assessed crisis situation with confidence scoring.
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
import uuid


class ConfidenceBreakdown(BaseModel):
    """Weighted confidence formula components — exposed in the UI for transparency."""

    signal_corroboration: float = Field(
        ge=0.0, le=1.0,
        description="0.30 weight — count of independent confirming signals / 5",
    )
    weather_concordance: float = Field(
        ge=0.0, le=1.0,
        description="0.25 weight — 1.0 if weather matches crisis precursor",
    )
    traffic_concordance: float = Field(
        ge=0.0, le=1.0,
        description="0.20 weight — 1.0 if traffic shows expected anomaly",
    )
    visual_confirmation: float = Field(
        ge=0.0, le=1.0,
        description="0.15 weight — 1.0 if photo/video confirms, 0.5 if ambiguous",
    )
    historical_match: float = Field(
        ge=0.0, le=1.0,
        description="0.10 weight — 1.0 if memory match > 0.8 similarity",
    )


class ImpactEstimate(BaseModel):
    """Estimated impact vectors for the crisis."""

    persons_at_risk: int = 0
    vehicles_likely_affected: int = 0
    infrastructure_threatened: List[str] = Field(default_factory=list)
    estimated_duration_min: int = 0


class SituationArtifact(BaseModel):
    """Analyst output — a fully assessed crisis with confidence, severity, and impact."""

    situation_id: str = Field(default_factory=lambda: f"sit-{uuid.uuid4().hex[:8]}")
    triage_id: str = Field(description="ID of the triggering Triage Artifact")
    incident_type: str
    confidence: float = Field(ge=0.0, le=1.0)
    confidence_breakdown: ConfidenceBreakdown
    severity: int = Field(ge=1, le=5, description="1=local nuisance, 5=mass casualty risk")
    geo: dict = Field(description="{lat, lon, radius_m}")
    impact_estimate: ImpactEstimate
    reasoning_trace: str = Field(
        description="3–5 sentence explanation in plain English of how the assessment was made"
    )
    language_for_alerts: str = Field(
        default="ur-Latn-PK",
        description="BCP-47 language to use for citizen alerts",
    )
    evidence_links: List[str] = Field(
        default_factory=list,
        description="URLs to supporting evidence (photos, signals, etc.)",
    )
    memory_match: Optional[dict] = Field(
        default=None,
        description="Past incident match: {incident_id, similarity, summary}",
    )
    vision_analysis: Optional[dict] = Field(
        default=None,
        description="Gemini 3 Pro vision output if photos were analyzed",
    )
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    agent: str = "analyst"
    status: str = Field(default="assessed", description="assessed | acting | resolved")

    def to_firestore(self) -> dict:
        """Serialize for Firestore write."""
        data = self.model_dump()
        data["timestamp"] = self.timestamp.isoformat()
        return data
