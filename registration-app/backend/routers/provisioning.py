import json
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session as DBSession

from database import get_db
from models.participant import Participant
from models.session import Session
from services.educates_provisioner import EducatesProvisioner
from services.cluster_monitor import ClusterMonitor
from config import settings

router = APIRouter()


def _get_provisioner() -> EducatesProvisioner:
    return EducatesProvisioner(
        portal_url=settings.educates_portal_url,
        robot_client_id=settings.educates_robot_client_id,
        robot_client_secret=settings.educates_robot_client_secret,
        robot_username=settings.educates_robot_username,
        robot_password=settings.educates_robot_password,
        index_url=settings.educates_index_url,
        dry_run=settings.dry_run,
    )


def _provision_one(participant: Participant, provisioner: EducatesProvisioner, db: DBSession):
    participant.status = "provisioning"
    db.commit()
    try:
        provisioner.provision_participant(participant, db)
    except Exception as exc:
        participant.status = "error"
        participant.error_message = str(exc)
        db.commit()


@router.post("/provision")
def provision_all(background_tasks: BackgroundTasks, db: DBSession = Depends(get_db)):
    active_session = (
        db.query(Session)
        .filter(Session.status == "active")
        .order_by(Session.created_at.desc())
        .first()
    )
    if not active_session:
        raise HTTPException(status_code=404, detail="No active session.")

    registered = (
        db.query(Participant)
        .filter(
            Participant.session_id == active_session.id,
            Participant.status == "registered",
        )
        .all()
    )
    if not registered:
        return {"message": "No registered participants to provision.", "count": 0}

    provisioner = _get_provisioner()
    for participant in registered:
        background_tasks.add_task(_provision_one, participant, provisioner, db)

    return {"message": f"Provisioning {len(registered)} participant(s) in background.", "count": len(registered)}


@router.post("/provision/{participant_id}")
def provision_single(participant_id: int, background_tasks: BackgroundTasks, db: DBSession = Depends(get_db)):
    participant = db.query(Participant).filter(Participant.id == participant_id).first()
    if not participant:
        raise HTTPException(status_code=404, detail="Participant not found.")
    if participant.status not in ("registered", "error"):
        raise HTTPException(
            status_code=409,
            detail=f"Participant status is '{participant.status}' — only 'registered' or 'error' can be provisioned.",
        )

    provisioner = _get_provisioner()
    background_tasks.add_task(_provision_one, participant, provisioner, db)
    return {"message": f"Provisioning {participant.name} in background."}


@router.post("/cleanup")
def cleanup_all_sessions(db: DBSession = Depends(get_db)):
    """Delete all Educates workshop sessions and reset participant statuses to 'registered'."""
    provisioner = _get_provisioner()
    provisioner.cleanup_all_sessions()

    active_session = (
        db.query(Session)
        .filter(Session.status == "active")
        .order_by(Session.created_at.desc())
        .first()
    )
    if active_session:
        db.query(Participant).filter(
            Participant.session_id == active_session.id,
            Participant.status.in_(["ready", "provisioning"]),
        ).update(
            {"status": "registered", "workshop_urls": None, "provisioned_at": None, "error_message": None},
            synchronize_session=False,
        )
        db.commit()

    return {"message": "Cleanup complete. All participants reset to 'registered'."}


@router.get("/cluster/status")
def cluster_status():
    monitor = ClusterMonitor(
        kubeconfig_path=settings.kubeconfig_path,
        cluster_context=settings.cluster_context,
        dry_run=settings.dry_run,
    )
    return monitor.get_status()
