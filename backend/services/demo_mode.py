"""
CIRO Services — Demo Mode
Prompt-hash caching system for stable demo presentations.
When DEMO_MODE=true:
1. Caches Gemini responses keyed by prompt hash — first run is real, second serves cached
2. Disables retries that could fail loudly
3. Adds graceful 500ms artificial delays so streaming feels natural
4. Enables pre-loaded mock scenarios
"""

import hashlib
import json
import asyncio
import structlog
from pathlib import Path
from typing import Optional

from backend.config import get_settings

log = structlog.get_logger()

# In-memory cache (persisted to disk for cross-restart stability)
_cache: dict = {}
_cache_file = Path("logs/demo_cache.json")


def _hash_prompt(prompt: str) -> str:
    """Generate a stable hash key for a prompt."""
    return hashlib.sha256(prompt.encode("utf-8")).hexdigest()[:16]


def get_cached_response(prompt: str) -> Optional[dict]:
    """Check if we have a cached response for this prompt hash."""
    settings = get_settings()
    if not settings.demo_mode:
        return None

    key = _hash_prompt(prompt)
    if key in _cache:
        log.info("demo_cache_hit", key=key)
        return _cache[key]

    # Try disk cache
    if _cache_file.exists():
        try:
            with open(_cache_file, "r") as f:
                disk_cache = json.load(f)
            if key in disk_cache:
                _cache[key] = disk_cache[key]
                log.info("demo_disk_cache_hit", key=key)
                return disk_cache[key]
        except Exception:
            pass

    return None


def cache_response(prompt: str, response: dict):
    """Store a response in the demo cache."""
    settings = get_settings()
    if not settings.demo_mode:
        return

    key = _hash_prompt(prompt)
    _cache[key] = response

    # Persist to disk
    try:
        disk_cache = {}
        if _cache_file.exists():
            with open(_cache_file, "r") as f:
                disk_cache = json.load(f)
        disk_cache[key] = response
        _cache_file.parent.mkdir(parents=True, exist_ok=True)
        with open(_cache_file, "w") as f:
            json.dump(disk_cache, f, indent=2, default=str)
        log.info("demo_cache_stored", key=key)
    except Exception as e:
        log.warning("demo_cache_write_failed", error=str(e))


async def demo_delay(seconds: float = 0.5):
    """Add artificial delay in demo mode for natural-feeling streaming."""
    settings = get_settings()
    if settings.demo_mode:
        await asyncio.sleep(seconds)

def load_mock_scenario(scenario_id: int) -> Optional[dict]:
    """Load a predefined mock scenario for stable demos."""
    scenario_path = Path("mock-data/scenarios.json")
    if not scenario_path.exists():
        log.warning("mock_scenarios_missing", path=str(scenario_path))
        return None
        
    try:
        with open(scenario_path, "r") as f:
            scenarios = json.load(f)
            for s in scenarios:
                if s.get("id") == scenario_id:
                    log.info("mock_scenario_loaded", scenario_id=scenario_id, name=s.get("name"))
                    return s
    except Exception as e:
        log.error("mock_scenario_load_error", error=str(e))
        
    return None
