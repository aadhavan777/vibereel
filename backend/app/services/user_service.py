from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import get_password_hash, verify_password
from app.models.user import Profile, User
from app.repositories.user_repository import user_repository
from app.schemas.auth import PasswordChangeRequest
from app.schemas.user import UserProfilePublic, UserResponse, UserUpdate


class UserService:
    def get_profile_by_id(self, db: Session, user_id: UUID) -> UserProfilePublic:
        user = user_repository.get(db, user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found.",
            )
        display_name = str(user.profile.full_name) if user.profile and user.profile.full_name else None
        bio = str(user.profile.bio) if user.profile and user.profile.bio else None
        avatar_url = str(user.profile.avatar_url) if user.profile and user.profile.avatar_url else None
        banner_url = str(user.profile.banner_url) if user.profile and user.profile.banner_url else None
        is_creator = bool(user.profile.is_creator) if user.profile else False

        return UserProfilePublic(
            id=UUID(str(user.id)),
            username=str(user.username),
            display_name=display_name,
            bio=bio,
            avatar_url=avatar_url,
            banner_url=banner_url,
            is_creator=is_creator,
            followers_count=len(user.follows_received) if user.follows_received else 0,
            following_count=len(user.follows_given) if user.follows_given else 0,
            videos_count=len(user.videos) if user.videos else 0,
        )

    def update_profile(self, db: Session, user: User, update_data: UserUpdate) -> UserResponse:
        if not user.profile:
            user.profile = Profile(user_id=user.id)
            db.add(user.profile)

        if update_data.display_name is not None:
            user.profile.full_name = update_data.display_name  # type: ignore[assignment]
        if update_data.bio is not None:
            user.profile.bio = update_data.bio  # type: ignore[assignment]
        if update_data.avatar_url is not None:
            user.profile.avatar_url = update_data.avatar_url  # type: ignore[assignment]
        if update_data.banner_url is not None:
            user.profile.banner_url = update_data.banner_url  # type: ignore[assignment]
        if update_data.website is not None:
            user.profile.website = update_data.website  # type: ignore[assignment]
        if update_data.is_creator is not None:
            user.profile.is_creator = update_data.is_creator  # type: ignore[assignment]

        db.commit()
        db.refresh(user)

        display_name = str(user.profile.full_name) if user.profile and user.profile.full_name else None
        bio = str(user.profile.bio) if user.profile and user.profile.bio else None
        avatar_url = str(user.profile.avatar_url) if user.profile and user.profile.avatar_url else None
        banner_url = str(user.profile.banner_url) if user.profile and user.profile.banner_url else None
        website = str(user.profile.website) if user.profile and user.profile.website else None
        is_creator = bool(user.profile.is_creator) if user.profile else False

        return UserResponse(
            id=UUID(str(user.id)),
            email=str(user.email),
            username=str(user.username),
            display_name=display_name,
            bio=bio,
            avatar_url=avatar_url,
            banner_url=banner_url,
            website=website,
            is_creator=is_creator,
            is_active=bool(user.is_active),
            created_at=user.created_at,  # type: ignore[arg-type]
        )

    def change_password(self, db: Session, user: User, req: PasswordChangeRequest) -> None:
        if not verify_password(req.current_password, str(user.hashed_password)):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password is incorrect.",
            )

        user.hashed_password = get_password_hash(req.new_password)  # type: ignore[assignment]
        db.commit()


user_service = UserService()
