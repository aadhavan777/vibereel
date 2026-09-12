import io
from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.services.storage_service import (
    ALLOWED_THUMBNAIL_EXTENSIONS,
    ALLOWED_VIDEO_EXTENSIONS,
    LocalStorageService,
    S3StorageService,
    generate_unique_key,
    validate_thumbnail_file,
    validate_video_file,
)


def test_validate_video_file():
    for ext in ALLOWED_VIDEO_EXTENSIONS:
        assert validate_video_file(f"test{ext}", 1024) == ext

    with pytest.raises(HTTPException) as exc_info:
        validate_video_file("test.exe", 1024)
    assert exc_info.value.status_code == 400

    with pytest.raises(HTTPException) as exc_info:
        validate_video_file("test.mp4", 101 * 1024 * 1024)
    assert exc_info.value.status_code == 400


def test_validate_thumbnail_file():
    for ext in ALLOWED_THUMBNAIL_EXTENSIONS:
        assert validate_thumbnail_file(f"thumb{ext}", 1024) == ext

    with pytest.raises(HTTPException) as exc_info:
        validate_thumbnail_file("thumb.pdf", 1024)
    assert exc_info.value.status_code == 400

    with pytest.raises(HTTPException) as exc_info:
        validate_thumbnail_file("thumb.png", 11 * 1024 * 1024)
    assert exc_info.value.status_code == 400


def test_generate_unique_key():
    key1 = generate_unique_key("videos", "my_video.mp4")
    key2 = generate_unique_key("videos", "my_video.mp4")
    assert key1.startswith("videos/")
    assert key1.endswith(".mp4")
    assert key1 != key2


def test_local_storage_service(tmp_path):
    storage = LocalStorageService(media_dir=str(tmp_path), base_url="http://localhost/media")
    video_bytes = b"fake video bytes content"
    url = storage.upload_video(video_bytes, "test_video.mp4", "video/mp4")
    assert "http://localhost/media/videos/" in url

    thumb_bytes = b"fake image bytes content"
    thumb_url = storage.upload_thumbnail(thumb_bytes, "test_thumb.jpg", "image/jpeg")
    assert "http://localhost/media/thumbnails/" in thumb_url

    assert storage.delete_video(url) is True
    assert storage.delete_thumbnail(thumb_url) is True


@patch("boto3.client")
def test_s3_storage_service(mock_boto_client):
    mock_s3 = MagicMock()
    mock_boto_client.return_value = mock_s3

    s3_storage = S3StorageService(
        bucket_name="vibereel-test-bucket",
        aws_access_key_id="test_key",
        aws_secret_access_key="test_secret",
    )

    url = s3_storage.upload_video(b"video bytes", "sample.mp4", "video/mp4")
    assert "https://vibereel-test-bucket.s3.amazonaws.com/videos/" in url
    mock_s3.put_object.assert_called_once()

    thumb_url = s3_storage.upload_thumbnail(b"thumb bytes", "sample.jpg", "image/jpeg")
    assert "https://vibereel-test-bucket.s3.amazonaws.com/thumbnails/" in thumb_url

    deleted = s3_storage.delete_video(url)
    assert deleted is True
    mock_s3.delete_object.assert_called_once()


def test_upload_file_endpoint_success():
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

    # Register user & login
    client.post(
        "/api/v1/auth/register",
        json={
            "username": "storagetester",
            "email": "storagetester@example.com",
            "password": "Password123!",
            "display_name": "Storage Tester",
        },
    )
    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": "storagetester", "password": "Password123!"},
    )
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    video_file = ("video.mp4", io.BytesIO(b"dummy video data"), "video/mp4")
    thumb_file = ("thumb.jpg", io.BytesIO(b"dummy thumb data"), "image/jpeg")

    response = client.post(
        "/api/v1/videos/upload-file",
        files={"file": video_file, "thumbnail_file": thumb_file},
        data={"caption": "Test upload video!", "is_draft": "false"},
        headers=headers,
    )

    assert response.status_code == 201
    data = response.json()
    assert data["caption"] == "Test upload video!"
    assert "videos/" in data["video_url"]
    assert "thumbnails/" in data["thumbnail_url"]


def test_upload_file_endpoint_invalid_extension():
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

    client.post(
        "/api/v1/auth/register",
        json={
            "username": "storagetester2",
            "email": "storagetester2@example.com",
            "password": "Password123!",
            "display_name": "Storage Tester 2",
        },
    )
    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": "storagetester2", "password": "Password123!"},
    )
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    invalid_file = ("script.sh", io.BytesIO(b"echo 'malicious'"), "text/plain")

    response = client.post(
        "/api/v1/videos/upload-file",
        files={"file": invalid_file},
        data={"caption": "Invalid extension test"},
        headers=headers,
    )

    assert response.status_code == 400
    assert "Invalid video file extension" in response.json()["detail"]

