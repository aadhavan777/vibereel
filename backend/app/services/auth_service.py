from datetime import datetime, timedelta, timezone
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_refresh_token,
    get_password_hash,
    verify_password,
)
from app.models.auth import RefreshToken
from app.models.user import Profile, User
from app.repositories.user_repository import user_repository
from app.schemas.auth import TokenResponse, UserRegisterRequest
from app.schemas.user import UserResponse


class AuthService:
    def register_user(self, db: Session, req: UserRegisterRequest) -> User:
        if user_repository.get_by_email(db, req.email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email address already registered.",
            )
        if user_repository.get_by_username(db, req.username):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Username already taken.",
            )

        hashed_password = get_password_hash(req.password)
        new_user = User(
            email=req.email,
            username=req.username,
            hashed_password=hashed_password,
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        profile = Profile(
            user_id=new_user.id,
            full_name=req.display_name,
        )
        db.add(profile)
        db.commit()
        db.refresh(new_user)
        return new_user

    def authenticate_user(self, db: Session, username: str, password: str) -> User | None:
        user = user_repository.get_by_username(db, username)
        if not user:
            user = user_repository.get_by_email(db, username)
        if not user or not verify_password(password, str(user.hashed_password)):
            return None
        return user

    def create_tokens_for_user(self, db: Session, user: User) -> TokenResponse:
        access_token = create_access_token(subject=str(user.id))
        refresh_token = create_refresh_token(subject=str(user.id))

        expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        refresh_record = RefreshToken(
            user_id=user.id,
            token=refresh_token,
            expires_at=expires_at,
        )
        db.add(refresh_record)
        db.commit()

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
        )

    def refresh_access_token(self, db: Session, refresh_token_str: str) -> TokenResponse:
        payload = decode_refresh_token(refresh_token_str)
        if not payload or "sub" not in payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired refresh token",
            )

        user_id_str = str(payload["sub"])
        token_record = (
            db.query(RefreshToken)
            .filter(RefreshToken.token == refresh_token_str, RefreshToken.revoked == False)
            .first()
        )

        if not token_record:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token revoked or not found",
            )

        expires_at_val = token_record.expires_at
        if isinstance(expires_at_val, datetime) and expires_at_val.tzinfo is None:
            expires_at = expires_at_val.replace(tzinfo=timezone.utc)
        else:
            expires_at = expires_at_val  # type: ignore[assignment]

        if expires_at < datetime.now(timezone.utc):
            token_record.revoked = True  # type: ignore[assignment]
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token has expired",
            )

        token_record.revoked = True  # type: ignore[assignment]
        db.commit()

        user = user_repository.get(db, UUID(user_id_str))
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User inactive or not found",
            )

        return self.create_tokens_for_user(db, user)

    def logout_user(self, db: Session, refresh_token_str: str | None, current_user: User) -> None:
        if refresh_token_str:
            token_record = (
                db.query(RefreshToken)
                .filter(RefreshToken.token == refresh_token_str, RefreshToken.user_id == current_user.id)
                .first()
            )
            if token_record:
                token_record.revoked = True  # type: ignore[assignment]
                db.commit()
        else:
            db.query(RefreshToken).filter(
                RefreshToken.user_id == current_user.id, RefreshToken.revoked == False
            ).update({"revoked": True})
            db.commit()

    def build_user_response(self, user: User) -> UserResponse:
        display_name: str | None = None
        bio: str | None = None
        avatar_url: str | None = None
        banner_url: str | None = None
        website: str | None = None
        is_creator: bool = False

        if user.profile:
            display_name = str(user.profile.full_name) if user.profile.full_name else None
            bio = str(user.profile.bio) if user.profile.bio else None
            avatar_url = str(user.profile.avatar_url) if user.profile.avatar_url else None
            banner_url = str(user.profile.banner_url) if user.profile.banner_url else None
            website = str(user.profile.website) if user.profile.website else None
            is_creator = bool(user.profile.is_creator)

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


auth_service = AuthService()
