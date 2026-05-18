"""
CIRO Router — Vision Analysis
Endpoint: POST /vision/analyze
Accepts a photo URL and runs Gemini 3 Pro vision analysis for crisis assessment.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
import structlog

from backend.services.gemini_client import get_gemini_client

router = APIRouter()
log = structlog.get_logger()

VISION_PROMPT = """Analyze this crisis photo. Return JSON with:
1. crisis_type (flooding/fire/accident/structural),
2. water_depth_estimate_cm using visible vehicles as reference,
3. stranded_vehicles array with [x1,y1,x2,y2] bounding boxes (0-1000 normalized),
4. visible_text array of any signs/billboards readable,
5. severity 1-5,
6. landmarks_identified for location triangulation."""


class VisionRequest(BaseModel):
    image_url: str = Field(description="Cloud Storage URL or public URL of the crisis photo")
    custom_prompt: Optional[str] = Field(default=None, description="Override the default vision prompt")


@router.post("/analyze")
async def analyze_image(request: VisionRequest):
    """
    Run Gemini 3 Pro vision analysis on a crisis photo.
    Returns structured JSON with bounding boxes, water depth estimates,
    visible text/signs, and severity assessment.
    """
    gemini = get_gemini_client()
    prompt = request.custom_prompt or VISION_PROMPT

    log.info("vision_analysis_started", image_url=request.image_url[:80])

    result = await gemini.analyze_image(request.image_url, prompt)

    if "error" in result:
        log.error("vision_analysis_failed", error=result["error"])
        raise HTTPException(status_code=500, detail=result["error"])

    log.info("vision_analysis_complete", crisis_type=result.get("crisis_type"))
    return result
