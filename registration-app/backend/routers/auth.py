from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from config import settings

router = APIRouter()


class VerifyRequest(BaseModel):
    password: str


@router.post("/auth/verify")
def verify_admin(req: VerifyRequest):
    """
    Verify the admin password.
    Returns 200 {"ok": true} if correct (or if no password is set — dev mode).
    Returns 401 if wrong.
    """
    if not settings.admin_password:
        # No password configured — allow all (local dev mode)
        return {"ok": True, "dev_mode": True}

    if req.password != settings.admin_password:
        raise HTTPException(status_code=401, detail="Incorrect password.")

    return {"ok": True, "dev_mode": False}
