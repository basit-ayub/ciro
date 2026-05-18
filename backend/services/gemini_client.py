"""
CIRO Services — Gemini Client
Wrapper around the google-genai SDK for both Flash (Sentinel) and Pro (Analyst/Commander).
Supports text generation, vision analysis, and thinking mode.
"""

import json
import structlog
from typing import Optional, AsyncGenerator
from google import genai
from google.genai import types

from backend.config import get_settings

log = structlog.get_logger()


class GeminiClient:
    """Singleton wrapper for Gemini API calls."""

    def __init__(self):
        settings = get_settings()
        self.client = genai.Client(api_key=settings.google_api_key)
        self.pro_model = settings.gemini_pro_model
        self.flash_model = settings.gemini_flash_model
        self.thinking_budget = settings.gemini_thinking_budget

    async def classify_signal(self, system_prompt: str, signal_text: str) -> dict:
        """
        Sentinel classification via Gemini 3 Flash.
        Returns parsed JSON dict from the model's response.
        """
        try:
            response = self.client.models.generate_content(
                model=self.flash_model,
                contents=[signal_text],
                config=types.GenerateContentConfig(
                    system_instruction=system_prompt,
                    temperature=0.1,  # Low temp for deterministic classification
                    response_mime_type="application/json",
                ),
            )
            return self._parse_json_response(response.text)
        except Exception as e:
            log.error("gemini_flash_error", error=str(e), signal_preview=signal_text[:100])
            return {"is_crisis": False, "error": str(e)}

    async def analyze_situation(
        self,
        system_prompt: str,
        context: str,
        image_url: Optional[str] = None,
    ) -> dict:
        """
        Analyst reasoning via Gemini 3 Pro with Thinking mode.
        Optionally includes vision analysis if image_url is provided.
        """
        contents = []

        if image_url:
            contents.append(types.Part.from_uri(image_url, mime_type="image/jpeg"))

        contents.append(context)

        try:
            response = self.client.models.generate_content(
                model=self.pro_model,
                contents=contents,
                config=types.GenerateContentConfig(
                    system_instruction=system_prompt,
                    temperature=0.2,
                    thinking_config=types.ThinkingConfig(
                        thinking_budget=self.thinking_budget
                    ),
                    response_mime_type="application/json",
                ),
            )
            return self._parse_json_response(response.text)
        except Exception as e:
            log.error("gemini_pro_error", error=str(e))
            return {"error": str(e)}

    async def generate_action_plan(self, system_prompt: str, situation_context: str) -> dict:
        """
        Commander plan generation via Gemini 3 Pro.
        """
        try:
            response = self.client.models.generate_content(
                model=self.pro_model,
                contents=[situation_context],
                config=types.GenerateContentConfig(
                    system_instruction=system_prompt,
                    temperature=0.3,
                    response_mime_type="application/json",
                ),
            )
            return self._parse_json_response(response.text)
        except Exception as e:
            log.error("gemini_commander_error", error=str(e))
            return {"error": str(e)}

    async def analyze_image(self, image_url: str, prompt: str) -> dict:
        """
        Vision-first analysis via Gemini 3 Pro.
        Used for citizen-uploaded crisis photos — bounding boxes, water depth, signs.
        """
        try:
            response = self.client.models.generate_content(
                model=self.pro_model,
                contents=[
                    types.Part.from_uri(image_url, mime_type="image/jpeg"),
                    prompt,
                ],
                config=types.GenerateContentConfig(
                    media_resolution="high",  # Gemini 3 specific — high-res analysis
                    thinking_config=types.ThinkingConfig(
                        thinking_budget=self.thinking_budget
                    ),
                    response_mime_type="application/json",
                ),
            )
            return self._parse_json_response(response.text)
        except Exception as e:
            log.error("gemini_vision_error", error=str(e))
            return {"error": str(e)}

    async def stream_response(
        self, model: str, system_prompt: str, context: str
    ) -> AsyncGenerator[str, None]:
        """
        Stream tokens for the Live Reasoning Stadium UI.
        Yields individual text chunks as they arrive.
        """
        try:
            response = self.client.models.generate_content_stream(
                model=model,
                contents=[context],
                config=types.GenerateContentConfig(
                    system_instruction=system_prompt,
                    temperature=0.2,
                ),
            )
            for chunk in response:
                if chunk.text:
                    yield chunk.text
        except Exception as e:
            log.error("gemini_stream_error", error=str(e))
            yield json.dumps({"error": str(e)})

    @staticmethod
    def _parse_json_response(text: str) -> dict:
        """Parse Gemini response, stripping markdown code fences if present."""
        cleaned = text.strip()
        if cleaned.startswith("```json"):
            cleaned = cleaned[7:]
        if cleaned.startswith("```"):
            cleaned = cleaned[3:]
        if cleaned.endswith("```"):
            cleaned = cleaned[:-3]
        cleaned = cleaned.strip()

        try:
            result = json.loads(cleaned)
            # Handle case where Gemini returns a list instead of dict
            if isinstance(result, list):
                return {"results": result}
            return result
        except json.JSONDecodeError:
            log.warning("json_parse_failed", raw_text=cleaned[:200])
            return {"raw_text": cleaned, "parse_error": True}


# Singleton instance
_client: Optional[GeminiClient] = None


def get_gemini_client() -> GeminiClient:
    """Get or create the singleton Gemini client."""
    global _client
    if _client is None:
        _client = GeminiClient()
    return _client
