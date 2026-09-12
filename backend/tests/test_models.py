import pytest
from sqlalchemy import create_engine
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import sessionmaker

from app.database.session import Base
from app.models import (
    Comment,
    Follow,
    ForumComment,
    ForumLike,
    ForumPost,
    Hashtag,
    Like,
    Notification,
    Profile,
    SavedVideo,
    User,
    Video,
    View,
)

# SQLite test database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def db():
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


def test_create_user_and_profile(db):
    user = User(email="test@vibereel.com", username="testuser", hashed_password="hashed_secret")
    db.add(user)
    db.commit()
    db.refresh(user)

    assert user.id is not None
    assert user.email == "test@vibereel.com"

    profile = Profile(
        user_id=user.id,
        full_name="Test Creator",
        bio="Creating awesome short videos",
        is_creator=True,
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)

    assert profile.user_id == user.id
    assert user.profile.full_name == "Test Creator"


def test_video_and_engagement_models(db):
    user = User(email="creator@vibereel.com", username="creator1", hashed_password="hashed_secret")
    db.add(user)
    db.commit()

    video = Video(
        user_id=user.id,
        title="First Vibe",
        video_url="https://cdn.vibereel.com/video1.mp4",
        duration_seconds=15.5,
    )
    db.add(video)
    db.commit()
    db.refresh(video)

    assert video.id is not None
    assert video.user_id == user.id

    # Add Like
    like = Like(user_id=user.id, video_id=video.id)
    db.add(like)
    db.commit()

    # Add Save
    save = SavedVideo(user_id=user.id, video_id=video.id)
    db.add(save)
    db.commit()

    # Add View
    view = View(user_id=user.id, video_id=video.id, watch_duration_seconds=12.0)
    db.add(view)
    db.commit()

    # Add Comment
    comment = Comment(user_id=user.id, video_id=video.id, content="Awesome video!")
    db.add(comment)
    db.commit()

    assert len(user.likes) == 1
    assert len(user.saved_videos) == 1
    assert len(user.views) == 1
    assert len(video.comments) == 1


def test_duplicate_like_constraint(db):
    u = User(email="u1@vibereel.com", username="u1", hashed_password="pwd")
    db.add(u)
    db.commit()

    v = Video(user_id=u.id, video_url="http://vid.mp4")
    db.add(v)
    db.commit()

    like1 = Like(user_id=u.id, video_id=v.id)
    db.add(like1)
    db.commit()

    like2 = Like(user_id=u.id, video_id=v.id)
    db.add(like2)
    with pytest.raises(IntegrityError):
        db.commit()
    db.rollback()


def test_duplicate_follow_constraint(db):
    u1 = User(email="user1@vibereel.com", username="user1", hashed_password="pwd")
    u2 = User(email="user2@vibereel.com", username="user2", hashed_password="pwd")
    db.add_all([u1, u2])
    db.commit()

    f1 = Follow(follower_id=u1.id, following_id=u2.id)
    db.add(f1)
    db.commit()

    f2 = Follow(follower_id=u1.id, following_id=u2.id)
    db.add(f2)
    with pytest.raises(IntegrityError):
        db.commit()
    db.rollback()


def test_duplicate_save_constraint(db):
    u = User(email="u_save@vibereel.com", username="usave", hashed_password="pwd")
    db.add(u)
    db.commit()

    v = Video(user_id=u.id, video_url="http://vid.mp4")
    db.add(v)
    db.commit()

    s1 = SavedVideo(user_id=u.id, video_id=v.id)
    db.add(s1)
    db.commit()

    s2 = SavedVideo(user_id=u.id, video_id=v.id)
    db.add(s2)
    with pytest.raises(IntegrityError):
        db.commit()
    db.rollback()


def test_forum_and_hashtag_models(db):
    author = User(email="forum_user@vibereel.com", username="forumuser", hashed_password="pwd")
    db.add(author)
    db.commit()

    post = ForumPost(
        author_id=author.id,
        title="Best Lighting Setup for Short Videos?",
        content="What Ring Lights do you recommend?",
        category="gear",
    )
    db.add(post)
    db.commit()
    db.refresh(post)

    assert post.id is not None

    comment = ForumComment(post_id=post.id, author_id=author.id, content="I recommend Softbox lights!")
    db.add(comment)
    db.commit()

    like = ForumLike(user_id=author.id, post_id=post.id)
    db.add(like)
    db.commit()

    hashtag = Hashtag(name="lighting")
    db.add(hashtag)
    db.commit()

    notification = Notification(
        recipient_id=author.id,
        type="forum_reply",
        title="New Reply",
        message="Someone replied to your forum post",
    )
    db.add(notification)
    db.commit()

    assert len(post.comments) == 1
    assert len(post.likes) == 1
    assert len(author.notifications_received) == 1
