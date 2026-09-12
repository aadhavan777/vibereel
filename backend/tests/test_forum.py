from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database.session import Base, get_db
from app.main import app

engine = create_engine(
    "sqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db
Base.metadata.create_all(bind=engine)

client = TestClient(app)


def _get_auth_headers(username: str, email: str) -> tuple[dict[str, str], str]:
    client.post(
        "/api/v1/auth/register",
        json={
            "username": username,
            "email": email,
            "password": "Password123!",
            "display_name": username.title(),
        },
    )
    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": username, "password": "Password123!"},
    )
    token = login_res.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}, token


def test_forum_full_workflow():
    headers1, _ = _get_auth_headers("creator1", "creator1@example.com")
    headers2, _ = _get_auth_headers("creator2", "creator2@example.com")

    # 1. Create Post
    create_res = client.post(
        "/api/v1/forum/posts",
        json={
            "title": "Best 4K Color Grading Presets?",
            "content": "Looking for recommendations on Premiere Pro color grading LUTs!",
            "category": "video_editing",
            "tags": "colorgrading, premiere",
        },
        headers=headers1,
    )
    assert create_res.status_code == 201
    post_data = create_res.json()
    post_id = post_data["id"]
    assert post_data["title"] == "Best 4K Color Grading Presets?"
    assert post_data["category"] == "video_editing"

    # 2. List & Filter Posts
    list_res = client.get("/api/v1/forum/posts?category=video_editing")
    assert list_res.status_code == 200
    assert len(list_res.json()["items"]) >= 1

    search_res = client.get("/api/v1/forum/posts?search=Premiere")
    assert search_res.status_code == 200
    assert len(search_res.json()["items"]) >= 1

    # 3. Get Post Details (Increments views)
    details_res = client.get(f"/api/v1/forum/posts/{post_id}")
    assert details_res.status_code == 200
    assert details_res.json()["views_count"] == 1

    # 4. Like & Unlike Post
    like_res = client.post(f"/api/v1/forum/posts/{post_id}/like", headers=headers2)
    assert like_res.status_code == 200
    assert like_res.json()["likes_count"] == 1

    unlike_res = client.delete(f"/api/v1/forum/posts/{post_id}/like", headers=headers2)
    assert unlike_res.status_code == 200
    assert unlike_res.json()["likes_count"] == 0

    # 5. Add Comment & Reply
    comment_res = client.post(
        f"/api/v1/forum/posts/{post_id}/comments",
        json={"content": "I recommend Lumetri color presets!"},
        headers=headers2,
    )
    assert comment_res.status_code == 201
    comment_id = comment_res.json()["id"]

    reply_res = client.post(
        f"/api/v1/forum/posts/{post_id}/comments",
        json={"content": "Thanks! Will check it out.", "parent_comment_id": comment_id},
        headers=headers1,
    )
    assert reply_res.status_code == 201
    assert reply_res.json()["parent_comment_id"] == comment_id

    get_comments_res = client.get(f"/api/v1/forum/posts/{post_id}/comments")
    assert get_comments_res.status_code == 200
    comments_list = get_comments_res.json()
    assert len(comments_list) == 1
    assert len(comments_list[0]["replies"]) == 1

    # 6. Report Content
    report_res = client.post(
        "/api/v1/forum/reports",
        json={"post_id": post_id, "reason": "inappropriate", "details": "Test report flag"},
        headers=headers2,
    )
    assert report_res.status_code == 201
    assert report_res.json()["reason"] == "inappropriate"

    # 7. Update Post (Author authorized, non-author forbidden)
    forbidden_update = client.put(
        f"/api/v1/forum/posts/{post_id}",
        json={"title": "Hacked Title"},
        headers=headers2,
    )
    assert forbidden_update.status_code == 403

    valid_update = client.put(
        f"/api/v1/forum/posts/{post_id}",
        json={"title": "Updated Best 4K Color Grading Presets?"},
        headers=headers1,
    )
    assert valid_update.status_code == 200
    assert valid_update.json()["title"] == "Updated Best 4K Color Grading Presets?"

    # 8. Delete Post (Author authorized, non-author forbidden)
    forbidden_delete = client.delete(f"/api/v1/forum/posts/{post_id}", headers=headers2)
    assert forbidden_delete.status_code == 403

    valid_delete = client.delete(f"/api/v1/forum/posts/{post_id}", headers=headers1)
    assert valid_delete.status_code == 200
    assert valid_delete.json()["status"] == "deleted"
