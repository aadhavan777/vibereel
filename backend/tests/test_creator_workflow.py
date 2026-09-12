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


def test_creator_workflow():
    # 1. Register creator
    reg_res = client.post(
        "/api/v1/auth/register",
        json={
            "username": "creator_pro",
            "email": "creator_pro@example.com",
            "password": "Password123!",
            "display_name": "Creator Pro",
        },
    )
    assert reg_res.status_code == 201

    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": "creator_pro", "password": "Password123!"},
    )
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Save video as draft
    draft_res = client.post(
        "/api/v1/videos",
        headers=headers,
        json={
            "caption": "My draft video idea #wip",
            "video_url": "https://assets.mixkit.co/videos/preview/mixkit-tree-1173-large.mp4",
            "thumbnail_url": "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe",
            "is_draft": True,
            "hashtags": ["wip"],
        },
    )
    assert draft_res.status_code == 201
    draft_data = draft_res.json()
    assert draft_data["is_draft"] is True
    draft_id = draft_data["id"]

    # 3. Get creator drafts
    drafts_list_res = client.get("/api/v1/users/me/drafts", headers=headers)
    assert drafts_list_res.status_code == 200
    assert len(drafts_list_res.json()) >= 1

    # 4. Publish draft
    pub_res = client.put(
        f"/api/v1/videos/{draft_id}",
        headers=headers,
        json={
            "caption": "Published video final caption! #vibereel",
            "video_url": "https://assets.mixkit.co/videos/preview/mixkit-tree-1173-large.mp4",
            "thumbnail_url": "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe",
            "is_draft": False,
            "hashtags": ["vibereel"],
        },
    )
    assert pub_res.status_code == 200
    assert pub_res.json()["is_draft"] is False

    # 5. Fetch creator published videos
    user_id = reg_res.json()["id"]
    videos_res = client.get(f"/api/v1/users/{user_id}/videos", headers=headers)
    assert videos_res.status_code == 200
    assert len(videos_res.json()) == 1
    assert videos_res.json()[0]["caption"] == "Published video final caption! #vibereel"

    # 6. Delete video
    del_res = client.delete(f"/api/v1/videos/{draft_id}", headers=headers)
    assert del_res.status_code == 200
    assert del_res.json()["status"] == "deleted"
