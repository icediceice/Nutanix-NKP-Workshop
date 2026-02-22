import csv
import io
import json
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session as DBSession

from database import get_db
from models.participant import Participant
from models.session import Session
from services.excel_parser import ExcelParser

router = APIRouter()


@router.post("/import")
async def import_excel(file: UploadFile = File(...), db: DBSession = Depends(get_db)):
    """Bulk-register participants from an uploaded .xlsx file."""
    if not file.filename.endswith(".xlsx"):
        raise HTTPException(status_code=422, detail="Only .xlsx files are supported.")

    active_session = (
        db.query(Session)
        .filter(Session.status == "active")
        .order_by(Session.created_at.desc())
        .first()
    )
    if not active_session:
        raise HTTPException(status_code=404, detail="No active session.")

    contents = await file.read()
    parser = ExcelParser()
    rows, errors = parser.parse(contents)

    created = []
    skipped = []
    for row in rows:
        existing = (
            db.query(Participant)
            .filter(Participant.email == row["email"], Participant.session_id == active_session.id)
            .first()
        )
        if existing:
            skipped.append(row["email"])
            continue

        from routers.registration import generate_username
        participant = Participant(
            session_id=active_session.id,
            name=row["name"],
            email=row["email"],
            company=row.get("company", ""),
            modules=json.dumps(row["modules"]),
            username=generate_username(row["email"]),
            status="registered",
        )
        db.add(participant)
        created.append(row["email"])

    db.commit()
    return {
        "imported": len(created),
        "skipped": len(skipped),
        "errors": errors,
        "created": created,
        "skipped_emails": skipped,
    }


@router.get("/import/template")
def download_template():
    """Download a formatted Excel template for bulk import."""
    parser = ExcelParser()
    content = parser.generate_template()
    return StreamingResponse(
        io.BytesIO(content),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=participant-template.xlsx"},
    )


@router.get("/export/csv")
def export_csv(session_id: Optional[int] = None, db: DBSession = Depends(get_db)):
    """Export participant credentials and workshop URLs as CSV."""
    query = db.query(Participant).filter(Participant.status == "ready")
    if session_id:
        query = query.filter(Participant.session_id == session_id)
    participants = query.all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["name", "email", "company", "modules", "username", "status", "workshop_urls"])

    for p in participants:
        urls_str = ""
        if p.workshop_urls:
            urls = json.loads(p.workshop_urls)
            urls_str = " | ".join(f"{k}: {v}" for k, v in urls.items())
        modules_str = ", ".join(json.loads(p.modules)) if p.modules else ""
        writer.writerow([p.name, p.email, p.company or "", modules_str, p.username or "", p.status, urls_str])

    output.seek(0)
    return StreamingResponse(
        io.StringIO(output.getvalue()),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=participants.csv"},
    )
