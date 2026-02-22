import os
import re
import json
import yaml
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session as DBSession
from pydantic import BaseModel

from database import get_db
from models.participant import Participant
from models.session import Session

router = APIRouter()

COURSES_YAML = os.path.join(os.path.dirname(__file__), "..", "..", "..", "courses.yaml")


def _load_valid_bundle_ids() -> List[str]:
    path = os.path.abspath(COURSES_YAML)
    if not os.path.exists(path):
        path = "courses.yaml"
    with open(path) as f:
        data = yaml.safe_load(f)
    return list(data.get("bundles", {}).keys())


class RegisterRequest(BaseModel):
    name: str
    email: str
    company: str = ""
    modules: List[str]  # list of bundle IDs, e.g. ["app-development", "istio-service-mesh"]


def generate_username(email: str) -> str:
    local = email.split("@")[0]
    username = re.sub(r"[^a-z0-9]", "-", local.lower())
    username = re.sub(r"-+", "-", username).strip("-")
    return username


def get_active_session(db: DBSession) -> Session:
    session = (
        db.query(Session)
        .filter(Session.status == "active")
        .order_by(Session.created_at.desc())
        .first()
    )
    if not session:
        raise HTTPException(
            status_code=404,
            detail="No active session. Ask the trainer to create a session first.",
        )
    return session


@router.post("/register", status_code=201)
def register_participant(req: RegisterRequest, db: DBSession = Depends(get_db)):
    if not req.modules:
        raise HTTPException(status_code=422, detail="Please select at least one learning module.")

    valid_bundles = _load_valid_bundle_ids()
    invalid = [m for m in req.modules if m not in valid_bundles]
    if invalid:
        raise HTTPException(status_code=422, detail=f"Unknown module(s): {invalid}. Valid: {valid_bundles}")

    active_session = get_active_session(db)

    existing = (
        db.query(Participant)
        .filter(Participant.email == req.email, Participant.session_id == active_session.id)
        .first()
    )
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered for this session.")

    username = generate_username(req.email)
    participant = Participant(
        session_id=active_session.id,
        name=req.name,
        email=req.email,
        company=req.company,
        modules=json.dumps(req.modules),
        username=username,
        status="registered",
    )
    db.add(participant)
    db.commit()
    db.refresh(participant)

    return {
        "message": "Registration successful",
        "participant": {
            "id": participant.id,
            "name": participant.name,
            "username": participant.username,
            "modules": req.modules,
            "session": active_session.name,
        },
    }


@router.get("/status/{email}")
def participant_status(email: str, db: DBSession = Depends(get_db)):
    active_session = get_active_session(db)
    participant = (
        db.query(Participant)
        .filter(Participant.email == email, Participant.session_id == active_session.id)
        .first()
    )
    if not participant:
        raise HTTPException(status_code=404, detail="Participant not found in active session.")

    urls = json.loads(participant.workshop_urls) if participant.workshop_urls else {}
    modules = json.loads(participant.modules) if participant.modules else []
    return {
        "name": participant.name,
        "modules": modules,
        "status": participant.status,
        "workshop_urls": urls,
        "error_message": participant.error_message,
    }


@router.get("/participants")
def list_participants(
    session_id: Optional[int] = None,
    status: Optional[str] = None,
    db: DBSession = Depends(get_db),
):
    query = db.query(Participant)
    if session_id:
        query = query.filter(Participant.session_id == session_id)
    if status:
        query = query.filter(Participant.status == status)
    return query.order_by(Participant.registered_at.desc()).all()


@router.delete("/participants/{participant_id}", status_code=204)
def delete_participant(participant_id: int, db: DBSession = Depends(get_db)):
    participant = db.query(Participant).filter(Participant.id == participant_id).first()
    if not participant:
        raise HTTPException(status_code=404, detail="Participant not found.")
    db.delete(participant)
    db.commit()
