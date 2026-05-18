"""
CIRO Models — Triage Artifact
Output of the Sentinel agent. Represents a detected crisis signal awaiting Analyst review.
"""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid


class TriageArtifact(BaseModel):
    """Sentinel output — a flagged crisis signal with classification metadata."""

    triage_id: str = Field(default_factory=lambda: f"triage-{uuid.uuid4().hex[:8]}")
    signal_id: str = Field(description="ID of the source signal that triggered this triage")
    is_crisis: bool = True
    crisis_type: str = Field(
        description="Detected crisis type: urban_flooding, heatwave, road_blockage, "
                    "accident, fire, infrastructure_failure, landslide, structural_collapse"
    )
    location_text: Optional[str] = Field(
        default=None,
        description="Extracted location string as mentioned in the original signal",
    )
    geo: Optional[dict] = Field(
        default=None,
        description="Resolved coordinates: {lat, lon}",
    )
    language_detected: Optional[str] = Field(
        default=None,
        description="BCP-47 language tag of the original signal",
    )
    urgency_signal: float = Field(
        ge=0.0, le=1.0,
        description="Sentinel confidence in crisis detection (0.0–1.0)",
    )
    evidence_phrase: Optional[str] = Field(
        default=None,
        description="The specific phrase that triggered detection, in original language",
    )
    source_text: Optional[str] = Field(
        default=None,
        description="Full original text of the signal for Analyst context",
    )
    media_url: Optional[str] = Field(
        default=None,
        description="URL to attached photo/video if any",
    )
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    agent: str = "sentinel"
    status: str = Field(default="pending", description="pending | analyzing | resolved")

    def to_firestore(self) -> dict:
        """Serialize for Firestore write."""
        data = self.model_dump()
        data["timestamp"] = self.timestamp.isoformat()
        return data
