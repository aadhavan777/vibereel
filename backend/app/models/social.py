from sqlalchemy import Column, ForeignKey, Index, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class Follow(BaseModel):
    __tablename__ = "follows"
    __table_args__ = (
        UniqueConstraint("follower_id", "following_id", name="uq_follower_following"),
        Index("ix_follows_follower_following", "follower_id", "following_id"),
    )

    follower_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    following_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    follower = relationship("User", foreign_keys=[follower_id], back_populates="follows_given")
    following = relationship("User", foreign_keys=[following_id], back_populates="follows_received")
