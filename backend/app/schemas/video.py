from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.schemas.user import UserResponse


class VideoCreate(BaseModel):
    caption: str | None = None
    video_url: str
    thumbnail_url: str | None = None
    duration_seconds: float | None = None
    is_draft: bool = False
    is_private: bool = False
    audio_title: str | None = None
    audio_artist: str | None = None
    hashtags: list[str] = []


class VideoResponse(BaseModel):
    id: UUID
    creator_id: UUID
    creator_username: str
    creator_avatar_url: str | None = None
    caption: str | None = None
    video_url: str
    thumbnail_url: str | None = None
    duration_seconds: float | None = None
    is_draft: bool
    is_private: bool
    likes_count: int
    comments_count: int
    saves_count: int
    shares_count: int
    is_liked: bool = False
    is_saved: bool = False
    audio_title: str | None = None
    audio_artist: str | None = None
    hashtags: list[str] = []
    created_at: datetime
    creator: UserResponse | None = None

    model_config = ConfigDict(from_attributes=True)


class FeedResponse(BaseModel):
    items: list[VideoResponse]
    total: int
    page: int
    limit: int


class CommentCreate(BaseModel):
    content: str
    parent_comment_id: UUID | None = None


class CommentResponse(BaseModel):
    id: UUID
    video_id: UUID
    user_id: UUID
    username: str
    avatar_url: str | None = None
    content: str
    parent_comment_id: UUID | None = None
    likes_count: int = 0
    is_liked: bool = False
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
