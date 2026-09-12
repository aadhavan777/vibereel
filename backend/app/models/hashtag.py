from sqlalchemy import Column, ForeignKey, String, Table
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database.session import Base
from app.models.base import BaseModel

video_hashtags = Table(
    "video_hashtags",
    Base.metadata,
    Column("video_id", UUID(as_uuid=True), ForeignKey("videos.id", ondelete="CASCADE"), primary_key=True),
    Column("hashtag_id", UUID(as_uuid=True), ForeignKey("hashtags.id", ondelete="CASCADE"), primary_key=True),
)


class Hashtag(BaseModel):
    __tablename__ = "hashtags"

    name = Column(String(100), unique=True, index=True, nullable=False)

    videos = relationship("Video", secondary=video_hashtags, back_populates="hashtags")
