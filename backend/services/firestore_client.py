"""
CIRO Services — Firestore Client
Wrapper around Firebase Admin SDK for reading/writing agent artifacts.
Provides async-friendly helpers for all Firestore collections.
"""

import structlog
from typing import Optional, List
from datetime import datetime

log = structlog.get_logger()

# ── Collection Names ─────────────────────────────────────────────
TRIAGE_COLLECTION = "triage_queue"
SITUATIONS_COLLECTION = "situations"
ACTIONS_COLLECTION = "actions"
INCIDENTS_COLLECTION = "incidents"
COUNTERFACTUAL_COLLECTION = "counterfactual"
MEMORY_COLLECTION = "incident_memory"
SIGNALS_COLLECTION = "signals"


def _get_db():
    """Get Firestore client instance. Lazy import to avoid init-order issues."""
    from firebase_admin import firestore
    return firestore.client()


# ── Write Operations ─────────────────────────────────────────────

def write_triage(triage_data: dict) -> str:
    """Write a Triage Artifact to Firestore. Returns the document ID."""
    db = _get_db()
    doc_id = triage_data.get("triage_id", None)
    if doc_id:
        db.collection(TRIAGE_COLLECTION).document(doc_id).set(triage_data)
    else:
        doc_ref = db.collection(TRIAGE_COLLECTION).add(triage_data)
        doc_id = doc_ref[1].id
    log.info("triage_written", doc_id=doc_id, crisis_type=triage_data.get("crisis_type"))
    return doc_id


def write_situation(situation_data: dict) -> str:
    """Write a Situation Artifact to Firestore."""
    db = _get_db()
    doc_id = situation_data.get("situation_id", None)
    if doc_id:
        db.collection(SITUATIONS_COLLECTION).document(doc_id).set(situation_data)
    else:
        doc_ref = db.collection(SITUATIONS_COLLECTION).add(situation_data)
        doc_id = doc_ref[1].id
    log.info("situation_written", doc_id=doc_id, confidence=situation_data.get("confidence"))
    return doc_id


def write_action(action_data: dict) -> str:
    """Write an Action Artifact to Firestore."""
    db = _get_db()
    doc_id = action_data.get("action_id", None)
    if doc_id:
        db.collection(ACTIONS_COLLECTION).document(doc_id).set(action_data)
    else:
        doc_ref = db.collection(ACTIONS_COLLECTION).add(action_data)
        doc_id = doc_ref[1].id
    log.info("action_written", doc_id=doc_id, status=action_data.get("status"))
    return doc_id


def write_signal(signal_data: dict) -> str:
    """Write a raw signal to Firestore for history."""
    db = _get_db()
    doc_ref = db.collection(SIGNALS_COLLECTION).add(signal_data)
    return doc_ref[1].id


def write_counterfactual(cf_id: str, cf_data: dict):
    """Write counterfactual simulation results."""
    db = _get_db()
    db.collection(COUNTERFACTUAL_COLLECTION).document(cf_id).set(cf_data)
    log.info("counterfactual_written", cf_id=cf_id)


# ── Read Operations ──────────────────────────────────────────────

def get_triage(triage_id: str) -> Optional[dict]:
    """Read a single Triage Artifact."""
    db = _get_db()
    doc = db.collection(TRIAGE_COLLECTION).document(triage_id).get()
    return doc.to_dict() if doc.exists else None


def get_situation(situation_id: str) -> Optional[dict]:
    """Read a single Situation Artifact."""
    db = _get_db()
    doc = db.collection(SITUATIONS_COLLECTION).document(situation_id).get()
    return doc.to_dict() if doc.exists else None


def get_action(action_id: str) -> Optional[dict]:
    """Read a single Action Artifact."""
    db = _get_db()
    doc = db.collection(ACTIONS_COLLECTION).document(action_id).get()
    return doc.to_dict() if doc.exists else None


def get_pending_triages() -> List[dict]:
    """Get all pending Triage Artifacts (for Analyst to process)."""
    db = _get_db()
    docs = (
        db.collection(TRIAGE_COLLECTION)
        .where("status", "==", "pending")
        .order_by("timestamp")
        .limit(10)
        .stream()
    )
    return [doc.to_dict() for doc in docs]


def get_active_incidents() -> List[dict]:
    """Get all active (non-resolved) incidents."""
    db = _get_db()
    situations = (
        db.collection(SITUATIONS_COLLECTION)
        .where("status", "!=", "resolved")
        .order_by("timestamp")
        .stream()
    )
    return [doc.to_dict() for doc in situations]


def get_all_incidents() -> List[dict]:
    """Get all incidents (active + resolved), most recent first."""
    db = _get_db()
    docs = (
        db.collection(SITUATIONS_COLLECTION)
        .order_by("timestamp", direction="DESCENDING")
        .limit(50)
        .stream()
    )
    return [doc.to_dict() for doc in docs]


def get_signals_near(lat: float, lon: float, radius_km: float = 1.0, minutes: int = 30) -> List[dict]:
    """
    Get recent signals near a geographic point.
    Note: Firestore doesn't support native geo queries in all SDKs,
    so we do a rough time-based filter and client-side distance check.
    """
    db = _get_db()
    from datetime import timedelta
    cutoff = datetime.utcnow() - timedelta(minutes=minutes)

    docs = (
        db.collection(SIGNALS_COLLECTION)
        .where("timestamp", ">=", cutoff.isoformat())
        .limit(100)
        .stream()
    )

    results = []
    for doc in docs:
        data = doc.to_dict()
        geo = data.get("geo")
        if geo and "lat" in geo and "lon" in geo:
            # Simple Euclidean distance check (good enough for ~1km radius in Pakistan latitudes)
            dlat = abs(geo["lat"] - lat)
            dlon = abs(geo["lon"] - lon)
            if dlat < radius_km / 111.0 and dlon < radius_km / 85.0:
                results.append(data)
        else:
            # Include signals without geo if they're from the same time window
            results.append(data)

    return results


# ── Update Operations ────────────────────────────────────────────

def update_triage_status(triage_id: str, status: str):
    """Update a triage artifact's status."""
    db = _get_db()
    db.collection(TRIAGE_COLLECTION).document(triage_id).update({"status": status})


def update_situation_status(situation_id: str, status: str):
    """Update a situation artifact's status."""
    db = _get_db()
    db.collection(SITUATIONS_COLLECTION).document(situation_id).update({"status": status})
