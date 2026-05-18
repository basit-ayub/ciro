"""
CIRO Models — Action Artifact
Output of the Commander agent. Represents executed actions and their verification.
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
import uuid


class PlanStep(BaseModel):
    """A single step in the Commander's plan-graph (DAG)."""

    step: int
    action: str = Field(description="Verb describing the action")
    tool: str = Field(description="MCP tool name, e.g., 'ciro_maps.update_route'")
    params: dict = Field(default_factory=dict)
    preconditions: List[int] = Field(
        default_factory=list,
        description="Step numbers that must complete before this step",
    )
    status: str = Field(default="pending", description="pending | executing | success | degraded | failed")
    result: Optional[dict] = Field(default=None, description="Tool call result")
    executed_at: Optional[str] = None
    retry_count: int = 0


class ActionArtifact(BaseModel):
    """Commander output — the full action plan with execution results."""

    action_id: str = Field(default_factory=lambda: f"act-{uuid.uuid4().hex[:8]}")
    situation_id: str = Field(description="ID of the triggering Situation Artifact")
    plan: List[PlanStep] = Field(description="DAG of planned actions with preconditions")
    expected_outcome: str = Field(description="One-sentence expected outcome")
    verification_steps: List[str] = Field(
        default_factory=list,
        description="What we check after each action to verify success",
    )
    counterfactual_id: Optional[str] = Field(
        default=None,
        description="ID of the counterfactual simulation for this action",
    )
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    agent: str = "commander"
    status: str = Field(
        default="planning",
        description="planning | executing | completed | partial_degraded",
    )

    def to_firestore(self) -> dict:
        """Serialize for Firestore write."""
        data = self.model_dump()
        data["timestamp"] = self.timestamp.isoformat()
        # Serialize PlanSteps
        data["plan"] = [step.model_dump() for step in self.plan]
        return data
