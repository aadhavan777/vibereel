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


def test_search_all():
    response = client.get("/api/v1/search?q=vibereel")
    assert response.status_code == 200
    data = response.json()
    assert "query" in data
    assert data["query"] == "vibereel"
    assert "videos" in data
    assert "creators" in data
    assert "hashtags" in data
    assert "forum_posts" in data


def test_search_trending():
    response = client.get("/api/v1/search/trending")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0
    assert "tag" in data[0]
    assert "category" in data[0]
