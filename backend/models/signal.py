"""
CIRO Models — Raw Signal
Represents a single incoming signal from any source (social, weather, traffic, CCTV, voice).
"""

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum
import uuid


class SignalSource(str, Enum):
    SOCIAL = "social"
    WEATHER = "weather"
    TRAFFIC = "traffic"
    CCTV = "cctv"
    VOICE = "voice"
    CITIZEN_REPORT = "citizen_report"


class Signal(BaseModel):
    """A single raw input signal before any processing."""

    signal_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    source: SignalSource
    text: str = Field(description="Raw text content of the signal")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    geo: Optional[dict] = Field(
        default=None,
        description="Geographic info: {lat, lon} or {area_name}",
    )
    language: Optional[str] = Field(
        default=None,
        description="Detected language (BCP-47), e.g., 'ur-Latn-PK' for Roman Urdu",
    )
    media_url: Optional[str] = Field(
        default=None,
        description="URL to attached photo/video if any",
    )
    metadata: Optional[dict] = Field(
        default=None,
        description="Source-specific metadata (e.g., rainfall_mm for weather)",
    )

    model_config = {"json_schema_extra": {"examples": [
        {
            "signal_id": "sig-001",
            "source": "social",
            "text": "G-10 Markaz mein paani bhar gaya hai, gaariyan phans gayi hain bhai",
            "timestamp": "2026-05-17T14:32:09Z",
            "geo": {"lat": 33.6912, "lon": 73.0118, "area_name": "G-10 Markaz, Islamabad"},
            "language": "ur-Latn-PK",
        }
    ]}}
