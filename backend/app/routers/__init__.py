from app.routers.auth import router as auth_router
from app.routers.feed import router as feed_router
from app.routers.forum import router as forum_router
from app.routers.health import router as health_router
from app.routers.moderation import router as moderation_router
from app.routers.notifications import router as notifications_router
from app.routers.search import router as search_router
from app.routers.users import router as users_router
from app.routers.videos import router as videos_router

__all__ = [
    "auth_router",
    "feed_router",
    "forum_router",
    "health_router",
    "moderation_router",
    "notifications_router",
    "search_router",
    "users_router",
    "videos_router",
]


