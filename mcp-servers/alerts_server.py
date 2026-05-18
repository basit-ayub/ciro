"""
CIRO MCP Server — ciro-alerts
Provides tools to send alerts via FCM push, Twilio SMS, and WhatsApp.

CRITICAL: All logging MUST go to stderr. stdout is JSON-RPC.
"""

import sys
import os
import json
import logging
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [ciro-alerts] %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger("ciro-alerts")

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("ciro-alerts")

MOCK_MODE = os.environ.get("MOCK_MODE", "true").lower() == "true"

# Alert history (in-memory)
_alerts_sent: list = []


@mcp.tool()
def send_geo_push(
    area_polygon: str,
    message_en: str,
    message_ur: str,
    channel: str = "push",
) -> str:
    """
    Send geo-fenced alerts to citizens in the affected area.
    
    Args:
        area_polygon: JSON string of polygon coordinates
        message_en: Alert message in English (max 280 chars)
        message_ur: Alert message in Roman Urdu / Urdu (max 280 chars)
        channel: "push" | "sms" | "whatsapp"
    
    Returns: Alert delivery summary.
    """
    alert = {
        "alert_id": f"alert-{len(_alerts_sent) + 1:04d}",
        "channel": channel,
        "area_polygon": area_polygon,
        "messages": {
            "en": message_en[:280],
            "ur": message_ur[:280],
        },
        "estimated_recipients": 2847,  # Mock count
        "status": "delivered" if MOCK_MODE else "pending",
        "timestamp": datetime.utcnow().isoformat(),
    }
    
    _alerts_sent.append(alert)
    
    if not MOCK_MODE and channel == "sms":
        # TODO: Real Twilio SMS integration
        pass
    elif not MOCK_MODE and channel == "whatsapp":
        # TODO: Real Twilio WhatsApp integration
        pass
    elif not MOCK_MODE and channel == "push":
        # TODO: Real FCM push notification
        pass
    
    logger.info(f"Alert sent via {channel}: {alert['alert_id']} ({alert['estimated_recipients']} recipients)")
    return json.dumps(alert, default=str)


@mcp.tool()
def send_operator_brief(situation_id: str) -> str:
    """
    Send a situation brief to operators/dashboard.
    Updates the operator dashboard with current incident status.
    
    Args:
        situation_id: ID of the Situation Artifact to brief about.
    """
    brief = {
        "brief_id": f"brief-{len(_alerts_sent) + 1:04d}",
        "situation_id": situation_id,
        "status": "sent",
        "channel": "operator_dashboard",
        "timestamp": datetime.utcnow().isoformat(),
    }
    
    _alerts_sent.append(brief)
    logger.info(f"Operator brief sent for situation {situation_id}")
    return json.dumps(brief, default=str)


@mcp.tool()
def get_alert_history() -> str:
    """Get the history of all sent alerts."""
    return json.dumps({
        "total_alerts": len(_alerts_sent),
        "alerts": _alerts_sent[-20:],  # Last 20
    }, default=str)


if __name__ == "__main__":
    logger.info(f"Starting ciro-alerts MCP server (MOCK_MODE={MOCK_MODE})")
    mcp.run()
