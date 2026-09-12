from uuid import UUID

from sqlalchemy.orm import Session

from app.models.video import Video
from app.repositories.base import BaseRepository


class VideoRepository(BaseRepository[Video]):
    def __init__(self):
        super().__init__(Video)

    def get_feed(self, db: Session, skip: int = 0, limit: int = 10) -> list[Video]:
        return (
            db.query(Video)
            .filter(Video.is_draft == False, Video.is_private == False)
            .order_by(Video.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def get_by_creator(self, db: Session, creator_id: UUID, include_drafts: bool = False) -> list[Video]:
        query = db.query(Video).filter(Video.creator_id == creator_id)
        if not include_drafts:
            query = query.filter(Video.is_draft == False)
        return query.order_by(Video.created_at.desc()).all()


video_repository = VideoRepository()
