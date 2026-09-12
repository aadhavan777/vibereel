from sqlalchemy import Boolean, Column, ForeignKey, Index, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class Notification(BaseModel):
    __tablename__ = "notifications"
    __table_args__ = (
        Index("ix_notifications_recipient_read", "recipient_id", "is_read"),
        Index("ix_notifications_recipient_created", "recipient_id", "created_at"),
    )

    recipient_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    actor_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True)
    type = Column(String(50), nullable=False)
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    entity_type = Column(String(50), nullable=True)
    entity_id = Column(UUID(as_uuid=True), nullable=True)
    is_read = Column(Boolean, default=False, nullable=False)

    recipient = relationship("User", foreign_keys=[recipient_id], back_populates="notifications_received")
    actor = relationship("User", foreign_keys=[actor_id], back_populates="notifications_acted")

