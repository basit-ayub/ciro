"""
CIRO Router — Counterfactual Simulation
Endpoint: GET /counterfactual/{id}
Streams the twin-timeline simulation (With CIRO vs Without CIRO).
"""

from fastapi import APIRouter, HTTPException
import structlog
from backend.services.counterfactual import TwinTimelineSimulator

router = APIRouter()
log = structlog.get_logger()
simulator = TwinTimelineSimulator()

@router.get("/{situation_id}")
async def get_counterfactual(situation_id: str):
    """
    Get counterfactual simulation results for a given situation.
    Uses NetworkX to simulate the twin-timeline impact.
    """
    try:
        # In a real run, we'd fetch the situation and derive parameters.
        # For demo, we use static values or infer from the ID.
        result = simulator.run_simulation(
            situation_id=situation_id,
            crisis_type="urban_flooding",
            severity=4
        )
        return result
    except Exception as e:
        log.error("counterfactual_sim_failed", error=str(e))
        raise HTTPException(status_code=500, detail="Simulation failed")

