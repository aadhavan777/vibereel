import json

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "VibeReel"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = "INFO"

    # Database
    DATABASE_URL: str = "postgresql://vibereel:vibereel@localhost:5432/vibereel_db"
    ASYNC_DATABASE_URL: str = "postgresql+asyncpg://vibereel:vibereel@localhost:5432/vibereel_db"

    # Security
    SECRET_KEY: str = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # CORS
    CORS_ORIGINS: str | list[str] = [
        "http://localhost:3000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ]

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: str | list[str]) -> list[str]:
        if isinstance(v, str):
            if v.startswith("[") and v.endswith("]"):
                parsed = json.loads(v)
                if isinstance(parsed, list):
                    return [str(i) for i in parsed]
            return [i.strip() for i in v.split(",") if i.strip()]
        elif isinstance(v, list):
            return [str(i) for i in v]
        raise ValueError(v)

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )


settings = Settings()
