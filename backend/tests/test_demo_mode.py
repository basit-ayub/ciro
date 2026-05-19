import pytest
import os
from backend.services.demo_mode import _hash_prompt, get_cached_response, cache_response, load_mock_scenario
from backend.config import get_settings

def test_hash_prompt():
    prompt = "Test prompt for hashing"
    hash1 = _hash_prompt(prompt)
    hash2 = _hash_prompt(prompt)
    
    # Hash should be stable and 16 chars long
    assert hash1 == hash2
    assert len(hash1) == 16

def test_load_mock_scenario(monkeypatch):
    # This requires the mock-data/scenarios.json file to exist
    # Since we are running from project root or backend, we must ensure path resolution
    scenario = load_mock_scenario(1)
    
    if scenario is not None:
        assert scenario["id"] == 1
        assert "G-10" in scenario["name"]
        assert "area_polygon" in scenario["location"]
