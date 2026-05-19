import pytest
from backend.models.signal import Signal
from backend.models.triage import TriageArtifact
from backend.models.situation import SituationArtifact
from backend.models.action import ActionArtifact

def test_signal_model():
    signal_data = {
        "signal_id": "sig-test-1",
        "source": "social",
        "text": "Flood in G-10 markaz",
        "timestamp": "2026-05-17T14:30:00Z"
    }
    signal = Signal(**signal_data)
    assert signal.signal_id == "sig-test-1"
    assert signal.source == "social"
    assert signal.text == "Flood in G-10 markaz"
    assert signal.geo is None

def test_triage_artifact():
    triage_data = {
        "triage_id": "triage-1",
        "signal_id": "sig-1",
        "crisis_type": "urban_flooding",
        "urgency_signal": 0.95
    }
    triage = TriageArtifact(**triage_data)
    assert triage.crisis_type == "urban_flooding"
    assert triage.urgency_signal == 0.95
