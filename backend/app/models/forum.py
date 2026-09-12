from sqlalchemy import (
    Column,
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


class ForumPost(BaseModel):
    __tablename__ = "forum_posts"
    __table_args__ = (
        Index("ix_forum_posts_category_created", "category", "created_at"),
    )

    author_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    category = Column(String(50), nullable=False, default="video_editing", index=True)
    tags = Column(String(255), nullable=True)
    views_count = Column(Integer, default=0, nullable=False)
    likes_count = Column(Integer, default=0, nullable=False)
    comments_count = Column(Integer, default=0, nullable=False)

    author = relationship("User", back_populates="forum_posts")
    comments = relationship("ForumComment", back_populates="post", cascade="all, delete-orphan")
    likes = relationship("ForumLike", back_populates="post", cascade="all, delete-orphan")
    reports = relationship("ForumReport", back_populates="post", cascade="all, delete-orphan")


class ForumComment(BaseModel):
    __tablename__ = "forum_comments"
    __table_args__ = (
        Index("ix_forum_comments_post_created", "post_id", "created_at"),
    )

    post_id = Column(UUID(as_uuid=True), ForeignKey("forum_posts.id", ondelete="CASCADE"), nullable=False, index=True)
    author_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    parent_comment_id = Column(
        UUID(as_uuid=True), ForeignKey("forum_comments.id", ondelete="CASCADE"), nullable=True, index=True
    )
    content = Column(Text, nullable=False)
    likes_count = Column(Integer, default=0, nullable=False)


    post = relationship("ForumPost", back_populates="comments")
    author = relationship("User", back_populates="forum_comments")
    parent_comment = relationship("ForumComment", remote_side="ForumComment.id", back_populates="replies")
    replies = relationship("ForumComment", back_populates="parent_comment", cascade="all, delete-orphan")
    likes = relationship("ForumCommentLike", back_populates="comment", cascade="all, delete-orphan")


class ForumLike(BaseModel):
    __tablename__ = "forum_likes"
    __table_args__ = (
        UniqueConstraint("user_id", "post_id", name="uq_user_forum_post_like"),
        Index("ix_forum_likes_user_post", "user_id", "post_id"),
    )

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    post_id = Column(UUID(as_uuid=True), ForeignKey("forum_posts.id", ondelete="CASCADE"), nullable=False, index=True)

    user = relationship("User", back_populates="forum_likes")
    post = relationship("ForumPost", back_populates="likes")


class ForumCommentLike(BaseModel):
    __tablename__ = "forum_comment_likes"
    __table_args__ = (
        UniqueConstraint("user_id", "comment_id", name="uq_user_forum_comment_like"),
        Index("ix_forum_comment_likes_user_comment", "user_id", "comment_id"),
    )

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    comment_id = Column(UUID(as_uuid=True), ForeignKey("forum_comments.id", ondelete="CASCADE"), nullable=False, index=True)

    user = relationship("User")
    comment = relationship("ForumComment", back_populates="likes")


class ForumReport(BaseModel):
    __tablename__ = "forum_reports"

    reporter_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    post_id = Column(UUID(as_uuid=True), ForeignKey("forum_posts.id", ondelete="CASCADE"), nullable=True, index=True)
    comment_id = Column(UUID(as_uuid=True), ForeignKey("forum_comments.id", ondelete="CASCADE"), nullable=True, index=True)
    reason = Column(String(100), nullable=False)
    details = Column(Text, nullable=True)
    status = Column(String(50), nullable=False, default="pending")

    reporter = relationship("User")
    post = relationship("ForumPost", back_populates="reports")
    comment = relationship("ForumComment")

