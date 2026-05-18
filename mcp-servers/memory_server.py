"""
CIRO MCP Server — ciro-memory
Provides tools for incident memory via Firestore vector search (RAG).
Stores past resolved incidents and retrieves similar ones for pattern matching.

CRITICAL: All logging MUST go to stderr. stdout is JSON-RPC.
"""

import sys
import os
import json
import logging
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [ciro-memory] %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger("ciro-memory")

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("ciro-memory")

# In-memory mock memory store (would be Firestore vector index in production)
_memory_store: list = [
    {
        "incident_id": "hist-001",
        "date": "2024-08-13",
        "type": "urban_flooding",
        "location": "G-9 Markaz, Islamabad",
        "severity": 4,
        "summary": "Heavy monsoon rainfall caused flash flooding in G-9 sector. 47mm rainfall in 2 hours. "
                   "12 vehicles stranded, 3 shops waterlogged. Rescue 1122 deployed 2 units. "
                   "Resolved in 4 hours after drainage pumps activated.",
        "response_playbook": "Deploy rescue units, activate drainage pumps, reroute traffic via Khayaban-e-Iqbal, "
                             "issue flood warning to G-8 and G-10 adjacent sectors.",
        "outcome": "0 casualties, 12 vehicles recovered, estimated 5M PKR damage",
        "keywords": ["flooding", "g-9", "monsoon", "drainage", "vehicles stranded"],
    },
    {
        "incident_id": "hist-002",
        "date": "2024-07-22",
        "type": "heatwave",
        "location": "Saddar, Karachi",
        "severity": 5,
        "summary": "Extreme heat wave with temperatures exceeding 48°C. Power outages in Saddar grid. "
                   "12 heatstroke cases reported. Water distribution points overwhelmed.",
        "response_playbook": "Activate heat emergency protocol, set up hydration stations, "
                             "coordinate with K-Electric for priority power restoration, alert hospitals.",
        "outcome": "2 casualties, 45 hospitalized, power restored after 6 hours",
        "keywords": ["heatwave", "karachi", "power outage", "heatstroke", "temperature"],
    },
    {
        "incident_id": "hist-003",
        "date": "2024-09-05",
        "type": "accident",
        "location": "M-2 Motorway, km 284",
        "severity": 4,
        "summary": "Multi-vehicle pileup on M-2 Lahore-Islamabad Motorway during fog. "
                   "6 vehicles involved, 2 trucks overturned. Lane blocked for 5 hours.",
        "response_playbook": "Dispatch Motorway Police, Rescue 1122, close affected lane, "
                             "divert traffic via GT Road, deploy cranes for truck recovery.",
        "outcome": "3 injured, 0 casualties, 5-hour closure, 15km tailback",
        "keywords": ["accident", "motorway", "pileup", "truck", "fog"],
    },
    {
        "incident_id": "hist-004",
        "date": "2024-06-15",
        "type": "fire",
        "location": "Bolton Market, Karachi",
        "severity": 5,
        "summary": "Major fire in Bolton Market commercial area. Started from electrical short circuit. "
                   "Spread to 12 shops. Fire brigade response delayed by narrow lanes.",
        "response_playbook": "Deploy all available fire engines, evacuate adjacent buildings, "
                             "establish perimeter, coordinate with gas utility for shutoff.",
        "outcome": "1 casualty, 15 injured, 12 shops destroyed, 50M PKR estimated damage",
        "keywords": ["fire", "market", "electrical", "shops", "evacuation"],
    },
    {
        "incident_id": "hist-005",
        "date": "2024-10-01",
        "type": "landslide",
        "location": "KKH km 195, Hunza",
        "severity": 3,
        "summary": "Minor landslide on Karakoram Highway due to heavy rainfall. "
                   "Single lane blocked. Traffic suspended for 3 hours.",
        "response_playbook": "Alert GBDMA, deploy NHA clearing crew, divert light vehicles via alternate "
                             "mountain road, issue travel advisory.",
        "outcome": "0 casualties, 3-hour traffic suspension, road cleared by NHA",
        "keywords": ["landslide", "kkh", "hunza", "rainfall", "road blocked"],
    },
    {
        "incident_id": "hist-006",
        "date": "2023-08-20",
        "type": "urban_flooding",
        "location": "DHA Phase 2, Karachi",
        "severity": 5,
        "summary": "Record breaking rainfall of 120mm in 4 hours submerged main boulevards. Basement flooding reported in 40+ houses.",
        "response_playbook": "Deploy heavy duty dewatering pumps, request armed forces assistance for evacuation of stranded residents, setup relief camps.",
        "outcome": "0 casualties, major property damage, cleared after 48 hours",
        "keywords": ["flooding", "dha", "karachi", "basement", "heavy rain"]
    },
    {
        "incident_id": "hist-007",
        "date": "2023-12-10",
        "type": "accident",
        "location": "M-1 Motorway, Swabi Interchange",
        "severity": 3,
        "summary": "Bus collided with a stationary truck due to low visibility. Minor injuries to 8 passengers.",
        "response_playbook": "Dispatch ambulances, clear lane to restore traffic flow, issue fog advisory.",
        "outcome": "8 minor injuries, road cleared in 2 hours",
        "keywords": ["accident", "bus", "truck", "motorway", "fog"]
    },
    {
        "incident_id": "hist-008",
        "date": "2023-05-15",
        "type": "fire",
        "location": "Lahore Anarkali Bazaar",
        "severity": 4,
        "summary": "Fire erupted in a garments plaza. Prompt response prevented spread to adjacent narrow streets.",
        "response_playbook": "Immediate dispatch of 6 fire engines, cordon off area, clear crowd for emergency vehicle access.",
        "outcome": "2 injured, 4 shops damaged, fire controlled in 3 hours",
        "keywords": ["fire", "bazaar", "garments", "lahore"]
    },
    {
        "incident_id": "hist-009",
        "date": "2024-01-22",
        "type": "infrastructure_failure",
        "location": "Rawalpindi, Murree Road",
        "severity": 4,
        "summary": "Main water supply pipeline burst causing sudden inundation of the road and severe traffic jam.",
        "response_playbook": "Shut off main valve immediately, divert traffic via double road, deploy WASA teams for repair.",
        "outcome": "Traffic disrupted for 6 hours, no casualties, repaired in 12 hours",
        "keywords": ["pipeline burst", "water", "traffic jam", "murree road"]
    },
    {
        "incident_id": "hist-010",
        "date": "2024-02-18",
        "type": "structural_collapse",
        "location": "Peshawar City",
        "severity": 5,
        "summary": "Roof of an old under-construction building collapsed due to structural weakness. 4 laborers trapped.",
        "response_playbook": "Dispatch urban search and rescue (USAR) team, heavy machinery, and ambulances. Establish triage area.",
        "outcome": "1 casualty, 3 rescued alive after 6 hours",
        "keywords": ["collapse", "building", "trapped", "rescue", "peshawar"]
    },
    {
        "incident_id": "hist-011",
        "date": "2023-06-30",
        "type": "heatwave",
        "location": "Multan",
        "severity": 4,
        "summary": "Temperatures reached 46°C. Spike in heatstroke cases at Nishtar Hospital. Shortage of ice in local markets.",
        "response_playbook": "Setup emergency cooling centers, ensure uninterrupted power to hospitals, public awareness campaigns.",
        "outcome": "15 treated for heatstroke, no casualties",
        "keywords": ["heatwave", "multan", "heatstroke", "hospitals"]
    },
    {
        "incident_id": "hist-012",
        "date": "2024-03-05",
        "type": "urban_flooding",
        "location": "G-10/4, Islamabad",
        "severity": 3,
        "summary": "Blocked drainage caused knee-deep water accumulation on street 44. 3 cars stuck.",
        "response_playbook": "Send CDA drainage team to clear blockage, divert local traffic.",
        "outcome": "Cleared in 2 hours, minor vehicle damage",
        "keywords": ["flooding", "g-10", "drainage", "cars stuck"]
    },
    {
        "incident_id": "hist-013",
        "date": "2023-11-20",
        "type": "landslide",
        "location": "Murree Expressway",
        "severity": 4,
        "summary": "Heavy snowfall led to minor landsliding and road blockage, stranding hundreds of tourist vehicles.",
        "response_playbook": "Deploy FWO machinery to clear road, supply food/blankets to stranded tourists, halt incoming traffic from toll plaza.",
        "outcome": "0 casualties, cleared in 8 hours",
        "keywords": ["landslide", "snowfall", "tourists", "stranded", "murree"]
    },
    {
        "incident_id": "hist-014",
        "date": "2024-04-12",
        "type": "accident",
        "location": "Clifton Beach Road, Karachi",
        "severity": 3,
        "summary": "Speeding sports car collided with a street pole, causing power outage in the immediate vicinity.",
        "response_playbook": "Dispatch traffic police, ambulance, and K-Electric team to secure live wires and restore power.",
        "outcome": "1 injured (driver), power restored in 4 hours",
        "keywords": ["accident", "car crash", "power outage", "clifton"]
    },
    {
        "incident_id": "hist-015",
        "date": "2023-09-25",
        "type": "fire",
        "location": "I-9 Industrial Area, Islamabad",
        "severity": 5,
        "summary": "Chemical factory fire resulted in toxic smoke plume drifting towards residential sectors.",
        "response_playbook": "Full fire brigade mobilization, issue shelter-in-place warning via push alerts to I-8 and I-9 residents, coordinate HAZMAT team.",
        "outcome": "Factory destroyed, no casualties, air quality normalized in 24 hrs",
        "keywords": ["fire", "chemical", "toxic smoke", "factory", "i-9"]
    }
]


@mcp.tool()
def search_similar(query: str, top_k: int = 3) -> str:
    """
    Search for past incidents similar to the current one.
    Uses keyword matching (would use vector similarity in production).
    
    Args:
        query: Description of the current incident for similarity matching
        top_k: Number of similar incidents to return
    """
    query_lower = query.lower()
    
    # Simple keyword-based similarity scoring
    scored = []
    for memory in _memory_store:
        score = 0
        for keyword in memory.get("keywords", []):
            if keyword.lower() in query_lower:
                score += 1
        # Also check summary
        summary_words = memory.get("summary", "").lower().split()
        query_words = query_lower.split()
        common = len(set(summary_words) & set(query_words))
        score += common * 0.1
        
        if score > 0:
            scored.append({
                **memory,
                "similarity_score": min(score / 5.0, 1.0),  # Normalize to 0-1
            })
    
    # Sort by score descending
    scored.sort(key=lambda x: x["similarity_score"], reverse=True)
    results = scored[:top_k]
    
    logger.info(f"search_similar: found {len(results)} matches for query")
    return json.dumps({
        "query": query[:100],
        "matches": results,
    }, default=str)


@mcp.tool()
def store_incident(incident_data: str) -> str:
    """
    Store a resolved incident as a memory chunk for future RAG lookups.
    
    Args:
        incident_data: JSON string of the incident to store
    """
    try:
        data = json.loads(incident_data)
    except json.JSONDecodeError:
        return json.dumps({"error": "Invalid JSON"})
    
    data["stored_at"] = datetime.utcnow().isoformat()
    _memory_store.append(data)
    
    logger.info(f"Stored incident: {data.get('incident_id', 'unknown')}")
    return json.dumps({"status": "stored", "total_memories": len(_memory_store)})


@mcp.tool()
def get_memory_stats() -> str:
    """Get statistics about the memory store."""
    types = {}
    for m in _memory_store:
        t = m.get("type", "unknown")
        types[t] = types.get(t, 0) + 1
    
    return json.dumps({
        "total_memories": len(_memory_store),
        "by_type": types,
    })


if __name__ == "__main__":
    logger.info("Starting ciro-memory MCP server")
    mcp.run()
