"""
CIRO Router — Hell Mode
Endpoint: POST /hell-mode/trigger
Triggers 5 simultaneous crisis scenarios across Pakistan.
"""

from fastapi import APIRouter, HTTPException
import structlog
import asyncio
import json
from pathlib import Path

from backend.agents.sentinel import get_sentinel
from backend.agents.analyst import get_analyst
from backend.agents.commander import get_commander
from backend.models.signal import Signal, SignalSource

router = APIRouter()
log = structlog.get_logger()


@router.post("/trigger")
async def trigger_hell_mode():
    """
    HELL MODE: Trigger 5 simultaneous crises across Pakistan.
    Runs the Sentinel, then parallelizes the Analyst evaluations, and finally Commander actions.
    """
    log.info("hell_mode_triggered", status="started")
    
    # 1. Load mock data
    mock_dir = Path("mock-data")
    try:
        with open(mock_dir / "scenarios.json", "r") as f:
            scenarios = json.load(f)
        with open(mock_dir / "social_feed.json", "r") as f:
            feed = json.load(f)
    except Exception as e:
        log.error("hell_mode_data_load_failed", error=str(e))
        raise HTTPException(status_code=500, detail="Failed to load mock data")

    # Collect all signal IDs from scenarios
    target_signal_ids = set()
    for s in scenarios:
        target_signal_ids.update(s.get("signal_ids", []))

    # Build Signal objects
    raw_signals = []
    for s_data in feed:
        if s_data.get("signal_id") in target_signal_ids:
            try:
                # Convert 'social' string to enum if needed, or rely on Pydantic's coercion
                s_data["source"] = SignalSource.SOCIAL
                raw_signals.append(Signal(**s_data))
            except Exception as e:
                log.warning("signal_parse_failed", error=str(e), signal_id=s_data.get("signal_id"))

    log.info("hell_mode_signals_loaded", count=len(raw_signals))

    # 2. Sentinel Processing (Batch)
    sentinel = get_sentinel()
    triages = await sentinel.process_signals(raw_signals)
    
    if not triages:
        return {"status": "no_crises_detected", "triages": 0}

    # 3. Parallel Analyst Processing (Wow #5)
    analyst = get_analyst()
    log.info("hell_mode_analyst_parallel", triage_count=len(triages))
    
    # Run all analyst assessments concurrently
    situation_tasks = [analyst.assess_crisis(t.triage_id) for t in triages]
    situations = await asyncio.gather(*situation_tasks, return_exceptions=True)
    
    # Filter out failures
    valid_situations = [s for s in situations if s and not isinstance(s, Exception)]

    # 4. Commander Processing (Priority Queue Simulation)
    # Sort situations by severity (highest first) to simulate priority queue
    valid_situations.sort(key=lambda s: s.severity, reverse=True)
    
    commander = get_commander()
    log.info("hell_mode_commander_sequential", situation_count=len(valid_situations))
    
    actions = []
    # Execute commander actions sequentially in priority order to simulate resource constraints
    for sit in valid_situations:
        action = await commander.generate_and_execute_plan(sit.situation_id)
        if action:
            actions.append(action)

    log.info("hell_mode_completed", situations=len(valid_situations), actions=len(actions))

    return {
        "status": "hell_mode_completed",
        "message": "Processed 5 simultaneous crises successfully.",
        "metrics": {
            "signals_processed": len(raw_signals),
            "triages_generated": len(triages),
            "situations_assessed": len(valid_situations),
            "actions_executed": len(actions)
        }
    }
