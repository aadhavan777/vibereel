from typing import Any, cast
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.dependencies.auth import get_current_active_user, get_optional_current_user
from app.models.user import User
from app.models.video import Comment, Like, SavedVideo, Video
from app.schemas.video import CommentCreate, CommentResponse, FeedResponse, VideoCreate, VideoResponse
from app.services.moderation_service import moderation_service
from app.services.notification_service import notification_service
from app.services.storage_service import BaseStorageService, get_storage_service

router = APIRouter(prefix="/videos", tags=["Videos"])


def _build_video_response(video: Video, db: Session, current_user_id: UUID | None = None) -> VideoResponse:
    creator = db.scalar(select(User).where(User.id == video.user_id))
    creator_username = str(creator.username) if creator else "vibemaster"
    creator_avatar_url = (
        str(creator.profile.avatar_url) if (creator and creator.profile and creator.profile.avatar_url) else None
    )

    is_liked = False
    is_saved = False

    if current_user_id:
        like_exists = db.scalar(select(Like).where(Like.user_id == current_user_id, Like.video_id == video.id))
        is_liked = like_exists is not None

        save_exists = db.scalar(
            select(SavedVideo).where(SavedVideo.user_id == current_user_id, SavedVideo.video_id == video.id)
        )
        is_saved = save_exists is not None

    return VideoResponse(
        id=cast(UUID, video.id),
        creator_id=cast(UUID, video.user_id),
        creator_username=creator_username,
        creator_avatar_url=creator_avatar_url,
        caption=cast(str | None, video.caption),
        video_url=cast(str, video.video_url),
        thumbnail_url=cast(str | None, video.thumbnail_url),
        duration_seconds=cast(float | None, video.duration_seconds),
        is_draft=cast(bool, video.is_draft),
        is_private=cast(bool, video.is_private),
        likes_count=cast(Any, video.likes_count),
        comments_count=cast(Any, video.comments_count),
        saves_count=cast(Any, video.saves_count),
        shares_count=0,
        is_liked=is_liked,
        is_saved=is_saved,
        audio_title=f"Original Audio - @{creator_username}",
        audio_artist=creator_username,
        hashtags=["flutter", "vibereel", "shortvideo"],
        created_at=cast(Any, video.created_at),
    )


@router.post("", response_model=VideoResponse, status_code=status.HTTP_201_CREATED)
@router.post("/upload", response_model=VideoResponse, status_code=status.HTTP_201_CREATED)
def create_video(
    video_in: VideoCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    video = Video(
        user_id=current_user.id,
        caption=video_in.caption,
        video_url=video_in.video_url,
        thumbnail_url=video_in.thumbnail_url,
        duration_seconds=video_in.duration_seconds,
        is_draft=video_in.is_draft,
        is_private=video_in.is_private,
    )
    db.add(video)
    db.commit()
    db.refresh(video)
    user_id = cast(UUID, current_user.id)
    return _build_video_response(video, db, user_id)


@router.post("/upload-file", response_model=VideoResponse, status_code=status.HTTP_201_CREATED)
async def upload_video_file(
    file: UploadFile = File(...),
    thumbnail_file: UploadFile | None = File(None),
    caption: str | None = Form(None),
    is_draft: bool = Form(False),
    is_private: bool = Form(False),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
    storage_service: BaseStorageService = Depends(get_storage_service),
):
    video_bytes = await file.read()
    video_filename = file.filename or "video.mp4"
    video_content_type = file.content_type or "video/mp4"

    uploaded_video_url = storage_service.upload_video(video_bytes, video_filename, video_content_type)

    uploaded_thumbnail_url = None
    if thumbnail_file and thumbnail_file.filename:
        thumb_bytes = await thumbnail_file.read()
        if thumb_bytes:
            thumb_filename = thumbnail_file.filename
            thumb_content_type = thumbnail_file.content_type or "image/jpeg"
            uploaded_thumbnail_url = storage_service.upload_thumbnail(thumb_bytes, thumb_filename, thumb_content_type)

    try:
        video = Video(
            user_id=current_user.id,
            caption=caption,
            video_url=uploaded_video_url,
            thumbnail_url=uploaded_thumbnail_url,
            is_draft=is_draft,
            is_private=is_private,
        )
        db.add(video)
        db.commit()
        db.refresh(video)
    except Exception as exc:
        db.rollback()
        storage_service.delete_video(uploaded_video_url)
        if uploaded_thumbnail_url:
            storage_service.delete_thumbnail(uploaded_thumbnail_url)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create video record in database: {str(exc)}",
        ) from exc

    user_id = cast(UUID, current_user.id)
    return _build_video_response(video, db, user_id)



@router.put("/{video_id}", response_model=VideoResponse)
def update_video(
    video_id: UUID,
    video_in: VideoCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    video = db.scalar(select(Video).where(Video.id == video_id, Video.user_id == current_user.id))
    if not video:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Video not found or unauthorized")

    video.caption = video_in.caption  # type: ignore
    video.thumbnail_url = video_in.thumbnail_url  # type: ignore
    video.is_draft = video_in.is_draft  # type: ignore
    video.is_private = video_in.is_private  # type: ignore

    db.commit()
    db.refresh(video)
    user_id = cast(UUID, current_user.id)
    return _build_video_response(video, db, user_id)


@router.delete("/{video_id}")
def delete_video(
    video_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    video = db.scalar(select(Video).where(Video.id == video_id, Video.user_id == current_user.id))
    if not video:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Video not found or unauthorized")

    db.delete(video)
    db.commit()
    return {"status": "deleted"}


@router.get("", response_model=FeedResponse)
def get_video_feed(
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
):
    offset = (page - 1) * limit
    current_user_id: UUID | None = cast(UUID, current_user.id) if current_user else None
    blocked_user_ids = moderation_service.get_blocked_user_ids(db, current_user_id)

    stmt = select(Video).where(Video.is_draft == False)  # noqa: E712
    if blocked_user_ids:
        stmt = stmt.where(Video.user_id.notin_(blocked_user_ids))

    stmt = stmt.order_by(Video.created_at.desc()).offset(offset).limit(limit)
    videos = db.scalars(stmt).all()


    if not videos and page == 1:
        seed_user = db.scalar(select(User).where(User.username == "vibemaster"))
        if not seed_user:
            seed_user = User(
                username="vibemaster",
                email="vibemaster@vibereel.com",
                hashed_password="hashed_seed_pass",
            )
            db.add(seed_user)
            db.commit()
            db.refresh(seed_user)

        sample_videos = [
            Video(
                user_id=seed_user.id,
                caption="Building VibeReel with Flutter & FastAPI! 🚀 #flutter #vibereel #coding",
                video_url="https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-flowers-1173-large.mp4",
                thumbnail_url="https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600",
                likes_count=14200,
                comments_count=382,
                saves_count=1890,
            ),
            Video(
                user_id=seed_user.id,
                caption="Cinematic night vibes in Tokyo 🗼✨ #cinematic #tokyo #nightlife",
                video_url="https://assets.mixkit.co/videos/preview/mixkit-vertical-view-of-a-neon-sign-at-night-42898-large.mp4",
                thumbnail_url="https://images.unsplash.com/photo-1503899036084-c55cdd92da26?w=600",
                likes_count=28900,
                comments_count=941,
                saves_count=5200,
            ),
            Video(
                user_id=seed_user.id,
                caption="3 Flutter tips you NEED to know for smooth 60fps animations! 🔥 #flutterdev #mobile",
                video_url="https://assets.mixkit.co/videos/preview/mixkit-hands-typing-on-a-laptop-keyboard-4171-large.mp4",
                thumbnail_url="https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600",
                likes_count=9430,
                comments_count=178,
                saves_count=3100,
            ),
        ]
        db.add_all(sample_videos)
        db.commit()
        videos = sample_videos

    items = [_build_video_response(v, db, current_user_id) for v in videos]


    return FeedResponse(
        items=items,
        total=len(items),
        page=page,
        limit=limit,
    )


@router.get("/{video_id}", response_model=VideoResponse)
def get_video_details(
    video_id: UUID,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    video = db.scalar(select(Video).where(Video.id == video_id))
    if not video:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Video not found")

    current_user_id: UUID | None = cast(UUID, current_user.id) if current_user else None
    return _build_video_response(video, db, current_user_id)


@router.post("/{video_id}/like")
def like_video(
    video_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    video = db.scalar(select(Video).where(Video.id == video_id))
    if not video:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Video not found")

    existing_like = db.scalar(select(Like).where(Like.user_id == current_user.id, Like.video_id == video_id))
    if not existing_like:
        like = Like(user_id=current_user.id, video_id=video_id)
        db.add(like)
        video.likes_count = cast(Any, video.likes_count) + 1  # type: ignore
        db.commit()

        notification_service.create_notification(
            db=db,
            recipient_id=cast(UUID, video.user_id),
            actor_id=cast(UUID, current_user.id),
            type="like",
            title="New Like",
            message=f"@{current_user.username} liked your video",
            entity_type="video",
            entity_id=video_id,
        )

    return {"status": "liked", "likes_count": cast(Any, video.likes_count)}


@router.delete("/{video_id}/like")
def unlike_video(
    video_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    video = db.scalar(select(Video).where(Video.id == video_id))
    if not video:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Video not found")

    existing_like = db.scalar(select(Like).where(Like.user_id == current_user.id, Like.video_id == video_id))
    if existing_like:
        db.delete(existing_like)
        video.likes_count = max(0, cast(Any, video.likes_count) - 1)  # type: ignore
        db.commit()

    return {"status": "unliked", "likes_count": cast(Any, video.likes_count)}


@router.post("/{video_id}/save")
def save_video(
    video_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    video = db.scalar(select(Video).where(Video.id == video_id))
    if not video:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Video not found")

    existing_save = db.scalar(
        select(SavedVideo).where(SavedVideo.user_id == current_user.id, SavedVideo.video_id == video_id)
    )
    if not existing_save:
        save = SavedVideo(user_id=current_user.id, video_id=video_id)
        db.add(save)
        video.saves_count = cast(Any, video.saves_count) + 1  # type: ignore
        db.commit()

    return {"status": "saved", "saves_count": cast(Any, video.saves_count)}


@router.delete("/{video_id}/save")
def unsave_video(
    video_id: UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    video = db.scalar(select(Video).where(Video.id == video_id))
    if not video:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Video not found")

    existing_save = db.scalar(
        select(SavedVideo).where(SavedVideo.user_id == current_user.id, SavedVideo.video_id == video_id)
    )
    if existing_save:
        db.delete(existing_save)
        video.saves_count = max(0, cast(Any, video.saves_count) - 1)  # type: ignore
        db.commit()

    return {"status": "unsaved", "saves_count": cast(Any, video.saves_count)}


@router.get("/{video_id}/comments", response_model=list[CommentResponse])
def get_video_comments(
    video_id: UUID,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_optional_current_user),
):
    video = db.scalar(select(Video).where(Video.id == video_id))
    if not video:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Video not found")

    current_user_id: UUID | None = cast(UUID, current_user.id) if current_user else None
    blocked_user_ids = moderation_service.get_blocked_user_ids(db, current_user_id)

    stmt_c = select(Comment).where(Comment.video_id == video_id)
    if blocked_user_ids:
        stmt_c = stmt_c.where(Comment.user_id.notin_(blocked_user_ids))

    comments = db.scalars(stmt_c.order_by(Comment.created_at.desc())).all()


    response = []
    for c in comments:
        user = db.scalar(select(User).where(User.id == c.user_id))
        username = str(user.username) if user else "anonymous"
        avatar_url = str(user.profile.avatar_url) if (user and user.profile and user.profile.avatar_url) else None
        response.append(
            CommentResponse(
                id=cast(UUID, c.id),
                video_id=cast(UUID, c.video_id),
                user_id=cast(UUID, c.user_id),
                username=username,
                avatar_url=avatar_url,
                content=cast(str, c.content),
                parent_comment_id=cast(UUID | None, c.parent_comment_id),
                likes_count=0,
                is_liked=False,
                created_at=cast(Any, c.created_at),
            )
        )

    return response


@router.post("/{video_id}/comments", response_model=CommentResponse)
def add_video_comment(
    video_id: UUID,
    data: CommentCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    video = db.scalar(select(Video).where(Video.id == video_id))
    if not video:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Video not found")

    comment = Comment(
        user_id=current_user.id,
        video_id=video_id,
        content=data.content,
        parent_comment_id=data.parent_comment_id,
    )
    db.add(comment)
    video.comments_count = cast(Any, video.comments_count) + 1  # type: ignore
    db.commit()
    db.refresh(comment)

    notification_service.create_notification(
        db=db,
        recipient_id=cast(UUID, video.user_id),
        actor_id=cast(UUID, current_user.id),
        type="comment",
        title="New Comment",
        message=f"@{current_user.username} commented: {data.content[:30]}",
        entity_type="video",
        entity_id=video_id,
    )

    avatar_url = (
        str(current_user.profile.avatar_url) if (current_user.profile and current_user.profile.avatar_url) else None
    )

    return CommentResponse(
        id=cast(UUID, comment.id),
        video_id=cast(UUID, comment.video_id),
        user_id=cast(UUID, comment.user_id),
        username=str(current_user.username),
        avatar_url=avatar_url,
        content=cast(str, comment.content),
        parent_comment_id=cast(UUID | None, comment.parent_comment_id),
        likes_count=0,
        is_liked=False,
        created_at=cast(Any, comment.created_at),
    )

