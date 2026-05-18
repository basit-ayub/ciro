"""
CIRO Router — Health & Metrics
Endpoints: GET /health, GET /metrics
"""

from fastapi import APIRouter
from datetime import datetime

from backend.config import get_settings

router = APIRouter()


@router.get("/health")
async def health_check():
    """Health check endpoint. Returns 200 if service is running."""
    settings = get_settings()
    return {
        "status": "healthy",
        "service": "CIRO Backend",
        "version": settings.app_version,
        "demo_mode": settings.demo_mode,
        "timestamp": datetime.utcnow().isoformat(),
    }


@router.get("/metrics")
async def metrics():
    """Basic metrics endpoint."""
    return {
        "uptime_seconds": 0,  # TODO: track actual uptime
        "signals_processed": 0,
        "triages_created": 0,
        "situations_assessed": 0,
        "actions_executed": 0,
        "timestamp": datetime.utcnow().isoformat(),
    }
