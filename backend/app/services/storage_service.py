import os
from abc import ABC, abstractmethod
from datetime import datetime
from pathlib import Path
from typing import Any
from uuid import uuid4

from fastapi import HTTPException, status

ALLOWED_VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv"}
ALLOWED_THUMBNAIL_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
MAX_VIDEO_SIZE_BYTES = 100 * 1024 * 1024  # 100 MB
MAX_THUMBNAIL_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB


def validate_video_file(filename: str, file_size: int) -> str:
    ext = Path(filename).suffix.lower()
    if ext not in ALLOWED_VIDEO_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid video file extension '{ext}'. Allowed extensions: {', '.join(ALLOWED_VIDEO_EXTENSIONS)}",
        )
    if file_size > MAX_VIDEO_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Video file exceeds maximum size limit of 100MB (file size: {file_size / (1024*1024):.2f}MB).",
        )
    return ext


def validate_thumbnail_file(filename: str, file_size: int) -> str:
    ext = Path(filename).suffix.lower()
    if ext not in ALLOWED_THUMBNAIL_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid thumbnail file extension '{ext}'. Allowed extensions: {', '.join(ALLOWED_THUMBNAIL_EXTENSIONS)}",
        )
    if file_size > MAX_THUMBNAIL_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Thumbnail file exceeds maximum size limit of 10MB (file size: {file_size / (1024*1024):.2f}MB).",
        )
    return ext


def generate_unique_key(prefix: str, original_filename: str) -> str:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    uuid_str = str(uuid4())[:8]
    ext = Path(original_filename).suffix.lower()
    safe_basename = Path(original_filename).stem[:20].replace(" ", "_")
    return f"{prefix}/{timestamp}_{uuid_str}_{safe_basename}{ext}"


class BaseStorageService(ABC):
    @abstractmethod
    def upload_video(self, file_bytes: bytes, filename: str, content_type: str = "video/mp4") -> str:
        pass

    @abstractmethod
    def upload_thumbnail(self, file_bytes: bytes, filename: str, content_type: str = "image/jpeg") -> str:
        pass

    @abstractmethod
    def delete_video(self, file_url_or_key: str) -> bool:
        pass

    @abstractmethod
    def delete_thumbnail(self, file_url_or_key: str) -> bool:
        pass


class LocalStorageService(BaseStorageService):
    def __init__(self, media_dir: str = "media", base_url: str = "http://localhost:8000/media") -> None:
        self.media_dir = Path(media_dir)
        self.base_url = base_url
        (self.media_dir / "videos").mkdir(parents=True, exist_ok=True)
        (self.media_dir / "thumbnails").mkdir(parents=True, exist_ok=True)

    def upload_video(self, file_bytes: bytes, filename: str, content_type: str = "video/mp4") -> str:
        validate_video_file(filename, len(file_bytes))
        key = generate_unique_key("videos", filename)
        target_path = self.media_dir / key
        target_path.parent.mkdir(parents=True, exist_ok=True)
        target_path.write_bytes(file_bytes)
        return f"{self.base_url}/{key}"

    def upload_thumbnail(self, file_bytes: bytes, filename: str, content_type: str = "image/jpeg") -> str:
        validate_thumbnail_file(filename, len(file_bytes))
        key = generate_unique_key("thumbnails", filename)
        target_path = self.media_dir / key
        target_path.parent.mkdir(parents=True, exist_ok=True)
        target_path.write_bytes(file_bytes)
        return f"{self.base_url}/{key}"

    def delete_video(self, file_url_or_key: str) -> bool:
        try:
            rel_path = file_url_or_key.replace(f"{self.base_url}/", "")
            target_path = self.media_dir / rel_path
            if target_path.exists():
                target_path.unlink()
                return True
        except Exception:
            pass
        return False

    def delete_thumbnail(self, file_url_or_key: str) -> bool:
        return self.delete_video(file_url_or_key)


class S3StorageService(BaseStorageService):
    def __init__(
        self,
        bucket_name: str,
        aws_access_key_id: str,
        aws_secret_access_key: str,
        region_name: str = "us-east-1",
        endpoint_url: str | None = None,
    ) -> None:
        import boto3  # type: ignore[import-untyped]

        self.bucket_name = bucket_name
        self.s3_client: Any = boto3.client(
            "s3",
            aws_access_key_id=aws_access_key_id,
            aws_secret_access_key=aws_secret_access_key,
            region_name=region_name,
            endpoint_url=endpoint_url,
        )

    def upload_video(self, file_bytes: bytes, filename: str, content_type: str = "video/mp4") -> str:
        validate_video_file(filename, len(file_bytes))
        key = generate_unique_key("videos", filename)
        self.s3_client.put_object(
            Bucket=self.bucket_name,
            Key=key,
            Body=file_bytes,
            ContentType=content_type,
        )
        return f"https://{self.bucket_name}.s3.amazonaws.com/{key}"

    def upload_thumbnail(self, file_bytes: bytes, filename: str, content_type: str = "image/jpeg") -> str:
        validate_thumbnail_file(filename, len(file_bytes))
        key = generate_unique_key("thumbnails", filename)
        self.s3_client.put_object(
            Bucket=self.bucket_name,
            Key=key,
            Body=file_bytes,
            ContentType=content_type,
        )
        return f"https://{self.bucket_name}.s3.amazonaws.com/{key}"

    def delete_video(self, file_url_or_key: str) -> bool:
        try:
            key = file_url_or_key.split("/")[-2] + "/" + file_url_or_key.split("/")[-1]
            self.s3_client.delete_object(Bucket=self.bucket_name, Key=key)
            return True
        except Exception:
            return False

    def delete_thumbnail(self, file_url_or_key: str) -> bool:
        return self.delete_video(file_url_or_key)


def get_storage_service() -> BaseStorageService:
    bucket_name = os.getenv("S3_BUCKET_NAME")
    aws_key = os.getenv("AWS_ACCESS_KEY_ID")
    aws_secret = os.getenv("AWS_SECRET_ACCESS_KEY")

    if bucket_name and aws_key and aws_secret:
        return S3StorageService(
            bucket_name=bucket_name,
            aws_access_key_id=aws_key,
            aws_secret_access_key=aws_secret,
            region_name=os.getenv("AWS_REGION", "us-east-1"),
            endpoint_url=os.getenv("S3_ENDPOINT_URL"),
        )
    return LocalStorageService()
