"""
CIRO Backend — Central Configuration
Manages all environment variables, constants, and the DEMO_MODE toggle.
Uses pydantic-settings for validated, typed configuration.
"""

from pydantic_settings import BaseSettings
from pydantic import Field
from typing import Optional
from functools import lru_cache


class Settings(BaseSettings):
    """Central config loaded from environment variables / .env file."""

    # ── Application ──────────────────────────────────────────────
    app_name: str = "CIRO — Crisis Intelligence & Response Orchestrator"
    app_version: str = "0.1.0"
    debug: bool = False
    demo_mode: bool = Field(default=False, description="Enable cached responses + mock scenarios")

    # ── Google AI / Gemini ────────────────────────────────────────
    google_api_key: str = Field(default="", description="Gemini 3 API key")
    gemini_pro_model: str = "gemini-3-pro"
    gemini_flash_model: str = "gemini-3-flash"
    gemini_thinking_budget: int = 2048

    # ── Google Maps ──────────────────────────────────────────────
    google_maps_api_key: str = Field(default="", description="Maps Routes API key")

    # ── Firebase ─────────────────────────────────────────────────
    firebase_project_id: str = Field(default="", description="Firebase project ID")
    firebase_storage_bucket: str = Field(default="", description="Cloud Storage bucket")
    firebase_credentials_path: Optional[str] = Field(
        default=None, description="Path to Firebase service account JSON"
    )

    # ── Twilio ───────────────────────────────────────────────────
    twilio_account_sid: str = Field(default="", description="Twilio Account SID")
    twilio_auth_token: str = Field(default="", description="Twilio Auth Token")
    twilio_phone_number: str = Field(default="", description="Twilio phone number")
    twilio_whatsapp_number: str = Field(default="", description="Twilio WhatsApp number")

    # ── FCM ───────────────────────────────────────────────────────
    fcm_server_key: str = Field(default="", description="FCM server key for push")

    # ── Telegram (Stretch) ────────────────────────────────────────
    telegram_bot_token: str = Field(default="", description="Telegram Bot API token")

    # ── GCP ───────────────────────────────────────────────────────
    gcp_project_id: str = Field(default="", description="GCP project for Cloud Run")

    # ── Sentinel Config ──────────────────────────────────────────
    sentinel_poll_interval_sec: float = 5.0
    sentinel_confidence_threshold: float = 0.6

    # ── Analyst Config ───────────────────────────────────────────
    analyst_confidence_threshold: float = 0.75
    analyst_severity_threshold: int = 4

    # ── Paths ────────────────────────────────────────────────────
    mock_data_dir: str = "mock-data"
    lexicon_path: str = "backend/lexicons/crisis_phrases.yml"
    prompts_dir: str = "backend/prompts"

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
    }


@lru_cache()
def get_settings() -> Settings:
    """Cached singleton — call this everywhere instead of instantiating Settings()."""
    return Settings()
