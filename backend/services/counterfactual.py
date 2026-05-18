"""
CIRO Services — Counterfactual Simulator
Wow #3: The Twin Timeline.
Uses NetworkX to simulate the crisis outcome with vs. without CIRO.
Calculates person-minutes saved, vehicles unaffected, and casualty risk delta.
"""

import networkx as nx
import json
from pathlib import Path
import structlog

log = structlog.get_logger()

class TwinTimelineSimulator:
    def __init__(self):
        self.graph_dir = Path("mock-data/city_graphs")
        
    def _load_graph(self, location_id: str) -> nx.DiGraph:
        """Load a city graph from JSON into a NetworkX directed graph."""
        file_path = self.graph_dir / f"{location_id}_graph.json"
        
        # Fallback to G-10 graph if specific one doesn't exist
        if not file_path.exists():
            file_path = self.graph_dir / "g10_graph.json"
            
        G = nx.DiGraph()
        try:
            with open(file_path, "r") as f:
                data = json.load(f)
                
            for node in data.get("nodes", []):
                G.add_node(node["id"], pos=(node["lat"], node["lon"]))
                
            for edge in data.get("edges", []):
                G.add_edge(edge["source"], edge["target"], 
                           weight=edge["weight"], 
                           capacity=edge["capacity"])
                           
            return G
        except Exception as e:
            log.error("graph_load_failed", error=str(e), file=str(file_path))
            return G # Return empty graph on error

    def run_simulation(self, situation_id: str, crisis_type: str, severity: int, epicenter_node: str = "G10-Markaz", blocked_edges: list = None) -> dict:
        """
        Run the twin timeline simulation.
        Timeline A (Without CIRO): Full traffic flows into the epicenter for 45 mins before official closure.
        Timeline B (With CIRO): AI detects anomaly in 5 mins, reroutes traffic instantly via early warning.
        """
        G = self._load_graph("g10")
        
        if not blocked_edges:
            # Default blocked edges based on epicenter
            blocked_edges = [("G10-Markaz", "Kashmir-Hwy-Junction")]
            
        # Baseline network stats
        if G.number_of_nodes() == 0:
            return {"error": "Graph empty"}
            
        total_capacity = sum(nx.get_edge_attributes(G, 'capacity').values())
        
        # Timeline A: Without CIRO
        # Traffic flows into the crisis zone, causing massive congestion before official response (avg 45m delay).
        without_ciro_delay_mins = 45
        affected_flow_rate = 0
        for u, v in blocked_edges:
            if G.has_edge(u, v):
                affected_flow_rate += G[u][v].get("capacity", 1000)
                
        # Assume 45 mins (0.75 hours) of flow enters the blocked zone
        vehicles_trapped_without = int(affected_flow_rate * 0.75) 
        persons_at_risk_without = vehicles_trapped_without * 2.5 # Avg 2.5 pax/vehicle in PK
        
        # Timeline B: With CIRO
        # Sentinel detects in 5 mins. Commander reroutes instantly via Google Maps integration.
        with_ciro_delay_mins = 5
        vehicles_trapped_with = int(affected_flow_rate * (5 / 60.0))
        persons_at_risk_with = vehicles_trapped_with * 2.5
        
        # Counterfactual metrics calculation
        vehicles_saved = vehicles_trapped_without - vehicles_trapped_with
        persons_saved = int(persons_at_risk_without - persons_at_risk_with)
        
        # Total person-minutes of delay saved
        # Without CIRO: trapped vehicles wait avg 120 mins
        # With CIRO: rerouted vehicles take +15 mins longer route
        delay_saved = (vehicles_trapped_without * 120 * 2.5) - (vehicles_saved * 15 * 2.5)

        return {
            "situation_id": situation_id,
            "epicenter": epicenter_node,
            "with_ciro": {
                "detection_time_mins": with_ciro_delay_mins,
                "vehicles_affected": vehicles_trapped_with,
                "persons_at_risk": int(persons_at_risk_with),
                "average_delay_min": 15
            },
            "without_ciro": {
                "detection_time_mins": without_ciro_delay_mins,
                "vehicles_affected": vehicles_trapped_without,
                "persons_at_risk": int(persons_at_risk_without),
                "average_delay_min": 120
            },
            "deltas": {
                "person_minutes_saved": int(max(0, delay_saved)),
                "vehicles_rerouted_safely": vehicles_saved,
                "casualty_risk_reduction_pct": 88
            },
            "graph_stats": {
                "nodes": G.number_of_nodes(),
                "edges": G.number_of_edges(),
                "blocked_edges": len(blocked_edges)
            }
        }
