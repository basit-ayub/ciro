"""
CIRO Router — Signal Ingestion
Endpoint: POST /signals/ingest
Accepts batches of raw signals and feeds them to the Sentinel agent.
"""

from fastapi import APIRouter, HTTPException
from typing import List
import structlog

from backend.models.signal import Signal
from backend.agents.sentinel import get_sentinel

router = APIRouter()
log = structlog.get_logger()


@router.post("/ingest")
async def ingest_signals(signals: List[Signal]):
    """
    Ingest a batch of raw signals. Each signal is fed through the Sentinel pipeline:
    1. Keyword pre-filter (cheap, deterministic)
    2. Gemini 3 Flash LLM classifier (for signals that pass stage 1)
    3. Triage Artifacts written to Firestore for Analyst pickup

    Returns the list of created Triage Artifacts (if any crises were detected).
    """
    if not signals:
        raise HTTPException(status_code=400, detail="No signals provided")

    log.info("signals_received", count=len(signals))

    sentinel = get_sentinel()
    triages = await sentinel.process_signals(signals)

    return {
        "signals_received": len(signals),
        "triages_created": len(triages),
        "triages": [t.model_dump() for t in triages],
    }
