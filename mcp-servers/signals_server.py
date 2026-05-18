"""
CIRO MCP Server — ciro-signals
Provides tools to poll mock (or real) signal sources: social feeds, weather, traffic, CCTV.

Usage:
  python mcp-servers/signals_server.py

Env:
  MOCK_MODE=true  → reads from local JSON files in mock-data/
  MOCK_MODE=false → (future) connects to real APIs

CRITICAL: All logging MUST go to stderr. stdout is JSON-RPC.
"""

import sys
import os
import json
import logging
from datetime import datetime, timedelta
from pathlib import Path

# ── Logging to stderr ONLY ───────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [ciro-signals] %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger("ciro-signals")

# ── FastMCP Import ───────────────────────────────────────────────
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("ciro-signals")

# ── Config ───────────────────────────────────────────────────────
MOCK_MODE = os.environ.get("MOCK_MODE", "true").lower() == "true"
MOCK_DATA_DIR = Path(os.environ.get("MOCK_DATA_DIR", "mock-data"))

# ── State: track cursor position for incremental polling ─────────
_social_cursor = 0
_weather_cursor = 0
_traffic_cursor = 0
_cctv_cursor = 0


def _load_mock_json(filename: str) -> list:
    """Load a JSON file from the mock data directory."""
    filepath = MOCK_DATA_DIR / filename
    if not filepath.exists():
        logger.warning(f"Mock file not found: {filepath}")
        return []
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    return data if isinstance(data, list) else data.get("signals", [])


# ── Tool Definitions ─────────────────────────────────────────────

@mcp.tool()
def poll_social(limit: int = 10) -> str:
    """
    Poll the social media signal feed (Twitter/X-style posts).
    Returns up to `limit` new signals since last poll.
    In mock mode, reads from mock-data/social_feed.json.
    """
    global _social_cursor

    if MOCK_MODE:
        all_signals = _load_mock_json("social_feed.json")
        batch = all_signals[_social_cursor : _social_cursor + limit]
        _social_cursor = min(_social_cursor + limit, len(all_signals))
        logger.info(f"poll_social: returning {len(batch)} signals (cursor: {_social_cursor})")
        return json.dumps(batch, ensure_ascii=False, default=str)
    else:
        # TODO: Real Twitter/X API integration
        return json.dumps([], default=str)


@mcp.tool()
def poll_weather(area: str = "islamabad") -> str:
    """
    Poll weather data for a given area.
    Returns PMD-style weather payloads.
    In mock mode, reads from mock-data/weather_payloads.json.
    """
    if MOCK_MODE:
        all_payloads = _load_mock_json("weather_payloads.json")
        # Filter by area if possible
        matching = [p for p in all_payloads if area.lower() in json.dumps(p).lower()]
        result = matching if matching else all_payloads[:1]
        logger.info(f"poll_weather: returning {len(result)} payloads for {area}")
        return json.dumps(result, ensure_ascii=False, default=str)
    else:
        # TODO: Real PMD API integration
        return json.dumps([], default=str)


@mcp.tool()
def poll_traffic(area: str = "islamabad") -> str:
    """
    Poll traffic data for a given area.
    Returns Google Maps-style edge weights and throughput deltas.
    In mock mode, reads from mock-data/traffic_edges.json.
    """
    if MOCK_MODE:
        all_edges = _load_mock_json("traffic_edges.json")
        matching = [e for e in all_edges if area.lower() in json.dumps(e).lower()]
        result = matching if matching else all_edges[:3]
        logger.info(f"poll_traffic: returning {len(result)} edges for {area}")
        return json.dumps(result, ensure_ascii=False, default=str)
    else:
        # TODO: Real Google Maps traffic API
        return json.dumps([], default=str)


@mcp.tool()
def poll_cctv(location: str = "g10") -> str:
    """
    Poll CCTV detection events for a given location.
    Returns detection events (vehicle stationary, thermal spike, smoke, etc.).
    In mock mode, returns pre-defined detection events.
    """
    if MOCK_MODE:
        # Pre-defined CCTV events for demo scenarios
        events = [
            {
                "camera_id": f"cctv-{location}-001",
                "location": location.upper(),
                "timestamp": datetime.utcnow().isoformat(),
                "detection_type": "vehicles_stationary",
                "details": "3 vehicles stationary > 4min at junction",
                "confidence": 0.87,
            }
        ]
        logger.info(f"poll_cctv: returning {len(events)} events for {location}")
        return json.dumps(events, ensure_ascii=False, default=str)
    else:
        # TODO: Real CCTV integration
        return json.dumps([], default=str)


@mcp.tool()
def reset_cursors() -> str:
    """Reset all polling cursors to the beginning. Useful for demo reruns."""
    global _social_cursor, _weather_cursor, _traffic_cursor, _cctv_cursor
    _social_cursor = 0
    _weather_cursor = 0
    _traffic_cursor = 0
    _cctv_cursor = 0
    logger.info("All cursors reset to 0")
    return json.dumps({"status": "cursors_reset"})


# ── Main ─────────────────────────────────────────────────────────
if __name__ == "__main__":
    logger.info(f"Starting ciro-signals MCP server (MOCK_MODE={MOCK_MODE})")
    mcp.run()
