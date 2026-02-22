from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from database import Base


class Participant(Base):
    __tablename__ = "participants"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(Integer, ForeignKey("sessions.id"), nullable=False)
    name = Column(String, nullable=False)
    email = Column(String, nullable=False)
    company = Column(String, nullable=True)
    modules = Column(String, nullable=False)           # JSON: ["app-development", "istio-service-mesh"]
    status = Column(String, default="registered")     # registered | provisioning | ready | error
    username = Column(String, nullable=True)           # generated from email local part
    workshop_urls = Column(String, nullable=True)      # JSON: {"k8s-intro": "https://...", ...}
    error_message = Column(String, nullable=True)
    registered_at = Column(DateTime, default=datetime.utcnow)
    provisioned_at = Column(DateTime, nullable=True)

    session = relationship("Session", back_populates="participants")
