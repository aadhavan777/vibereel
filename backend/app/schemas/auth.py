from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator


class UserRegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=100)
    display_name: str | None = Field(None, max_length=100)

    @field_validator("password")
    @classmethod
    def validate_password_complexity(cls, v: str) -> str:
        if not any(char.isdigit() for char in v):
            raise ValueError("Password must contain at least one digit")
        return v


class UserLoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class PasswordChangeRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=8, max_length=100)

    @field_validator("new_password")
    @classmethod
    def validate_new_password_complexity(cls, v: str) -> str:
        if not any(char.isdigit() for char in v):
            raise ValueError("New password must contain at least one digit")
        return v


class TokenData(BaseModel):
    user_id: UUID | None = None

