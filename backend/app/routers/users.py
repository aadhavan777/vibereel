from typing import cast
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.dependencies.auth import get_current_active_user, get_optional_current_user
from app.dependencies.db import get_db
from app.models.social import Follow
from app.models.user import User
from app.models.video import Video
from app.routers.videos import _build_video_response
from app.schemas.auth import PasswordChangeRequest
from app.schemas.user import UserProfilePublic, UserResponse, UserUpdate
from app.schemas.video import VideoResponse
from app.services.auth_service import auth_service
from app.services.notification_service import notification_service
from app.services.user_service import user_service

router = APIRouter(prefix="/users", tags=["Users"])



@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user: User = Depends(get_current_active_user)):
    return auth_service.build_user_response(current_user)


@router.get("/me/drafts", response_model=list[VideoResponse])
def get_current_user_drafts(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    drafts = db.scalars(
        select(Video)
        .where(Video.user_id == current_user.id, Video.is_draft == True)  # noqa: E712
        .order_by(Video.created_at.desc())
    ).all()
    user_id = cast(UUID, current_user.id)
    return [_build_video_response(v, db, user_id) for v in drafts]


@router.put("/me", response_model=UserResponse)
def update_current_user_profile(
    update_data: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    return user_service.update_profile(db, current_user, update_data)


@router.put("/me/password")
def change_password(
    password_req: PasswordChangeRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    user_service.change_password(db, current_user, password_req)
    return {"message": "Password updated successfully"}


@router.get("/{user_id}", response_model=UserProfilePublic)
def get_public_user_profile(user_id: UUID, db: Session = Depends(get_db)):
    return user_service.get_profile_by_id(db, user_id)


@router.get("/{user_id}/videos", response_model=list[VideoResponse])
def get_user_videos(
    user_id: UUID,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    target_user = db.scalar(select(User).where(User.id == user_id))
    if not target_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    videos = db.scalars(
        select(Video)
        .where(Video.user_id == user_id, Video.is_draft == False)  # noqa: E712
        .order_by(Video.created_at.desc())
    ).all()

    c_user_id = cast(UUID, current_user.id) if current_user else None
    return [_build_video_response(v, db, c_user_id) for v in videos]


@router.post("/{user_id}/follow")
def follow_user(
    user_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    if user_id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot follow yourself")

    target_user = db.scalar(select(User).where(User.id == user_id))
    if not target_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    existing_follow = db.scalar(
        select(Follow).where(Follow.follower_id == current_user.id, Follow.following_id == user_id)
    )
    if not existing_follow:
        follow = Follow(follower_id=current_user.id, following_id=user_id)
        db.add(follow)
        db.commit()

        notification_service.create_notification(
            db=db,
            recipient_id=user_id,
            actor_id=cast(UUID, current_user.id),
            type="follow",
            title="New Follower",
            message=f"@{current_user.username} started following you",
            entity_type="user",
            entity_id=user_id,
        )

    return {"status": "following"}



@router.delete("/{user_id}/follow")
def unfollow_user(
    user_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    target_user = db.scalar(select(User).where(User.id == user_id))
    if not target_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    existing_follow = db.scalar(
        select(Follow).where(Follow.follower_id == current_user.id, Follow.following_id == user_id)
    )
    if existing_follow:
        db.delete(existing_follow)
        db.commit()

    return {"status": "unfollowed"}
