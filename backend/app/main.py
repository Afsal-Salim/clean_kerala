from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.audit_middleware import AuditMiddleware
from app.core.config import settings
from app.db.audit_events import register_audit_events
from app.db.base import Base
from app.db.session import engine
from app.modules.analytics.router import router as analytics_router
from app.modules.auth.router import router as auth_router
from app.modules.profile.router import router as profile_router
from app.modules.quotes.router import router as quotes_router
from app.modules.reports.router import router as reports_router
import app.models  # noqa: F401 — register all models with SQLAlchemy metadata
from scripts.seed import seed_if_empty

register_audit_events()


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    seed_if_empty()
    yield


app = FastAPI(
    title="Make Kerala Clean API",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(AuditMiddleware)

app.include_router(auth_router, prefix="/api/v1")
app.include_router(profile_router, prefix="/api/v1")
app.include_router(quotes_router, prefix="/api/v1")
app.include_router(reports_router, prefix="/api/v1")
app.include_router(analytics_router, prefix="/api/v1")

upload_path = Path(settings.upload_dir)
upload_path.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(upload_path)), name="uploads")


@app.get("/api/v1/health")
def health():
    return {"status": "ok", "service": "make-kerala-clean"}
