from uuid import UUID

from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models.forum import ForumComment, ForumCommentLike, ForumLike, ForumPost, ForumReport
from app.repositories.base import BaseRepository


class ForumRepository(BaseRepository[ForumPost]):
    def __init__(self):
        super().__init__(ForumPost)

    def get_posts(
        self,
        db: Session,
        category: str | None = None,
        search: str | None = None,
        sort_by: str = "latest",
        skip: int = 0,
        limit: int = 20,
        blocked_user_ids: list[UUID] | None = None,
    ) -> list[ForumPost]:
        query = db.query(ForumPost)

        if blocked_user_ids:
            query = query.filter(ForumPost.author_id.notin_(blocked_user_ids))

        if category and category.lower() != "all":
            query = query.filter(ForumPost.category == category.lower())

        if search and search.strip():
            pattern = f"%{search.strip()}%"
            query = query.filter(
                or_(
                    ForumPost.title.ilike(pattern),
                    ForumPost.content.ilike(pattern),
                    ForumPost.tags.ilike(pattern),
                )
            )

        if sort_by == "trending":
            query = query.order_by((ForumPost.likes_count + ForumPost.comments_count * 2 + ForumPost.views_count).desc())
        else:
            query = query.order_by(ForumPost.created_at.desc())

        return query.offset(skip).limit(limit).all()

    def get_post_by_id(self, db: Session, post_id: UUID) -> ForumPost | None:
        return db.query(ForumPost).filter(ForumPost.id == post_id).first()

    def is_post_liked_by_user(self, db: Session, user_id: UUID, post_id: UUID) -> bool:
        return db.query(ForumLike).filter(ForumLike.user_id == user_id, ForumLike.post_id == post_id).first() is not None

    def is_comment_liked_by_user(self, db: Session, user_id: UUID, comment_id: UUID) -> bool:
        return (
            db.query(ForumCommentLike)
            .filter(ForumCommentLike.user_id == user_id, ForumCommentLike.comment_id == comment_id)
            .first()
            is not None
        )

    def get_comments_for_post(
        self, db: Session, post_id: UUID, blocked_user_ids: list[UUID] | None = None
    ) -> list[ForumComment]:
        query = db.query(ForumComment).filter(ForumComment.post_id == post_id, ForumComment.parent_comment_id.is_(None))
        if blocked_user_ids:
            query = query.filter(ForumComment.author_id.notin_(blocked_user_ids))
        return query.order_by(ForumComment.created_at.asc()).all()


    def create_report(
        self,
        db: Session,
        reporter_id: UUID,
        reason: str,
        details: str | None = None,
        post_id: UUID | None = None,
        comment_id: UUID | None = None,
    ) -> ForumReport:
        report = ForumReport(
            reporter_id=reporter_id,
            post_id=post_id,
            comment_id=comment_id,
            reason=reason,
            details=details,
        )
        db.add(report)
        db.commit()
        db.refresh(report)
        return report


forum_repository = ForumRepository()

