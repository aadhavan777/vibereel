from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr


class UserResponse(BaseModel):
    id: UUID
    email: EmailStr
    username: str
    display_name: str | None = None
    bio: str | None = None
    avatar_url: str | None = None
    banner_url: str | None = None
    website: str | None = None
    is_creator: bool = False
    is_active: bool = True
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class UserUpdate(BaseModel):
    display_name: str | None = None
    bio: str | None = None
    avatar_url: str | None = None
    banner_url: str | None = None
    website: str | None = None
    is_creator: bool | None = None


class UserProfilePublic(BaseModel):
    id: UUID
    username: str
    display_name: str | None = None
    bio: str | None = None
    avatar_url: str | None = None
    banner_url: str | None = None
    is_creator: bool = False
    followers_count: int = 0
    following_count: int = 0
    videos_count: int = 0

    model_config = ConfigDict(from_attributes=True)
