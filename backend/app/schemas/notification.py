from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.schemas.user import UserResponse


class NotificationResponse(BaseModel):
    id: UUID
    recipient_id: UUID
    actor_id: UUID | None = None
    type: str  # like, comment, reply, follow, mention, forum_reply, collaboration_request
    title: str
    message: str
    entity_type: str | None = None
    entity_id: UUID | None = None
    is_read: bool = False
    created_at: datetime
    actor: UserResponse | None = None

    model_config = ConfigDict(from_attributes=True)


class NotificationListResponse(BaseModel):
    items: list[NotificationResponse]
    unread_count: int
    total: int
    page: int = 1
    limit: int = 20

