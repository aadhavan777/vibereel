from typing import Any, cast
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.models.user import User
from app.schemas.notification import NotificationListResponse, NotificationResponse
from app.schemas.user import UserResponse


class NotificationService:
    def create_notification(
        self,
        db: Session,
        recipient_id: UUID,
        type: str,
        title: str,
        message: str,
        actor_id: UUID | None = None,
        entity_type: str | None = None,
        entity_id: UUID | None = None,
    ) -> Notification | None:
        # Don't notify oneself
        if actor_id and recipient_id == actor_id:
            return None

        # Duplicate prevention check:
        # If recipient has an unread notification of same type and entity_id from same actor, don't create duplicate
        if actor_id and entity_id:
            existing = db.scalar(
                select(Notification).where(
                    Notification.recipient_id == recipient_id,
                    Notification.actor_id == actor_id,
                    Notification.type == type,
                    Notification.entity_id == entity_id,
                    Notification.is_read == False,  # noqa: E712
                )
            )
            if existing:
                return existing

        notification = Notification(
            recipient_id=recipient_id,
            actor_id=actor_id,
            type=type,
            title=title,
            message=message,
            entity_type=entity_type,
            entity_id=entity_id,
            is_read=False,
        )
        db.add(notification)
        db.commit()
        db.refresh(notification)
        return notification

    def get_user_notifications(
        self, db: Session, recipient_id: UUID, unread_only: bool = False, page: int = 1, limit: int = 20
    ) -> NotificationListResponse:
        offset = (page - 1) * limit
        stmt = select(Notification).where(Notification.recipient_id == recipient_id)
        if unread_only:
            stmt = stmt.where(Notification.is_read == False)  # noqa: E712

        stmt = stmt.order_by(Notification.created_at.desc()).offset(offset).limit(limit)
        notifications = db.scalars(stmt).all()

        unread_count = (
            db.scalar(
                select(func.count(Notification.id)).where(
                    Notification.recipient_id == recipient_id, Notification.is_read == False  # noqa: E712
                )
            )
            or 0
        )

        items = []
        for n in notifications:
            actor_user = db.scalar(select(User).where(User.id == n.actor_id)) if n.actor_id else None
            actor_resp = UserResponse.model_validate(actor_user) if actor_user else None
            items.append(
                NotificationResponse(
                    id=cast(UUID, n.id),
                    recipient_id=cast(UUID, n.recipient_id),
                    actor_id=cast(UUID | None, n.actor_id),
                    type=cast(str, n.type),
                    title=cast(str, n.title),
                    message=cast(str, n.message),
                    entity_type=cast(str | None, n.entity_type),
                    entity_id=cast(UUID | None, n.entity_id),
                    is_read=cast(bool, n.is_read),
                    created_at=cast(Any, n.created_at),
                    actor=actor_resp,
                )
            )

        return NotificationListResponse(
            items=items,
            unread_count=int(unread_count),
            total=len(items),
            page=page,
            limit=limit,
        )

    def mark_as_read(self, db: Session, notification_id: UUID, recipient_id: UUID) -> bool:
        n = db.scalar(select(Notification).where(Notification.id == notification_id, Notification.recipient_id == recipient_id))
        if n:
            n.is_read = True  # type: ignore
            db.commit()
            return True
        return False

    def mark_all_as_read(self, db: Session, recipient_id: UUID) -> int:
        unread = db.scalars(
            select(Notification).where(Notification.recipient_id == recipient_id, Notification.is_read == False)  # noqa: E712
        ).all()
        for n in unread:
            n.is_read = True  # type: ignore
        db.commit()
        return len(unread)


notification_service = NotificationService()
