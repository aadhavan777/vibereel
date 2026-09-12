import pytest
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
client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


def _get_auth_headers(username: str, email: str) -> tuple[dict[str, str], str]:
    res = client.post(
        "/api/v1/auth/register",
        json={
            "username": username,
            "email": email,
            "password": "Password123!",
            "display_name": username.title(),
        },
    )
    user_id = res.json()["id"]
    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": username, "password": "Password123!"},
    )
    token = login_res.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}, user_id


def test_submit_report_flow():
    headers, _ = _get_auth_headers("reporter1", "reporter1@vibereel.com")

    # Create a video first to get a valid entity_id
    video_res = client.post(
        "/api/v1/videos",
        json={"video_url": "https://example.com/test.mp4", "caption": "Test report video"},
        headers=headers,
    )
    video_id = video_res.json()["id"]

    payload = {
        "entity_type": "video",
        "entity_id": video_id,
        "reason": "Spam or Scam",
        "details": "Promoting suspicious link",
    }
    resp = client.post("/api/v1/moderation/reports", json=payload, headers=headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["reason"] == "Spam or Scam"
    assert data["entity_type"] == "video"
    assert data["status"] == "pending"



def test_user_block_and_unblock_flow():
    headers1, user1_id = _get_auth_headers("blocker_user", "blocker@vibereel.com")
    headers2, user2_id = _get_auth_headers("blocked_user", "blocked@vibereel.com")

    # 1. Block user2
    block_resp = client.post(f"/api/v1/moderation/blocks/{user2_id}", headers=headers1)
    assert block_resp.status_code == 200
    assert block_resp.json()["status"] == "blocked"

    # 2. Get blocked users list
    list_resp = client.get("/api/v1/moderation/blocks", headers=headers1)
    assert list_resp.status_code == 200
    assert user2_id in list_resp.json()["blocked_user_ids"]

    # 3. Unblock user2
    unblock_resp = client.delete(f"/api/v1/moderation/blocks/{user2_id}", headers=headers1)
    assert unblock_resp.status_code == 200
    assert unblock_resp.json()["status"] == "unblocked"

    # 4. Verify unblocked
    list_resp2 = client.get("/api/v1/moderation/blocks", headers=headers1)
    assert user2_id not in list_resp2.json()["blocked_user_ids"]
