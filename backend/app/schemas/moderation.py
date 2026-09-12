from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ContentReportCreate(BaseModel):
    entity_type: str = Field(..., description="Type of content: video, forum_post, forum_comment, video_comment")
    entity_id: UUID = Field(..., description="ID of target content")
    reason: str = Field(..., min_length=2, max_length=100, description="Reason for reporting")
    details: str | None = Field(None, max_length=1000, description="Optional supporting details")


class ContentReportResponse(BaseModel):
    id: UUID
    reporter_id: UUID
    entity_type: str
    entity_id: UUID
    reason: str
    details: str | None = None
    status: str
    created_at: Any

    model_config = ConfigDict(from_attributes=True)


class UserBlockResponse(BaseModel):
    status: str
    blocked_user_id: UUID


class UserBlockListResponse(BaseModel):
    blocked_user_ids: list[UUID]
