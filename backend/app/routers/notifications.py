from typing import Any, cast
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.dependencies.auth import get_current_active_user
from app.models.user import User
from app.schemas.notification import NotificationListResponse
from app.services.notification_service import notification_service

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=NotificationListResponse)
def get_user_notifications(
    unread_only: bool = Query(False),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    return notification_service.get_user_notifications(
        db,
        recipient_id=cast(UUID, current_user.id),
        unread_only=unread_only,
        page=page,
        limit=limit,
    )


@router.get("/unread-count")
def get_unread_notification_count(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    res = notification_service.get_user_notifications(
        db, recipient_id=cast(UUID, current_user.id), unread_only=True, limit=1
    )
    return {"unread_count": res.unread_count}


@router.put("/{notification_id}/read", response_model=dict[str, str])
def mark_notification_read(
    notification_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    success = notification_service.mark_as_read(db, notification_id, cast(UUID, current_user.id))
    if not success:
        return {"status": "not_found_or_already_read"}
    return {"status": "success"}


@router.put("/read-all", response_model=dict[str, Any])
def mark_all_notifications_read(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    count = notification_service.mark_all_as_read(db, cast(UUID, current_user.id))
    return {"status": "success", "marked_read_count": count}

