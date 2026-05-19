from fastapi import APIRouter, Form, Request, BackgroundTasks
import structlog
from typing import Optional
import time
import uuid
from backend.models.signal import Signal

# Note: In a real app we'd import process_signal from sentinel, 
# but for this mock we will just log it or simulate background dispatch.
# from backend.agents.sentinel import process_signal

router = APIRouter()
logger = structlog.get_logger(__name__)

@router.post("/webhook")
async def twilio_voice_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
    CallSid: str = Form(default="unknown"),
    From: str = Form(default="unknown"),
    RecordingUrl: Optional[str] = Form(None),
    SpeechResult: Optional[str] = Form(None)
):
    """
    Twilio voice webhook for handling incoming emergency calls.
    If SpeechResult is present, it means Twilio's STT has transcribed the caller.
    """
    logger.info("voice_webhook_received", call_sid=CallSid, from_number=From)
    
    if SpeechResult:
        logger.info("voice_transcription", transcription=SpeechResult)
        
        # Convert transcription into a Signal
        signal = Signal(
            id=f"voice-{uuid.uuid4().hex[:8]}",
            source="twilio_voice",
            text=SpeechResult,
            timestamp=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            location=None,
            metadata={"call_sid": CallSid, "caller": From, "recording_url": RecordingUrl}
        )
        
        # We would normally dispatch to Sentinel here:
        # background_tasks.add_task(process_signal, signal)
        logger.info("signal_dispatched_to_sentinel", signal_id=signal.id)
        
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Say>Ap ki report darj kar li gayi hai. Rescue teams alert ki ja rahi hain.</Say></Response>"
    else:
        # Prompt the caller to speak
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response><Gather input=\"speech\" action=\"/voice/webhook\" timeout=\"5\"><Say>CIRO Emergency. Please state your emergency clearly.</Say></Gather></Response>"
