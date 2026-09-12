from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.dependencies.db import get_db
from app.schemas.video import FeedResponse
from app.services.video_service import video_service

router = APIRouter(prefix="/feed", tags=["Feed"])


@router.get("", response_model=FeedResponse)
def get_video_feed(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
):
    return video_service.get_feed(db, page=page, limit=limit)
