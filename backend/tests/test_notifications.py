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


def test_notifications_flow():
    headers1, user1_id = _get_auth_headers("notifuser1", "notif1@example.com")
    headers2, user2_id = _get_auth_headers("notifuser2", "notif2@example.com")

    # 1. Check initial empty notifications for user1
    resp = client.get("/api/v1/notifications", headers=headers1)
    assert resp.status_code == 200
    data = resp.json()
    assert data["unread_count"] == 0
    assert len(data["items"]) == 0

    # 2. User2 follows User1 -> Triggers notification
    follow_resp = client.post(f"/api/v1/users/{user1_id}/follow", headers=headers2)
    assert follow_resp.status_code == 200

    # 3. User1 checks unread count & notifications list
    count_resp = client.get("/api/v1/notifications/unread-count", headers=headers1)
    assert count_resp.status_code == 200
    assert count_resp.json()["unread_count"] == 1

    resp = client.get("/api/v1/notifications", headers=headers1)
    assert resp.status_code == 200
    items = resp.json()["items"]
    assert len(items) == 1
    notif_id = items[0]["id"]
    assert items[0]["type"] == "follow"
    assert items[0]["is_read"] is False

    # 4. Mark notification as read
    read_resp = client.put(f"/api/v1/notifications/{notif_id}/read", headers=headers1)
    assert read_resp.status_code == 200
    assert read_resp.json()["status"] == "success"

    # 5. Check unread count is 0
    count_resp = client.get("/api/v1/notifications/unread-count", headers=headers1)
    assert count_resp.json()["unread_count"] == 0

    # 6. Mark all read endpoint test
    read_all_resp = client.put("/api/v1/notifications/read-all", headers=headers1)
    assert read_all_resp.status_code == 200
    assert "marked_read_count" in read_all_resp.json()
