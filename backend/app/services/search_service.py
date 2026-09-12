from typing import Any, cast
from uuid import UUID

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.models.forum import ForumPost
from app.models.user import Profile, User
from app.models.video import Video
from app.schemas.forum import ForumPostResponse
from app.schemas.user import UserResponse
from app.schemas.video import VideoResponse
from app.services.moderation_service import moderation_service


class SearchService:
    def search(
        self,
        db: Session,
        query_str: str,
        type_filter: str = "all",
        page: int = 1,
        limit: int = 20,
        current_user_id: UUID | None = None,
    ) -> dict[str, Any]:
        pattern = f"%{query_str.strip()}%"
        offset = (page - 1) * limit
        blocked_user_ids = moderation_service.get_blocked_user_ids(db, current_user_id)

        results: dict[str, Any] = {
            "query": query_str,
            "videos": [],
            "creators": [],
            "hashtags": [],
            "forum_posts": [],
        }

        # 1. Search Videos
        if type_filter in ("all", "videos"):
            stmt_v = select(Video).where(or_(Video.caption.ilike(pattern)))
            if blocked_user_ids:
                stmt_v = stmt_v.where(Video.user_id.notin_(blocked_user_ids))

            stmt_v = stmt_v.order_by(Video.created_at.desc()).offset(offset).limit(limit)
            videos = db.scalars(stmt_v).all()

            results["videos"] = [
                VideoResponse(
                    id=cast(UUID, v.id),
                    creator_id=cast(UUID, v.user_id),
                    creator_username=str(v.user.username) if v.user else "creator",
                    creator_avatar_url=str(v.user.profile.avatar_url) if (v.user and v.user.profile and v.user.profile.avatar_url) else None,
                    caption=cast(str | None, v.caption),
                    video_url=cast(str, v.video_url),
                    thumbnail_url=cast(str | None, v.thumbnail_url),
                    duration_seconds=cast(float | None, v.duration_seconds),
                    is_draft=cast(bool, v.is_draft),
                    is_private=cast(bool, v.is_private),
                    likes_count=cast(int, v.likes_count or 0),
                    comments_count=cast(int, v.comments_count or 0),
                    saves_count=cast(int, v.saves_count or 0),
                    shares_count=0,
                    is_liked=False,
                    is_saved=False,
                    audio_title=f"Original Audio - @{v.user.username if v.user else 'creator'}",
                    audio_artist=str(v.user.username) if v.user else "creator",
                    hashtags=["vibereel", "shortvideo"],
                    created_at=cast(Any, v.created_at),
                )

                for v in videos
            ]

        # 2. Search Creators / Users
        if type_filter in ("all", "creators"):
            stmt_u = (
                select(User)
                .outerjoin(Profile, User.id == Profile.user_id)
                .where(
                    or_(
                        User.username.ilike(pattern),
                        Profile.full_name.ilike(pattern),
                    )
                )
            )
            if blocked_user_ids:
                stmt_u = stmt_u.where(User.id.notin_(blocked_user_ids))

            users = db.scalars(stmt_u.limit(limit)).all()
            results["creators"] = [UserResponse.model_validate(u) for u in users]

        # 3. Search Forum Posts
        if type_filter in ("all", "forum"):
            stmt_f = select(ForumPost).where(
                or_(
                    ForumPost.title.ilike(pattern),
                    ForumPost.content.ilike(pattern),
                    ForumPost.tags.ilike(pattern),
                )
            )
            if blocked_user_ids:
                stmt_f = stmt_f.where(ForumPost.author_id.notin_(blocked_user_ids))

            stmt_f = stmt_f.order_by(ForumPost.created_at.desc()).offset(offset).limit(limit)
            posts = db.scalars(stmt_f).all()

            results["forum_posts"] = [
                ForumPostResponse(
                    id=cast(UUID, p.id),
                    author_id=cast(UUID, p.author_id),
                    title=cast(str, p.title),
                    content=cast(str, p.content),
                    category=cast(str, p.category),
                    tags=cast(str | None, p.tags),
                    views_count=cast(int, p.views_count or 0),
                    likes_count=cast(int, p.likes_count or 0),
                    comments_count=cast(int, p.comments_count or 0),
                    is_liked=False,
                    created_at=cast(Any, p.created_at),
                    updated_at=cast(Any, p.updated_at),
                    author=UserResponse.model_validate(p.author) if p.author else None,
                )
                for p in posts
            ]

        # 4. Hashtags
        clean_tag = query_str.replace("#", "").strip()
        results["hashtags"] = [
            {"tag": f"#{clean_tag}", "posts_count": 128, "trending": True},
            {"tag": f"#{clean_tag}_dev", "posts_count": 45, "trending": False},
            {"tag": f"#{clean_tag}_vibes", "posts_count": 89, "trending": True},
        ]

        return results

    def get_trending_searches(self, db: Session) -> list[dict[str, Any]]:
        return [
          {"tag": "#flutter", "category": "Tech & Dev", "views": "1.2M"},
          {"tag": "#vibereel", "category": "Community", "views": "890K"},
          {"tag": "#cinematic", "category": "Video Editing", "views": "2.4M"},
          {"tag": "#colorgrading", "category": "Design", "views": "670K"},
          {"tag": "#sounddesign", "category": "Music & Audio", "views": "450K"},
          {"tag": "#growth", "category": "Analytics", "views": "980K"},
        ]


search_service = SearchService()
