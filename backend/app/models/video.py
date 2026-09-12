from sqlalchemy import (
    Boolean,
    Column,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class Video(BaseModel):
    __tablename__ = "videos"
    __table_args__ = (
        Index("ix_videos_draft_created", "is_draft", "created_at"),
        Index("ix_videos_user_draft", "user_id", "is_draft"),
    )

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), nullable=True)
    caption = Column(Text, nullable=True)
    video_url = Column(String(512), nullable=False)
    thumbnail_url = Column(String(512), nullable=True)
    duration_seconds = Column(Float, nullable=True)

    views_count = Column(Integer, default=0, nullable=False)
    likes_count = Column(Integer, default=0, nullable=False)
    comments_count = Column(Integer, default=0, nullable=False)
    saves_count = Column(Integer, default=0, nullable=False)

    is_draft = Column(Boolean, default=False, nullable=False)
    is_private = Column(Boolean, default=False, nullable=False)

    user = relationship("User", back_populates="videos")
    comments = relationship("Comment", back_populates="video", cascade="all, delete-orphan")
    likes = relationship("Like", back_populates="video", cascade="all, delete-orphan")
    saves = relationship("SavedVideo", back_populates="video", cascade="all, delete-orphan")
    views = relationship("View", back_populates="video", cascade="all, delete-orphan")
    hashtags = relationship("Hashtag", secondary="video_hashtags", back_populates="videos")


class Comment(BaseModel):
    __tablename__ = "comments"
    __table_args__ = (
        Index("ix_comments_video_created", "video_id", "created_at"),
    )

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    video_id = Column(UUID(as_uuid=True), ForeignKey("videos.id", ondelete="CASCADE"), nullable=False, index=True)
    parent_comment_id = Column(
        UUID(as_uuid=True), ForeignKey("comments.id", ondelete="CASCADE"), nullable=True, index=True
    )
    content = Column(Text, nullable=False)


    user = relationship("User", back_populates="comments")
    video = relationship("Video", back_populates="comments")
    parent_comment = relationship("Comment", remote_side="Comment.id", back_populates="replies")
    replies = relationship("Comment", back_populates="parent_comment", cascade="all, delete-orphan")


class Like(BaseModel):
    __tablename__ = "likes"
    __table_args__ = (
        UniqueConstraint("user_id", "video_id", name="uq_user_video_like"),
        Index("ix_likes_user_video", "user_id", "video_id"),
    )

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    video_id = Column(UUID(as_uuid=True), ForeignKey("videos.id", ondelete="CASCADE"), nullable=False, index=True)

    user = relationship("User", back_populates="likes")
    video = relationship("Video", back_populates="likes")


class SavedVideo(BaseModel):
    __tablename__ = "saved_videos"
    __table_args__ = (
        UniqueConstraint("user_id", "video_id", name="uq_user_video_save"),
        Index("ix_saved_videos_user_video", "user_id", "video_id"),
    )

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    video_id = Column(UUID(as_uuid=True), ForeignKey("videos.id", ondelete="CASCADE"), nullable=False, index=True)

    user = relationship("User", back_populates="saved_videos")
    video = relationship("Video", back_populates="saves")


class View(BaseModel):
    __tablename__ = "views"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    video_id = Column(UUID(as_uuid=True), ForeignKey("videos.id", ondelete="CASCADE"), nullable=False, index=True)
    watch_duration_seconds = Column(Float, default=0.0, nullable=False)
    ip_address = Column(String(45), nullable=True)

    user = relationship("User", back_populates="views")
    video = relationship("Video", back_populates="views")
