"""
CIRO Router — Agent SSE Stream
Endpoint: GET /stream/agents
Server-Sent Events stream for the Live Reasoning Stadium UI.
Streams agent_id | step | tool_call | tokens events.
"""

import asyncio
import json
from fastapi import APIRouter
from sse_starlette.sse import EventSourceResponse
import structlog

from backend.agents.sentinel import sentinel_events

router = APIRouter()
log = structlog.get_logger()

# Global event queues for each agent (Sentinel queue is in sentinel.py)
analyst_events: asyncio.Queue = asyncio.Queue(maxsize=100)
commander_events: asyncio.Queue = asyncio.Queue(maxsize=100)


async def _event_generator():
    """
    Merge events from all 3 agent queues into a single SSE stream.
    Each event is JSON: {agent, step, message, timestamp, tool_call?, tokens?}
    """
    while True:
        # Check all three queues with a short timeout
        for queue, agent_name in [
            (sentinel_events, "sentinel"),
            (analyst_events, "analyst"),
            (commander_events, "commander"),
        ]:
            try:
                event = queue.get_nowait()
                yield {
                    "event": event.get("agent", agent_name),
                    "data": json.dumps(event, default=str),
                }
            except asyncio.QueueEmpty:
                continue

        # Small sleep to prevent busy-waiting
        await asyncio.sleep(0.1)


@router.get("/agents")
async def stream_agents():
    """
    SSE endpoint for the Live Reasoning Stadium.
    Clients connect and receive a continuous stream of agent reasoning events:
    - Sentinel: anomaly detection steps, keyword matches, LLM classifications
    - Analyst: cross-referencing, confidence calculation, vision analysis
    - Commander: plan generation, tool calls, verification results
    """
    return EventSourceResponse(_event_generator())
