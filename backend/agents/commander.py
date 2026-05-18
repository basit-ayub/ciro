"""
CIRO Agent — The Commander
Agent 3: Action planning and execution.
Reads Situation Artifacts from Analyst. Uses Gemini 3 Pro to generate a Plan Graph (DAG)
of actions based on severity and incident type. Executes MCP tools (dispatch, routing, alerts).
Outputs Action Artifacts.
"""

import asyncio
import json
import structlog
from datetime import datetime
from typing import Optional

from backend.config import get_settings
from backend.models.situation import SituationArtifact
from backend.models.action import ActionArtifact, PlanStep
from backend.services.gemini_client import get_gemini_client
from backend.services import firestore_client
from backend.routers.stream import commander_events

log = structlog.get_logger()

class CommanderAgent:
    """The action planner and executor."""

    def __init__(self):
        self.gemini = get_gemini_client()
        self.settings = get_settings()
        self.system_prompt = self._load_prompt()

    def _load_prompt(self) -> str:
        with open(f"{self.settings.prompts_dir}/commander.txt", "r", encoding="utf-8") as f:
            return f.read()

    async def _execute_mcp_tool(self, tool_name: str, params: dict) -> dict:
        """
        Mock MCP tool execution.
        In a full MCP host runtime, this would route to the appropriate FastMCP server.
        For the hackathon demo without a live MCP client runtime, we simulate the responses
        that the servers would return.
        """
        await self._emit_event("tool_call", f"Executing MCP tool: {tool_name}")
        await asyncio.sleep(1) # Simulate network call
        
        result = {"status": "success", "tool": tool_name}
        
        if tool_name == "ciro_maps.update_route":
            result["blocked_edges_count"] = 2
            result["alternate_route_set"] = True
        elif tool_name == "ciro_dispatch.create_ticket":
            result["ticket_id"] = "CIRO-DISP-MOCK"
            result["eta_minutes"] = 8
        elif tool_name == "ciro_alerts.send_geo_push":
            result["estimated_recipients"] = 1205
            result["delivered"] = True
            
        await self._emit_event("tool_result", f"Tool {tool_name} completed.")
        return result

    async def generate_and_execute_plan(self, situation_id: str) -> Optional[ActionArtifact]:
        """Process a Situation Artifact into an actionable plan and execute it."""
        situation_dict = firestore_client.get_situation(situation_id)
        if not situation_dict:
            log.error("situation_not_found", situation_id=situation_id)
            return None
            
        await self._emit_event("planning_started", f"Generating response plan for Situation {situation_id}")
        firestore_client.update_situation_status(situation_id, "acting")
        
        llm_context = json.dumps(situation_dict, default=str)
        
        await self._emit_event("reasoning", "Commander is constructing Plan DAG...")
        
        # Call Gemini 3 Pro to generate the DAG
        result = await self.gemini.generate_action_plan(
            system_prompt=self.system_prompt,
            situation_context=llm_context
        )
        
        if "error" in result:
            await self._emit_event("error", f"Plan generation failed: {result['error']}")
            return None
            
        plan_steps = result.get("plan", [])
        expected_outcome = result.get("expected_outcome", "Mitigate crisis impact.")
        verification = result.get("verification_steps", [])
        
        # Convert to Pydantic models
        parsed_steps = []
        for step in plan_steps:
            parsed_steps.append(PlanStep(
                step=step.get("step", 1),
                action=step.get("action", "unknown action"),
                tool=step.get("tool", "unknown_tool"),
                params=step.get("params", {}),
                preconditions=step.get("preconditions", [])
            ))
            
        action_artifact = ActionArtifact(
            situation_id=situation_id,
            plan=parsed_steps,
            expected_outcome=expected_outcome,
            verification_steps=verification
        )
        
        # Initial save of the plan
        action_id = firestore_client.write_action(action_artifact.to_firestore())
        
        await self._emit_event("plan_generated", f"Plan generated with {len(parsed_steps)} steps. Beginning execution...")
        
        # Execute steps (Simplified sequential execution honoring preconditions)
        # In a real DAG executor, we'd use asyncio.gather for parallel steps
        for step in action_artifact.plan:
            step.status = "executing"
            firestore_client.write_action(action_artifact.to_firestore())
            
            try:
                result = await self._execute_mcp_tool(step.tool, step.params)
                step.result = result
                step.status = "success"
                step.executed_at = datetime.utcnow().isoformat()
            except Exception as e:
                log.error("tool_execution_failed", tool=step.tool, error=str(e))
                step.status = "failed"
                step.result = {"error": str(e)}
                
            firestore_client.write_action(action_artifact.to_firestore())
            
        action_artifact.status = "completed"
        firestore_client.write_action(action_artifact.to_firestore())
        firestore_client.update_situation_status(situation_id, "resolved")
        
        await self._emit_event("execution_complete", f"All actions completed. Situation resolved.")
        return action_artifact

    async def _emit_event(self, step: str, message: str):
        """Push an event to the SSE stream."""
        event = {
            "agent": "commander",
            "step": step,
            "message": message,
            "timestamp": datetime.utcnow().isoformat(),
        }
        try:
            commander_events.put_nowait(event)
        except asyncio.QueueFull:
            try:
                commander_events.get_nowait()
                commander_events.put_nowait(event)
            except asyncio.QueueEmpty:
                pass

# Singleton
_agent: Optional[CommanderAgent] = None

def get_commander() -> CommanderAgent:
    global _agent
    if _agent is None:
        _agent = CommanderAgent()
    return _agent
