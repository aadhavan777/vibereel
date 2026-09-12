from typing import Any, cast
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.forum import ForumComment, ForumLike, ForumPost
from app.models.user import User
from app.repositories.forum_repository import forum_repository
from app.schemas.forum import (
    ForumCommentCreate,
    ForumCommentResponse,
    ForumPostCreate,
    ForumPostListResponse,
    ForumPostResponse,
    ForumPostUpdate,
    ForumReportCreate,
    ForumReportResponse,
)
from app.schemas.user import UserResponse
from app.services.moderation_service import moderation_service
from app.services.notification_service import notification_service


class ForumService:
    def _build_post_response(self, db: Session, post: ForumPost, current_user_id: UUID | None = None) -> ForumPostResponse:
        author = db.scalar(select(User).where(User.id == post.author_id))
        author_resp = UserResponse.model_validate(author) if author else None

        is_liked = False
        if current_user_id:
            is_liked = forum_repository.is_post_liked_by_user(db, current_user_id, cast(UUID, post.id))

        return ForumPostResponse(
            id=cast(UUID, post.id),
            author_id=cast(UUID, post.author_id),
            title=cast(str, post.title),
            content=cast(str, post.content),
            category=cast(str, post.category),
            tags=cast(str | None, post.tags),
            views_count=cast(int, post.views_count or 0),
            likes_count=cast(int, post.likes_count or 0),
            comments_count=cast(int, post.comments_count or 0),
            is_liked=is_liked,
            created_at=cast(Any, post.created_at),
            updated_at=cast(Any, post.updated_at),
            author=author_resp,
        )

    def _build_comment_response(
        self, db: Session, comment: ForumComment, current_user_id: UUID | None = None
    ) -> ForumCommentResponse:
        author = db.scalar(select(User).where(User.id == comment.author_id))
        author_resp = UserResponse.model_validate(author) if author else None

        is_liked = False
        if current_user_id:
            is_liked = forum_repository.is_comment_liked_by_user(db, current_user_id, cast(UUID, comment.id))

        replies = [self._build_comment_response(db, r, current_user_id) for r in (comment.replies or [])]

        return ForumCommentResponse(
            id=cast(UUID, comment.id),
            post_id=cast(UUID, comment.post_id),
            author_id=cast(UUID, comment.author_id),
            parent_comment_id=cast(UUID | None, comment.parent_comment_id),
            content=cast(str, comment.content),
            likes_count=cast(int, comment.likes_count or 0),
            is_liked=is_liked,
            created_at=cast(Any, comment.created_at),
            author=author_resp,
            replies=replies,
        )

    def get_posts(
        self,
        db: Session,
        category: str | None = None,
        search: str | None = None,
        sort_by: str = "latest",
        page: int = 1,
        limit: int = 20,
        current_user_id: UUID | None = None,
    ) -> ForumPostListResponse:
        skip = (page - 1) * limit
        blocked_ids = moderation_service.get_blocked_user_ids(db, current_user_id)
        posts = forum_repository.get_posts(
            db, category=category, search=search, sort_by=sort_by, skip=skip, limit=limit + 1, blocked_user_ids=blocked_ids
        )
        has_more = len(posts) > limit
        result_posts = posts[:limit]

        items = [self._build_post_response(db, p, current_user_id) for p in result_posts]
        next_cursor = str(result_posts[-1].id) if has_more and result_posts else None

        return ForumPostListResponse(
            items=items,
            total=len(items),
            page=page,
            limit=limit,
            next_cursor=next_cursor,
            has_more=has_more,
        )


    def create_post(self, db: Session, author: User, post_in: ForumPostCreate) -> ForumPostResponse:
        post = ForumPost(
            author_id=author.id,
            title=post_in.title,
            content=post_in.content,
            category=post_in.category.lower(),
            tags=post_in.tags,
        )
        db.add(post)
        db.commit()
        db.refresh(post)
        return self._build_post_response(db, post, cast(UUID, author.id))

    def get_post_details(self, db: Session, post_id: UUID, current_user_id: UUID | None = None) -> ForumPostResponse:
        post = forum_repository.get_post_by_id(db, post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Forum post not found")

        # Increment view count
        post.views_count = cast(Any, (post.views_count or 0) + 1)
        db.commit()

        return self._build_post_response(db, post, current_user_id)

    def update_post(
        self, db: Session, post_id: UUID, current_user: User, post_in: ForumPostUpdate
    ) -> ForumPostResponse:
        post = forum_repository.get_post_by_id(db, post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Forum post not found")

        if post.author_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to edit this post")

        if post_in.title is not None:
            post.title = cast(Any, post_in.title)
        if post_in.content is not None:
            post.content = cast(Any, post_in.content)
        if post_in.category is not None:
            post.category = cast(Any, post_in.category.lower())
        if post_in.tags is not None:
            post.tags = cast(Any, post_in.tags)

        db.commit()
        db.refresh(post)
        return self._build_post_response(db, post, cast(UUID, current_user.id))

    def delete_post(self, db: Session, post_id: UUID, current_user: User) -> dict[str, str]:
        post = forum_repository.get_post_by_id(db, post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Forum post not found")

        if post.author_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to delete this post")

        db.delete(post)
        db.commit()
        return {"status": "deleted"}

    def like_post(self, db: Session, post_id: UUID, current_user: User) -> dict[str, str | int]:
        post = forum_repository.get_post_by_id(db, post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Forum post not found")

        existing = db.query(ForumLike).filter(ForumLike.user_id == current_user.id, ForumLike.post_id == post_id).first()
        if not existing:
            like = ForumLike(user_id=current_user.id, post_id=post_id)
            db.add(like)
            post.likes_count = cast(Any, (post.likes_count or 0) + 1)
            db.commit()

            notification_service.create_notification(
                db=db,
                recipient_id=cast(UUID, post.author_id),
                actor_id=cast(UUID, current_user.id),
                type="like",
                title="Forum Post Liked",
                message=f"@{current_user.username} liked your post '{post.title[:25]}...'",
                entity_type="forum_post",
                entity_id=post_id,
            )

        likes_cnt: int = int(cast(Any, post.likes_count or 0))
        return {"status": "liked", "likes_count": likes_cnt}

    def unlike_post(self, db: Session, post_id: UUID, current_user: User) -> dict[str, str | int]:
        post = forum_repository.get_post_by_id(db, post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Forum post not found")

        existing = db.query(ForumLike).filter(ForumLike.user_id == current_user.id, ForumLike.post_id == post_id).first()
        if existing:
            db.delete(existing)
            post.likes_count = cast(Any, max(0, int(cast(Any, post.likes_count or 0)) - 1))
            db.commit()

        likes_cnt: int = int(cast(Any, post.likes_count or 0))
        return {"status": "unliked", "likes_count": likes_cnt}

    def get_comments(
        self, db: Session, post_id: UUID, current_user_id: UUID | None = None
    ) -> list[ForumCommentResponse]:
        post = forum_repository.get_post_by_id(db, post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Forum post not found")

        blocked_ids = moderation_service.get_blocked_user_ids(db, current_user_id)
        comments = forum_repository.get_comments_for_post(db, post_id, blocked_user_ids=blocked_ids)
        return [self._build_comment_response(db, c, current_user_id) for c in comments]


    def create_comment(
        self, db: Session, post_id: UUID, current_user: User, comment_in: ForumCommentCreate
    ) -> ForumCommentResponse:
        post = forum_repository.get_post_by_id(db, post_id)
        if not post:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Forum post not found")

        parent_author_id: UUID | None = None
        if comment_in.parent_comment_id:
            parent = db.query(ForumComment).filter(ForumComment.id == comment_in.parent_comment_id).first()
            if not parent:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parent comment not found")
            parent_author_id = cast(UUID, parent.author_id)

        comment = ForumComment(
            post_id=post_id,
            author_id=current_user.id,
            parent_comment_id=comment_in.parent_comment_id,
            content=comment_in.content,
        )
        db.add(comment)
        post.comments_count = cast(Any, (post.comments_count or 0) + 1)
        db.commit()
        db.refresh(comment)

        recipient_id = parent_author_id or cast(UUID, post.author_id)
        notif_type = "reply" if parent_author_id else "forum_reply"
        notif_title = "New Reply" if parent_author_id else "New Comment on Post"

        notification_service.create_notification(
            db=db,
            recipient_id=recipient_id,
            actor_id=cast(UUID, current_user.id),
            type=notif_type,
            title=notif_title,
            message=f"@{current_user.username}: {comment_in.content[:30]}",
            entity_type="forum_post",
            entity_id=post_id,
        )

        return self._build_comment_response(db, comment, cast(UUID, current_user.id))


    def create_report(self, db: Session, current_user: User, report_in: ForumReportCreate) -> ForumReportResponse:
        if not report_in.post_id and not report_in.comment_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Must specify either post_id or comment_id to report"
            )

        report = forum_repository.create_report(
            db,
            reporter_id=cast(UUID, current_user.id),
            reason=report_in.reason,
            details=report_in.details,
            post_id=report_in.post_id,
            comment_id=report_in.comment_id,
        )
        return ForumReportResponse.model_validate(report)



forum_service = ForumService()

