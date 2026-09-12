from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.database.session import get_db
from app.schemas.health import HealthResponse

router = APIRouter(tags=["Health"])


@router.get("/health", response_model=HealthResponse)
def health_check(db: Session = Depends(get_db)):
    db_status = "connected"
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError:
        db_status = "disconnected"

    return HealthResponse(
        status="ok" if db_status == "connected" else "degraded",
        project=settings.PROJECT_NAME,
        version=settings.VERSION,
        environment=settings.ENVIRONMENT,
        database=db_status,
    )
