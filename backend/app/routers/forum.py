from typing import cast
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.dependencies.auth import get_current_active_user, get_optional_current_user
from app.models.user import User
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
from app.services.forum_service import forum_service

router = APIRouter(prefix="/forum", tags=["Creator Forum"])


@router.get("/posts", response_model=ForumPostListResponse)
def list_forum_posts(
    category: str | None = None,
    search: str | None = None,
    sort_by: str = Query("latest", pattern="^(latest|trending)$"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: User | None = Depends(get_optional_current_user),
    db: Session = Depends(get_db),
):
    current_user_id = cast(UUID, current_user.id) if current_user else None
    return forum_service.get_posts(
        db,
        category=category,
        search=search,
        sort_by=sort_by,
        page=page,
        limit=limit,
        current_user_id=current_user_id,
    )


@router.post("/posts", response_model=ForumPostResponse, status_code=status.HTTP_201_CREATED)
def create_forum_post(
    post_in: ForumPostCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    return forum_service.create_post(db, current_user, post_in)


@router.get("/posts/{post_id}", response_model=ForumPostResponse)
def get_forum_post_details(
    post_id: UUID,
    current_user: User | None = Depends(get_optional_current_user),
    db: Session = Depends(get_db),
):
    current_user_id = cast(UUID, current_user.id) if current_user else None
    return forum_service.get_post_details(db, post_id, current_user_id)


@router.put("/posts/{post_id}", response_model=ForumPostResponse)
def update_forum_post(
    post_id: UUID,
    post_in: ForumPostUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    return forum_service.update_post(db, post_id, current_user, post_in)


@router.delete("/posts/{post_id}")
def delete_forum_post(
    post_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    return forum_service.delete_post(db, post_id, current_user)


@router.post("/posts/{post_id}/like")
def like_forum_post(
    post_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    return forum_service.like_post(db, post_id, current_user)


@router.delete("/posts/{post_id}/like")
def unlike_forum_post(
    post_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    return forum_service.unlike_post(db, post_id, current_user)


@router.get("/posts/{post_id}/comments", response_model=list[ForumCommentResponse])
def get_forum_post_comments(
    post_id: UUID,
    current_user: User | None = Depends(get_optional_current_user),
    db: Session = Depends(get_db),
):
    current_user_id = cast(UUID, current_user.id) if current_user else None
    return forum_service.get_comments(db, post_id, current_user_id)



@router.post("/posts/{post_id}/comments", response_model=ForumCommentResponse, status_code=status.HTTP_201_CREATED)
def create_forum_post_comment(
    post_id: UUID,
    comment_in: ForumCommentCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    return forum_service.create_comment(db, post_id, current_user, comment_in)


@router.post("/reports", response_model=ForumReportResponse, status_code=status.HTTP_201_CREATED)
def report_forum_content(
    report_in: ForumReportCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    return forum_service.create_report(db, current_user, report_in)

