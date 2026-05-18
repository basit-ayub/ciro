"""
CIRO MCP Server — ciro-dispatch
Provides tools to create and manage emergency dispatch tickets.
Simulates Rescue 1122, Edhi Foundation, Police, and Fire Brigade dispatch.

CRITICAL: All logging MUST go to stderr. stdout is JSON-RPC.
"""

import sys
import os
import json
import logging
from datetime import datetime
import uuid

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [ciro-dispatch] %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger("ciro-dispatch")

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("ciro-dispatch")

# In-memory ticket store (would be Firestore in production)
_tickets: dict = {}

# Available rescue units (mock)
_available_units = {
    "1122": [
        {"unit_id": "1122-ISB-018", "type": "rescue", "location": "F-8, Islamabad", "status": "available"},
        {"unit_id": "1122-ISB-023", "type": "rescue", "location": "G-9, Islamabad", "status": "available"},
        {"unit_id": "1122-ISB-007", "type": "ambulance", "location": "G-11, Islamabad", "status": "available"},
        {"unit_id": "1122-ISB-041", "type": "rescue", "location": "I-8, Islamabad", "status": "available"},
    ],
    "edhi": [
        {"unit_id": "EDHI-ISB-003", "type": "ambulance", "location": "Blue Area, Islamabad", "status": "available"},
        {"unit_id": "EDHI-KHI-015", "type": "ambulance", "location": "Saddar, Karachi", "status": "available"},
    ],
    "police": [
        {"unit_id": "POL-ISB-112", "type": "patrol", "location": "G-10, Islamabad", "status": "available"},
    ],
    "fire": [
        {"unit_id": "FIRE-ISB-005", "type": "fire_engine", "location": "F-7, Islamabad", "status": "available"},
    ],
}


@mcp.tool()
def create_ticket(
    service: str,
    lat: float,
    lon: float,
    severity: int,
    summary: str,
) -> str:
    """
    Create an emergency dispatch ticket.

    Args:
        service: "1122" | "edhi" | "police" | "fire"
        lat: Latitude of the incident
        lon: Longitude of the incident
        severity: 1-5 severity scale
        summary: Brief description of the emergency
    
    Returns: Ticket details with assigned unit and ETA.
    """
    ticket_id = f"CIRO-{service.upper()}-{uuid.uuid4().hex[:6].upper()}"
    
    # Find closest available unit
    assigned_unit = None
    units = _available_units.get(service, [])
    for unit in units:
        if unit["status"] == "available":
            assigned_unit = unit.copy()
            unit["status"] = "dispatched"  # Mark as dispatched
            break
    
    ticket = {
        "ticket_id": ticket_id,
        "service": service,
        "location": {"lat": lat, "lon": lon},
        "severity": severity,
        "summary": summary,
        "assigned_unit": assigned_unit,
        "eta_minutes": 8 if assigned_unit else None,  # Mock ETA
        "status": "dispatched" if assigned_unit else "no_units_available",
        "created_at": datetime.utcnow().isoformat(),
    }
    
    _tickets[ticket_id] = ticket
    logger.info(f"Ticket created: {ticket_id} ({service}, severity {severity})")
    
    return json.dumps(ticket, default=str)


@mcp.tool()
def get_ticket_status(ticket_id: str) -> str:
    """Get the current status of a dispatch ticket."""
    ticket = _tickets.get(ticket_id)
    if ticket:
        return json.dumps(ticket, default=str)
    return json.dumps({"error": f"Ticket {ticket_id} not found"})


@mcp.tool()
def list_available_units(service: str) -> str:
    """
    List available rescue units for a given service.
    
    Args:
        service: "1122" | "edhi" | "police" | "fire"
    """
    units = _available_units.get(service, [])
    available = [u for u in units if u["status"] == "available"]
    logger.info(f"list_available_units: {len(available)} units available for {service}")
    return json.dumps({
        "service": service,
        "total_units": len(units),
        "available_units": len(available),
        "units": available,
    })


if __name__ == "__main__":
    logger.info("Starting ciro-dispatch MCP server")
    mcp.run()
