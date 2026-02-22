from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.orm import relationship
from database import Base


class Session(Base):
    __tablename__ = "sessions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    event_date = Column(String, nullable=True)            # ISO date string, e.g. "2026-03-15"
    created_at = Column(DateTime, default=datetime.utcnow)
    cluster_uid = Column(String, nullable=True)           # kube-system namespace UID at session creation
    status = Column(String, default="active")             # active | completed | archived

    participants = relationship("Participant", back_populates="session", cascade="all, delete-orphan")
