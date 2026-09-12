from sqlalchemy import Column, ForeignKey, Index, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class UserBlock(BaseModel):
    __tablename__ = "user_blocks"
    __table_args__ = (
        UniqueConstraint("blocker_id", "blocked_id", name="uq_blocker_blocked"),
        Index("ix_user_blocks_blocker_blocked", "blocker_id", "blocked_id"),
    )

    blocker_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    blocked_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    blocker = relationship("User", foreign_keys=[blocker_id], back_populates="blocks_given")
    blocked = relationship("User", foreign_keys=[blocked_id], back_populates="blocks_received")


class ContentReport(BaseModel):
    __tablename__ = "content_reports"
    __table_args__ = (
        Index("ix_content_reports_reporter_type", "reporter_id", "entity_type"),
    )

    reporter_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    entity_type = Column(String(50), nullable=False, index=True)  # video, forum_post, forum_comment, video_comment
    entity_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    reason = Column(String(100), nullable=False)
    details = Column(Text, nullable=True)
    status = Column(String(50), nullable=False, default="pending", index=True)  # pending, reviewed, dismissed

    reporter = relationship("User")
