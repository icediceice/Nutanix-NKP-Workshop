from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from database import engine, Base
from routers import registration, sessions, provisioning, import_export, courses


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create all tables on startup
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title=settings.app_title,
    description="NKP Workshop Registration and Provisioning Platform",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(registration.router, prefix="/api", tags=["registration"])
app.include_router(sessions.router, prefix="/api", tags=["sessions"])
app.include_router(provisioning.router, prefix="/api", tags=["provisioning"])
app.include_router(import_export.router, prefix="/api", tags=["import-export"])
app.include_router(courses.router, prefix="/api", tags=["courses"])


@app.get("/health")
def health():
    return {"status": "ok", "app": settings.app_title, "dry_run": settings.dry_run}
