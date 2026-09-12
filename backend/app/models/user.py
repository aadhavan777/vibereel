from sqlalchemy import Boolean, Column, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class User(BaseModel):
    __tablename__ = "users"

    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(50), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    # 1-to-1 relationship with Profile
    profile = relationship("Profile", back_populates="user", uselist=False, cascade="all, delete-orphan")

    # Content & Social Relationships
    videos = relationship("Video", back_populates="user", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="user", cascade="all, delete-orphan")
    likes = relationship("Like", back_populates="user", cascade="all, delete-orphan")
    saved_videos = relationship("SavedVideo", back_populates="user", cascade="all, delete-orphan")
    views = relationship("View", back_populates="user")

    follows_given = relationship(
        "Follow", foreign_keys="Follow.follower_id", back_populates="follower", cascade="all, delete-orphan"
    )
    follows_received = relationship(
        "Follow", foreign_keys="Follow.following_id", back_populates="following", cascade="all, delete-orphan"
    )

    notifications_received = relationship(
        "Notification",
        foreign_keys="Notification.recipient_id",
        back_populates="recipient",
        cascade="all, delete-orphan",
    )
    notifications_acted = relationship("Notification", foreign_keys="Notification.actor_id", back_populates="actor")

    blocks_given = relationship(
        "UserBlock", foreign_keys="UserBlock.blocker_id", back_populates="blocker", cascade="all, delete-orphan"
    )
    blocks_received = relationship(
        "UserBlock", foreign_keys="UserBlock.blocked_id", back_populates="blocked", cascade="all, delete-orphan"
    )

    forum_posts = relationship("ForumPost", back_populates="author", cascade="all, delete-orphan")
    forum_comments = relationship("ForumComment", back_populates="author", cascade="all, delete-orphan")
    forum_likes = relationship("ForumLike", back_populates="user", cascade="all, delete-orphan")



class Profile(BaseModel):
    __tablename__ = "profiles"

    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
    )
    full_name = Column(String(100), nullable=True)
    bio = Column(Text, nullable=True)
    avatar_url = Column(String(512), nullable=True)
    banner_url = Column(String(512), nullable=True)
    website = Column(String(255), nullable=True)
    is_creator = Column(Boolean, default=False, nullable=False)

    user = relationship("User", back_populates="profile")
