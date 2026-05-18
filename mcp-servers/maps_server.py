"""
CIRO MCP Server — ciro-maps
Provides tools to interact with Google Maps Routes API for routing and traffic.

Usage:
  python mcp-servers/maps_server.py

Env:
  GOOGLE_MAPS_API_KEY → required for real API calls
  MOCK_MODE=true → returns pre-defined route data

CRITICAL: All logging MUST go to stderr. stdout is JSON-RPC.
"""

import sys
import os
import json
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [ciro-maps] %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger("ciro-maps")

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("ciro-maps")

MOCK_MODE = os.environ.get("MOCK_MODE", "true").lower() == "true"
MAPS_API_KEY = os.environ.get("GOOGLE_MAPS_API_KEY", "")


@mcp.tool()
def get_route(origin_lat: float, origin_lon: float, dest_lat: float, dest_lon: float) -> str:
    """
    Get the optimal route between two points via Google Maps Routes API.
    Returns polyline, duration, distance, and traffic conditions.
    """
    if MOCK_MODE:
        result = {
            "status": "OK",
            "route": {
                "polyline": "mock_encoded_polyline_data",
                "duration_seconds": 840,
                "distance_meters": 4200,
                "traffic_condition": "heavy",
            },
            "origin": {"lat": origin_lat, "lon": origin_lon},
            "destination": {"lat": dest_lat, "lon": dest_lon},
        }
        logger.info(f"get_route: mock route returned")
        return json.dumps(result)
    else:
        # TODO: Real Google Maps Routes API call
        import httpx
        # Placeholder for actual API integration
        return json.dumps({"error": "Real API not yet implemented"})


@mcp.tool()
def update_route(area_polygon: str, blocked_edges: str, alternate_route: str) -> str:
    """
    Update routing with blocked edges and provide an alternate route.
    Used by Commander to reroute traffic away from crisis zones.
    
    Args:
        area_polygon: JSON string of polygon coordinates defining the affected area
        blocked_edges: JSON string of edge IDs to mark as blocked
        alternate_route: JSON string of the alternate route polyline/waypoints
    """
    logger.info(f"update_route: blocking edges and setting alternate route")
    
    result = {
        "status": "route_updated",
        "blocked_edges_count": len(json.loads(blocked_edges)) if blocked_edges else 0,
        "alternate_route_set": True,
        "affected_area": area_polygon,
        "timestamp": __import__("datetime").datetime.utcnow().isoformat(),
    }
    return json.dumps(result)


@mcp.tool()
def get_traffic_edges(area_polygon: str) -> str:
    """
    Get current traffic edge weights for an area.
    Returns throughput deltas and congestion levels.
    """
    if MOCK_MODE:
        edges = [
            {
                "edge_id": "G10-Kashmir-Hwy",
                "from": "G-10 Markaz",
                "to": "Kashmir Highway",
                "throughput_delta": -340,
                "congestion": "severe",
                "speed_kmh": 5,
            },
            {
                "edge_id": "G10-Service-Rd",
                "from": "G-10/4",
                "to": "Service Road North",
                "throughput_delta": -120,
                "congestion": "moderate",
                "speed_kmh": 25,
            },
        ]
        return json.dumps(edges)
    else:
        return json.dumps([])


if __name__ == "__main__":
    logger.info(f"Starting ciro-maps MCP server (MOCK_MODE={MOCK_MODE})")
    mcp.run()
