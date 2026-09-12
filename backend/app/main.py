import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.database.session import engine
from app.models import BaseModel
from app.routers import (
    auth_router,
    feed_router,
    forum_router,
    health_router,
    moderation_router,
    notifications_router,
    search_router,
    users_router,
    videos_router,
)

BaseModel.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url="/api/v1/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
)

if not os.path.exists("media"):
    os.makedirs("media", exist_ok=True)
app.mount("/media", StaticFiles(directory="media"), name="media")

if settings.CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

api_v1_prefix = "/api/v1"
app.include_router(health_router, prefix=api_v1_prefix)
app.include_router(auth_router, prefix=api_v1_prefix)
app.include_router(users_router, prefix=api_v1_prefix)
app.include_router(videos_router, prefix=api_v1_prefix)
app.include_router(feed_router, prefix=api_v1_prefix)
app.include_router(forum_router, prefix=api_v1_prefix)
app.include_router(notifications_router, prefix=api_v1_prefix)
app.include_router(search_router, prefix=api_v1_prefix)
app.include_router(moderation_router, prefix=api_v1_prefix)




@app.get("/")
def root():
    return {
        "message": f"Welcome to {settings.PROJECT_NAME} Backend API",
        "docs": "/docs",
        "health": f"{api_v1_prefix}/health",
    }
