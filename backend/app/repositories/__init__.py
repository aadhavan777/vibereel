from app.repositories.base import BaseRepository
from app.repositories.forum_repository import ForumRepository, forum_repository
from app.repositories.user_repository import UserRepository, user_repository
from app.repositories.video_repository import VideoRepository, video_repository

__all__ = [
    "BaseRepository",
    "ForumRepository",
    "UserRepository",
    "VideoRepository",
    "forum_repository",
    "user_repository",
    "video_repository",
]
