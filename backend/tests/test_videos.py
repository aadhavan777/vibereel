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


def test_video_feed_endpoint():
    # Register user & get token
    reg_res = client.post(
        "/api/v1/auth/register",
        json={
            "username": "videotester",
            "email": "videotester@example.com",
            "password": "Password123!",
            "display_name": "Video Tester",
        },
    )
    assert reg_res.status_code == 201

    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": "videotester", "password": "Password123!"},
    )
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Fetch feed
    feed_res = client.get("/api/v1/videos", headers=headers)
    assert feed_res.status_code == 200
    feed_data = feed_res.json()
    assert "items" in feed_data
    assert len(feed_data["items"]) >= 1

    first_video = feed_data["items"][0]
    video_id = first_video["id"]

    # Like video
    like_res = client.post(f"/api/v1/videos/{video_id}/like", headers=headers)
    assert like_res.status_code == 200
    assert like_res.json()["status"] == "liked"

    # Save video
    save_res = client.post(f"/api/v1/videos/{video_id}/save", headers=headers)
    assert save_res.status_code == 200
    assert save_res.json()["status"] == "saved"

    # Add comment
    comment_res = client.post(
        f"/api/v1/videos/{video_id}/comments",
        headers=headers,
        json={"content": "Awesome video content!"},
    )
    assert comment_res.status_code == 200
    assert comment_res.json()["content"] == "Awesome video content!"

    # Get comments
    get_comments_res = client.get(f"/api/v1/videos/{video_id}/comments", headers=headers)
    assert get_comments_res.status_code == 200
    assert len(get_comments_res.json()) >= 1
