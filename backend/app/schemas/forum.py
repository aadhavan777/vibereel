from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.schemas.user import UserResponse


class ForumPostCreate(BaseModel):
    title: str
    content: str
    category: str = "video_editing"
    tags: str | None = None


class ForumPostUpdate(BaseModel):
    title: str | None = None
    content: str | None = None
    category: str | None = None
    tags: str | None = None


class ForumPostResponse(BaseModel):
    id: UUID
    author_id: UUID
    title: str
    content: str
    category: str
    tags: str | None = None
    views_count: int = 0
    likes_count: int = 0
    comments_count: int = 0
    is_liked: bool = False
    created_at: datetime
    updated_at: datetime
    author: UserResponse | None = None

    model_config = ConfigDict(from_attributes=True)


class ForumPostListResponse(BaseModel):
    items: list[ForumPostResponse]
    total: int
    page: int = 1
    limit: int = 20
    next_cursor: str | None = None
    has_more: bool = False


class ForumCommentCreate(BaseModel):
    content: str
    parent_comment_id: UUID | None = None


class ForumCommentResponse(BaseModel):
    id: UUID
    post_id: UUID
    author_id: UUID
    parent_comment_id: UUID | None = None
    content: str
    likes_count: int = 0
    is_liked: bool = False
    created_at: datetime
    author: UserResponse | None = None
    replies: list["ForumCommentResponse"] = []

    model_config = ConfigDict(from_attributes=True)


class ForumReportCreate(BaseModel):
    post_id: UUID | None = None
    comment_id: UUID | None = None
    reason: str
    details: str | None = None


class ForumReportResponse(BaseModel):
    id: UUID
    reporter_id: UUID
    post_id: UUID | None = None
    comment_id: UUID | None = None
    reason: str
    details: str | None = None
    status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CollaborationCreate(BaseModel):
    target_user_id: UUID
    title: str
    description: str


class CollaborationResponse(BaseModel):
    id: UUID
    initiator_id: UUID
    target_user_id: UUID
    title: str
    description: str
    status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

