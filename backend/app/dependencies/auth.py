from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.database.session import get_db
from app.models.user import User
from app.repositories.user_repository import user_repository

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception

    user_id_str = payload.get("sub")
    if not isinstance(user_id_str, str):
        raise credentials_exception

    try:
        user_id = UUID(user_id_str)
    except ValueError:
        raise credentials_exception from None

    user = user_repository.get(db, user_id)
    if user is None:
        raise credentials_exception
    return user


def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user profile.")
    return current_user


oauth2_scheme_optional = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=False)


def get_optional_current_user(
    token: str | None = Depends(oauth2_scheme_optional), db: Session = Depends(get_db)
) -> User | None:
    if not token:
        return None
    try:
        payload = decode_access_token(token)
        if payload is None:
            return None
        user_id_str = payload.get("sub")
        if not isinstance(user_id_str, str):
            return None
        user_id = UUID(user_id_str)
        return user_repository.get(db, user_id)
    except Exception:
        return None
