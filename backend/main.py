"""
CIRO Backend — FastAPI Application Entry Point
Sets up CORS, lifespan hooks (Firebase init), and includes all routers.
"""

import structlog
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.config import get_settings

# ── Structlog Configuration ──────────────────────────────────────
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.dev.ConsoleRenderer() if get_settings().debug else structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(0),
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
    cache_logger_on_first_use=True,
)

log = structlog.get_logger()


# ── Firebase Initialization ──────────────────────────────────────
def _init_firebase():
    """Initialize Firebase Admin SDK. Called once at startup."""
    import firebase_admin
    from firebase_admin import credentials as fb_creds

    settings = get_settings()

    if firebase_admin._apps:
        log.info("firebase_already_initialized")
        return

    if settings.firebase_credentials_path:
        cred = fb_creds.Certificate(settings.firebase_credentials_path)
        firebase_admin.initialize_app(cred, {
            "storageBucket": settings.firebase_storage_bucket,
        })
    else:
        # Use Application Default Credentials (Cloud Run / local gcloud auth)
        firebase_admin.initialize_app(options={
            "storageBucket": settings.firebase_storage_bucket,
        })

    log.info("firebase_initialized", project_id=settings.firebase_project_id)


# ── Lifespan ─────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown hooks. Modern pattern (replaces deprecated @app.on_event)."""
    settings = get_settings()

    log.info(
        "ciro_starting",
        app=settings.app_name,
        version=settings.app_version,
        demo_mode=settings.demo_mode,
    )

    # Initialize Firebase
    try:
        _init_firebase()
    except Exception as e:
        log.warning("firebase_init_skipped", error=str(e),
                    hint="Set FIREBASE_CREDENTIALS_PATH or run with Application Default Credentials")

    yield  # ← App runs here

    log.info("ciro_shutting_down")


# ── FastAPI App ──────────────────────────────────────────────────
app = FastAPI(
    title="CIRO — Crisis Intelligence & Response Orchestrator",
    description="Multi-agent crisis response backend powered by Gemini 3",
    version=get_settings().app_version,
    lifespan=lifespan,
)

# ── CORS (permissive for hackathon; restrict in production) ──────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Import and include routers ───────────────────────────────────
from backend.routers import health, signals, incidents, vision, stream, counterfactual, sitrep, hell_mode

app.include_router(health.router, tags=["Health"])
app.include_router(signals.router, prefix="/signals", tags=["Signals"])
app.include_router(incidents.router, prefix="/incidents", tags=["Incidents"])
app.include_router(vision.router, prefix="/vision", tags=["Vision"])
app.include_router(stream.router, prefix="/stream", tags=["Streaming"])
app.include_router(counterfactual.router, prefix="/counterfactual", tags=["Counterfactual"])
app.include_router(sitrep.router, prefix="/sitrep", tags=["SitRep"])
app.include_router(hell_mode.router, prefix="/hell-mode", tags=["Hell Mode"])
