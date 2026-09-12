from pydantic import BaseModel

from app.schemas.forum import ForumPostResponse
from app.schemas.user import UserResponse
from app.schemas.video import VideoResponse


class HashtagResult(BaseModel):
    tag: str
    posts_count: int
    trending: bool


class TrendingSearchResult(BaseModel):
    tag: str
    category: str
    views: str


class SearchResponse(BaseModel):
    query: str
    videos: list[VideoResponse] = []
    creators: list[UserResponse] = []
    hashtags: list[HashtagResult] = []
    forum_posts: list[ForumPostResponse] = []
