from typing import Any, cast
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.video import Like, SavedVideo, Video
from app.repositories.video_repository import video_repository
from app.schemas.video import FeedResponse, VideoCreate, VideoResponse


class VideoService:
    def get_feed(self, db: Session, page: int = 1, limit: int = 10, current_user_id: UUID | None = None) -> FeedResponse:
        skip = (page - 1) * limit
        items = video_repository.get_feed(db, skip=skip, limit=limit)
        response_items = []
        for v in items:
            creator = db.scalar(select(User).where(User.id == v.user_id))
            creator_username = str(creator.username) if creator else "vibemaster"
            creator_avatar_url = (
                str(creator.profile.avatar_url) if (creator and creator.profile and creator.profile.avatar_url) else None
            )

            is_liked = False
            is_saved = False
            if current_user_id:
                like_exists = db.scalar(select(Like).where(Like.user_id == current_user_id, Like.video_id == v.id))
                is_liked = like_exists is not None
                save_exists = db.scalar(select(SavedVideo).where(SavedVideo.user_id == current_user_id, SavedVideo.video_id == v.id))
                is_saved = save_exists is not None

            response_items.append(
                VideoResponse(
                    id=cast(UUID, v.id),
                    creator_id=cast(UUID, v.user_id),
                    creator_username=creator_username,
                    creator_avatar_url=creator_avatar_url,
                    caption=cast(str | None, v.caption),
                    video_url=cast(str, v.video_url),
                    thumbnail_url=cast(str | None, v.thumbnail_url),
                    duration_seconds=cast(float | None, v.duration_seconds),
                    is_draft=cast(bool, v.is_draft),
                    is_private=cast(bool, v.is_private),
                    likes_count=cast(Any, v.likes_count),
                    comments_count=cast(Any, v.comments_count),
                    saves_count=cast(Any, v.saves_count),
                    shares_count=0,
                    is_liked=is_liked,
                    is_saved=is_saved,
                    audio_title=f"Original Audio - @{creator_username}",
                    audio_artist=creator_username,
                    hashtags=["flutter", "vibereel", "shortvideo"],
                    created_at=cast(Any, v.created_at),
                )
            )
        return FeedResponse(items=response_items, total=len(response_items), page=page, limit=limit)

    def create_video(self, db: Session, user: User, video_in: VideoCreate) -> Video:
        video = Video(
            user_id=user.id,
            caption=video_in.caption,
            video_url=video_in.video_url,
            thumbnail_url=video_in.thumbnail_url,
            duration_seconds=video_in.duration_seconds,
            is_draft=video_in.is_draft,
            is_private=video_in.is_private,
        )
        db.add(video)
        db.commit()
        db.refresh(video)
        return video


video_service = VideoService()
