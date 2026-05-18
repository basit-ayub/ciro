"""
CIRO Router — Incidents
Endpoints: GET /incidents, GET /incidents/{id}
Read active and historical crisis incidents.
"""

from fastapi import APIRouter, HTTPException
import structlog

from backend.services import firestore_client

router = APIRouter()
log = structlog.get_logger()


@router.get("/")
async def list_incidents():
    """List all incidents (active + resolved), most recent first."""
    try:
        incidents = firestore_client.get_all_incidents()
        return {"count": len(incidents), "incidents": incidents}
    except Exception as e:
        log.error("incidents_list_failed", error=str(e))
        return {"count": 0, "incidents": [], "warning": "Firestore not connected"}


@router.get("/{incident_id}")
async def get_incident(incident_id: str):
    """Get a single incident with all associated artifacts."""
    try:
        situation = firestore_client.get_situation(incident_id)
        if not situation:
            raise HTTPException(status_code=404, detail=f"Incident {incident_id} not found")

        # Fetch related artifacts
        action = None
        if "situation_id" in situation:
            # Look for action artifacts linked to this situation
            pass  # TODO: query by situation_id

        return {
            "situation": situation,
            "action": action,
        }
    except HTTPException:
        raise
    except Exception as e:
        log.error("incident_get_failed", error=str(e), incident_id=incident_id)
        raise HTTPException(status_code=500, detail=str(e))
