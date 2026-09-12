"""Initial schema migration for VibeReel foundation (13 tables)

Revision ID: 001_initial_schema
Revises:
Create Date: 2026-09-12 00:00:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "001_initial_schema"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # 1. Users Table
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("username", sa.String(50), nullable=False, unique=True),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_users_email", "users", ["email"])
    op.create_index("ix_users_username", "users", ["username"])

    # 2. Profiles Table
    op.create_table(
        "profiles",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column("full_name", sa.String(100), nullable=True),
        sa.Column("bio", sa.Text(), nullable=True),
        sa.Column("avatar_url", sa.String(512), nullable=True),
        sa.Column("banner_url", sa.String(512), nullable=True),
        sa.Column("website", sa.String(255), nullable=True),
        sa.Column("is_creator", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_profiles_user_id", "profiles", ["user_id"])

    # 3. Videos Table
    op.create_table(
        "videos",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("title", sa.String(255), nullable=True),
        sa.Column("caption", sa.Text(), nullable=True),
        sa.Column("video_url", sa.String(512), nullable=False),
        sa.Column("thumbnail_url", sa.String(512), nullable=True),
        sa.Column("duration_seconds", sa.Float(), nullable=True),
        sa.Column("views_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("likes_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("comments_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("saves_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_draft", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("is_private", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_videos_user_id", "videos", ["user_id"])

    # 4. Comments Table
    op.create_table(
        "comments",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column(
            "video_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("videos.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column(
            "parent_comment_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("comments.id", ondelete="CASCADE"),
            nullable=True,
        ),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_comments_user_id", "comments", ["user_id"])
    op.create_index("ix_comments_video_id", "comments", ["video_id"])
    op.create_index("ix_comments_parent_comment_id", "comments", ["parent_comment_id"])

    # 5. Likes Table
    op.create_table(
        "likes",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column(
            "video_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("videos.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("user_id", "video_id", name="uq_user_video_like"),
    )
    op.create_index("ix_likes_user_video", "likes", ["user_id", "video_id"])

    # 6. SavedVideos Table
    op.create_table(
        "saved_videos",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column(
            "video_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("videos.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("user_id", "video_id", name="uq_user_video_save"),
    )
    op.create_index("ix_saved_videos_user_video", "saved_videos", ["user_id", "video_id"])

    # 7. Views Table
    op.create_table(
        "views",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True
        ),
        sa.Column(
            "video_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("videos.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("watch_duration_seconds", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # 8. Follows Table
    op.create_table(
        "follows",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "follower_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column(
            "following_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("follower_id", "following_id", name="uq_follower_following"),
    )
    op.create_index("ix_follows_follower_following", "follows", ["follower_id", "following_id"])

    # 9. ForumPosts Table
    op.create_table(
        "forum_posts",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "author_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("category", sa.String(50), nullable=False, server_default="discussion"),
        sa.Column("views_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("likes_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("comments_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_forum_posts_category", "forum_posts", ["category"])

    # 10. ForumComments Table
    op.create_table(
        "forum_comments",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "post_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("forum_posts.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "author_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column(
            "parent_comment_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("forum_comments.id", ondelete="CASCADE"),
            nullable=True,
        ),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # 11. ForumLikes Table
    op.create_table(
        "forum_likes",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column(
            "post_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("forum_posts.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("user_id", "post_id", name="uq_user_forum_post_like"),
    )

    # 12. Hashtags Table & video_hashtags Junction
    op.create_table(
        "hashtags",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.String(100), nullable=False, unique=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_hashtags_name", "hashtags", ["name"])

    op.create_table(
        "video_hashtags",
        sa.Column(
            "video_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("videos.id", ondelete="CASCADE"), primary_key=True
        ),
        sa.Column(
            "hashtag_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("hashtags.id", ondelete="CASCADE"),
            primary_key=True,
        ),
    )

    # 13. Notifications Table
    op.create_table(
        "notifications",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "recipient_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column(
            "actor_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=True
        ),
        sa.Column("type", sa.String(50), nullable=False),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("entity_type", sa.String(50), nullable=True),
        sa.Column("entity_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("is_read", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_notifications_recipient_id", "notifications", ["recipient_id"])


def downgrade() -> None:
    op.drop_table("notifications")
    op.drop_table("video_hashtags")
    op.drop_table("hashtags")
    op.drop_table("forum_likes")
    op.drop_table("forum_comments")
    op.drop_table("forum_posts")
    op.drop_table("follows")
    op.drop_table("views")
    op.drop_table("saved_videos")
    op.drop_table("likes")
    op.drop_table("comments")
    op.drop_table("videos")
    op.drop_table("profiles")
    op.drop_table("users")
