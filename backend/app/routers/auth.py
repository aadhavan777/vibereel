from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.core.rate_limiter import rate_limiter_auth
from app.dependencies.auth import get_current_active_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.auth import (
    RefreshTokenRequest,
    TokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
)
from app.schemas.user import UserResponse
from app.services.auth_service import auth_service

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(
    req: UserRegisterRequest,
    request: Request,
    db: Session = Depends(get_db),
    _: None = Depends(rate_limiter_auth.check_rate_limit),
):
    user = auth_service.register_user(db, req)
    return auth_service.build_user_response(user)


@router.post("/login", response_model=TokenResponse)
def login(
    login_req: UserLoginRequest,
    request: Request,
    db: Session = Depends(get_db),
    _: None = Depends(rate_limiter_auth.check_rate_limit),
):
    user = auth_service.authenticate_user(db, login_req.username, login_req.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return auth_service.create_tokens_for_user(db, user)



@router.post("/refresh", response_model=TokenResponse)
def refresh_token(req: RefreshTokenRequest, db: Session = Depends(get_db)):
    return auth_service.refresh_access_token(db, req.refresh_token)


@router.post("/logout")
def logout(
    req: RefreshTokenRequest | None = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    refresh_str = req.refresh_token if req else None
    auth_service.logout_user(db, refresh_str, current_user)
    return {"message": "Successfully logged out"}


@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_active_user)):
    return auth_service.build_user_response(current_user)
