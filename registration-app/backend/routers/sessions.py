from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session as DBSession
from pydantic import BaseModel

from database import get_db
from models.session import Session

router = APIRouter()


class CreateSessionRequest(BaseModel):
    name: str
    event_date: Optional[str] = None   # ISO date string, e.g. "2026-03-15"


class UpdateSessionRequest(BaseModel):
    name: Optional[str] = None
    event_date: Optional[str] = None


@router.post("/sessions", status_code=201)
def create_session(req: CreateSessionRequest, db: DBSession = Depends(get_db)):
    session = Session(name=req.name, event_date=req.event_date, status="active")
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.get("/sessions")
def list_sessions(db: DBSession = Depends(get_db)):
    return db.query(Session).order_by(Session.created_at.desc()).all()


@router.get("/sessions/active")
def get_active_session(db: DBSession = Depends(get_db)):
    session = (
        db.query(Session)
        .filter(Session.status == "active")
        .order_by(Session.created_at.desc())
        .first()
    )
    if not session:
        raise HTTPException(status_code=404, detail="No active session.")
    return session


@router.put("/sessions/{session_id}")
def update_session(session_id: int, req: UpdateSessionRequest, db: DBSession = Depends(get_db)):
    """Update a session's name and/or event date."""
    session = db.query(Session).filter(Session.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found.")
    if req.name is not None:
        session.name = req.name
    if req.event_date is not None:
        session.event_date = req.event_date
    db.commit()
    db.refresh(session)
    return session


@router.put("/sessions/{session_id}/activate")
def activate_session(session_id: int, db: DBSession = Depends(get_db)):
    # Deactivate all other sessions
    db.query(Session).filter(Session.status == "active").update({"status": "completed"})
    session = db.query(Session).filter(Session.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found.")
    session.status = "active"
    db.commit()
    db.refresh(session)
    return session


@router.delete("/sessions/{session_id}", status_code=204)
def archive_session(session_id: int, db: DBSession = Depends(get_db)):
    session = db.query(Session).filter(Session.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found.")
    session.status = "archived"
    db.commit()
