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


def test_weak_password_rejected():
    # Password without digit should be rejected
    res = client.post(
        "/api/v1/auth/register",
        json={
            "username": "secuser1",
            "email": "sec1@example.com",
            "password": "nodigitspassword",
            "display_name": "Sec User",
        },
    )
    assert res.status_code == 422


def test_invalid_token_unauthorized():
    res = client.get(
        "/api/v1/users/me",
        headers={"Authorization": "Bearer invalid_malformed_token_123"},
    )
    assert res.status_code == 401
    assert "Could not validate credentials" in res.json()["detail"]


def test_invalid_file_extension_upload_rejected():
    # Register and login user
    client.post(
        "/api/v1/auth/register",
        json={
            "username": "uploader",
            "email": "uploader@example.com",
            "password": "Password123!",
        },
    )
    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": "uploader", "password": "Password123!"},
    )
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Upload file with forbidden executable extension .exe
    files = {"file": ("malicious.exe", b"binary content", "video/mp4")}
    upload_res = client.post("/api/v1/videos/upload-file", files=files, headers=headers)
    assert upload_res.status_code == 400
    assert "Invalid video file extension" in upload_res.json()["detail"]
