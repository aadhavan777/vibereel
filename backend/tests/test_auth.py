import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database.session import Base, get_db
from app.main import app

# In-memory SQLite database setup for tests with StaticPool
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
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


def test_register_user_success():
    payload = {
        "username": "vibecoder",
        "email": "coder@vibereel.com",
        "password": "SecurePassword123!",
        "display_name": "Vibe Coder",
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["username"] == "vibecoder"
    assert data["email"] == "coder@vibereel.com"
    assert data["display_name"] == "Vibe Coder"
    assert "hashed_password" not in data
    assert "password" not in data


def test_register_duplicate_username_and_email():
    payload = {
        "username": "uniqueuser",
        "email": "unique@vibereel.com",
        "password": "Password123!",
        "display_name": "Unique User",
    }
    res1 = client.post("/api/v1/auth/register", json=payload)
    assert res1.status_code == 201

    # Duplicate Username
    res2 = client.post(
        "/api/v1/auth/register",
        json={
            "username": "uniqueuser",
            "email": "other@vibereel.com",
            "password": "Password123!",
        },
    )
    assert res2.status_code == 409
    assert "Username already taken" in res2.json()["detail"]

    # Duplicate Email
    res3 = client.post(
        "/api/v1/auth/register",
        json={
            "username": "otheruser",
            "email": "unique@vibereel.com",
            "password": "Password123!",
        },
    )
    assert res3.status_code == 409
    assert "Email address already registered" in res3.json()["detail"]


def test_login_and_token_generation():
    # Register user
    reg_payload = {
        "username": "logintester",
        "email": "login@vibereel.com",
        "password": "MySecretPassword1!",
        "display_name": "Login Tester",
    }
    client.post("/api/v1/auth/register", json=reg_payload)

    # Success Login
    login_payload = {
        "username": "logintester",
        "password": "MySecretPassword1!",
    }
    res = client.post("/api/v1/auth/login", json=login_payload)
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"

    # Failed Login with wrong password
    bad_login = {
        "username": "logintester",
        "password": "WrongPassword!",
    }
    res_bad = client.post("/api/v1/auth/login", json=bad_login)
    assert res_bad.status_code == 401
    assert "Incorrect username or password" in res_bad.json()["detail"]


def test_get_me_authenticated():
    # Register & Login
    client.post(
        "/api/v1/auth/register",
        json={
            "username": "metester",
            "email": "me@vibereel.com",
            "password": "Password123!",
            "display_name": "Me Tester",
        },
    )
    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": "metester", "password": "Password123!"},
    )
    access_token = login_res.json()["access_token"]

    # Request /auth/me
    headers = {"Authorization": f"Bearer {access_token}"}
    me_res = client.get("/api/v1/auth/me", headers=headers)
    assert me_res.status_code == 200
    data = me_res.json()
    assert data["username"] == "metester"
    assert data["email"] == "me@vibereel.com"
    assert data["display_name"] == "Me Tester"
    assert "hashed_password" not in data


def test_refresh_token_and_logout():
    client.post(
        "/api/v1/auth/register",
        json={
            "username": "refreshtester",
            "email": "refresh@vibereel.com",
            "password": "Password123!",
        },
    )
    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": "refreshtester", "password": "Password123!"},
    )
    access_token = login_res.json()["access_token"]
    refresh_token = login_res.json()["refresh_token"]

    # Refresh tokens
    ref_res = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert ref_res.status_code == 200
    new_data = ref_res.json()
    assert "access_token" in new_data
    assert "refresh_token" in new_data
    new_refresh_token = new_data["refresh_token"]

    # Old refresh token should be revoked (rotation)
    old_ref_res = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert old_ref_res.status_code == 401

    # Logout
    headers = {"Authorization": f"Bearer {access_token}"}
    logout_res = client.post("/api/v1/auth/logout", json={"refresh_token": new_refresh_token}, headers=headers)
    assert logout_res.status_code == 200

    # Refresh after logout should fail
    after_logout_ref = client.post("/api/v1/auth/refresh", json={"refresh_token": new_refresh_token})
    assert after_logout_ref.status_code == 401


def test_update_profile_and_change_password():
    client.post(
        "/api/v1/auth/register",
        json={
            "username": "profileuser",
            "email": "profile@vibereel.com",
            "password": "OldPassword123!",
            "display_name": "Old Name",
        },
    )
    login_res = client.post(
        "/api/v1/auth/login",
        json={"username": "profileuser", "password": "OldPassword123!"},
    )
    access_token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {access_token}"}

    # Update Profile (PUT /users/me)
    update_res = client.put(
        "/api/v1/users/me",
        json={
            "display_name": "New Display Name",
            "bio": "Updated Bio",
            "is_creator": True,
        },
        headers=headers,
    )
    assert update_res.status_code == 200
    up_data = update_res.json()
    assert up_data["display_name"] == "New Display Name"
    assert up_data["bio"] == "Updated Bio"
    assert up_data["is_creator"] is True

    # Change Password with wrong current password -> 400
    bad_pwd_res = client.put(
        "/api/v1/users/me/password",
        json={"current_password": "WrongPassword!", "new_password": "NewSecretPassword1!"},
        headers=headers,
    )
    assert bad_pwd_res.status_code == 400

    # Change Password with correct current password
    pwd_res = client.put(
        "/api/v1/users/me/password",
        json={"current_password": "OldPassword123!", "new_password": "NewSecretPassword1!"},
        headers=headers,
    )
    assert pwd_res.status_code == 200

    # Login with new password
    new_login_res = client.post(
        "/api/v1/auth/login",
        json={"username": "profileuser", "password": "NewSecretPassword1!"},
    )
    assert new_login_res.status_code == 200
