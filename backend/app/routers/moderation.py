from typing import cast
from uuid import UUID

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.orm import Session

from app.core.rate_limiter import rate_limiter_reports
from app.database.session import get_db
from app.dependencies.auth import get_current_active_user
from app.models.user import User
from app.schemas.moderation import (
    ContentReportCreate,
    ContentReportResponse,
    UserBlockListResponse,
    UserBlockResponse,
)
from app.services.moderation_service import moderation_service

router = APIRouter(prefix="/moderation", tags=["Moderation"])



@router.post("/reports", response_model=ContentReportResponse, status_code=status.HTTP_201_CREATED)
def submit_report(
    report_in: ContentReportCreate,
    request: Request,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    _: None = Depends(rate_limiter_reports.check_rate_limit),
) -> ContentReportResponse:
    return moderation_service.create_report(db, current_user, report_in)



@router.post("/blocks/{user_id}", response_model=UserBlockResponse)
def block_user(
    user_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> UserBlockResponse:
    moderation_service.block_user(db, current_user, user_id)
    return UserBlockResponse(status="blocked", blocked_user_id=user_id)


@router.delete("/blocks/{user_id}", response_model=UserBlockResponse)
def unblock_user(
    user_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> UserBlockResponse:
    moderation_service.unblock_user(db, current_user, user_id)
    return UserBlockResponse(status="unblocked", blocked_user_id=user_id)


@router.get("/blocks", response_model=UserBlockListResponse)
def get_blocked_users(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> UserBlockListResponse:
    user_id = cast(UUID, current_user.id)
    blocked_ids = moderation_service.get_blocked_user_ids(db, user_id)
    return UserBlockListResponse(blocked_user_ids=blocked_ids)

