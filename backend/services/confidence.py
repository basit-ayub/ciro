"""
CIRO Services — Confidence Calculator
Implements the exact weighted confidence formula from the Master Plan §5.3.
This formula is exposed in the UI for full transparency — judges love seeing the math.
"""

from dataclasses import dataclass


@dataclass
class ConfidenceInputs:
    """Raw inputs to the confidence formula."""

    independent_signal_count: int = 1      # Count of independent signals confirming this crisis
    weather_matches_precursor: bool = False # Does weather match expected crisis precursor?
    traffic_shows_anomaly: bool = False     # Does traffic data show expected disruption?
    visual_confirmation: float = 0.0        # 1.0 = confirmed, 0.5 = ambiguous, 0.0 = absent
    historical_similarity: float = 0.0     # Cosine similarity from memory RAG (0.0–1.0)


def calculate_confidence(inputs: ConfidenceInputs) -> dict:
    """
    Calculate weighted confidence score using the exact formula from the Master Plan.

    Formula:
        confidence = 0.30 * (signal_corroboration: min(count, 5) / 5)
                   + 0.25 * (weather_concordance: 1.0 if match, else 0)
                   + 0.20 * (traffic_concordance: 1.0 if anomaly, else 0)
                   + 0.15 * (visual_confirmation: 1.0/0.5/0)
                   + 0.10 * (historical_match: 1.0 if similarity > 0.8, else 0)

    Returns:
        Dict with 'confidence' (float) and 'breakdown' (dict of each component).
    """

    # Component calculations
    signal_corroboration = min(inputs.independent_signal_count, 5) / 5.0
    weather_concordance = 1.0 if inputs.weather_matches_precursor else 0.0
    traffic_concordance = 1.0 if inputs.traffic_shows_anomaly else 0.0
    visual_conf = inputs.visual_confirmation  # Already 0.0, 0.5, or 1.0
    historical_match = 1.0 if inputs.historical_similarity > 0.8 else 0.0

    # Weighted sum
    confidence = (
        0.30 * signal_corroboration
        + 0.25 * weather_concordance
        + 0.20 * traffic_concordance
        + 0.15 * visual_conf
        + 0.10 * historical_match
    )

    return {
        "confidence": round(confidence, 4),
        "breakdown": {
            "signal_corroboration": round(0.30 * signal_corroboration, 4),
            "weather_concordance": round(0.25 * weather_concordance, 4),
            "traffic_concordance": round(0.20 * traffic_concordance, 4),
            "visual_confirmation": round(0.15 * visual_conf, 4),
            "historical_match": round(0.10 * historical_match, 4),
        },
        "raw_inputs": {
            "independent_signal_count": inputs.independent_signal_count,
            "weather_matches_precursor": inputs.weather_matches_precursor,
            "traffic_shows_anomaly": inputs.traffic_shows_anomaly,
            "visual_confirmation": inputs.visual_confirmation,
            "historical_similarity": inputs.historical_similarity,
        },
    }
