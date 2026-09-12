# VibeReel 🎬⚡

> Production-Quality Full-Stack Short-Video Social Platform & Creator Forum for iOS & Android.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?logo=postgresql)](https://www.postgresql.org)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python)](https://www.python.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 1. 🚀 Project Overview

**VibeReel** is a modern full-stack short-video social platform designed for high performance, smooth user engagement, and community building. Built specifically to showcase production-grade architecture without third-party platform lock-in (zero Firebase dependency), VibeReel pairs a responsive cross-platform **Flutter** client for Android & iOS with an asynchronous **FastAPI** backend powered by **PostgreSQL** and **S3-compatible Object Storage**.

VibeReel empowers creators to record, edit, draft, upload, and publish vertical short videos, engage with their audience through social interactions (likes, comments, saves, follows), discover trending content, and participate in an integrated **Creator Forum** for peer feedback, technical discussion, and growth collaboration.

---

## 2. ✨ Key Features

### 📱 Mobile Experience (Flutter)
- 🎬 **Vertically Swipeable Reels Feed**: Full-screen vertical page scrolling, automatic video playback, pause/play toggles, and mute/unmute gestures.
- 💬 **Interactive Social Engagement**: Instant likes with optimistic UI feedback, threaded video comments modal, video bookmarks/saves, and creator follow actions.
- 🎨 **Creator Video Studio**: Video gallery selection, camera recording, preview, trimming, thumbnail selection, custom captioning, hashtag assignment, draft management, and multi-step publishing.
- 💬 **Creator Community Forum**: 8 specialized categories (Video Editing, Content Ideas, Growth, Tech, etc.), discussion creation, upvoting, threaded comment replies, and content reporting.
- 🔍 **Multi-Domain Discovery**: Universal search across videos, creators, hashtags, and forum posts with recent search memory and trending topic chips.
- 🔔 **Alerts & Activity Center**: Self-contained notifications center supporting 7 notification types with unread badge indicators and mark-as-read toggles.
- 🛡️ **Moderation & Safety**: Report content dialogs with category selection and one-tap user blocking to instantly hide unwanted content.

### ⚡ Backend System (FastAPI & PostgreSQL)
- 🔒 **Secure Authentication**: Password complexity validation, password hashing with bcrypt, JWT access/refresh token generation, and secure session validation.
- 📁 **Storage Abstraction Service**: Pluggable storage architecture supporting local file storage and AWS S3-compatible cloud storage with file type sanitization and size limit validation.
- 📊 **Optimized Queries**: Composite database indexes on SQLAlchemy models (`Video`, `Comment`, `ForumPost`, `UserBlock`, `Notification`) for low-latency queries.
- 🛡️ **Content Moderation Engine**: Complete user blocking engine and content reporting backend.
- 🚦 **Rate Limiting & Protection**: IP-based rate limiting on sensitive routes (`/auth/login`, `/auth/register`, `/moderation/reports`).

---

## 3. 🖼️ Screenshots

> *Note: Place screen recordings or PNG screenshots under `docs/screenshots/` to display interactive UI previews.*

| Reels Feed | Creator Forum | User Profile |
|:---:|:---:|:---:|
| `![Reels Feed](docs/screenshots/reels_feed.png)` | `![Creator Forum](docs/screenshots/forum.png)` | `![User Profile](docs/screenshots/profile.png)` |

| Multi-Domain Search | Notifications | Upload Studio |
|:---:|:---:|:---:|
| `![Search](docs/screenshots/search.png)` | `![Notifications](docs/screenshots/notifications.png)` | `![Upload Studio](docs/screenshots/upload.png)` |

---

## 4. 📐 Architecture Diagram

```text
+-----------------------------------------------------------------------+
|                         Mobile Client Layer                           |
|                      (Flutter - iOS & Android)                        |
|                                                                       |
|  +------------------+    +-------------------+    +----------------+  |
|  |  UI Views &      | -> | Riverpod State    | -> | Repository /   |  |
|  |  Widgets         |    | Management (MVVM) |    | ApiClient      |  |
|  +------------------+    +-------------------+    +----------------+  |
+-----------------------------------:-----------------------------------+
                                    | HTTPS / JSON
                                    v
+-----------------------------------------------------------------------+
|                         Backend API Layer                             |
|                        (FastAPI & Python 3)                           |
|                                                                       |
|  +------------------+    +-------------------+    +----------------+  |
|  |  Routers / API   | -> | Service Layer     | -> | Repositories & |  |
|  |  Endpoints        |    | (Business Logic)  |    | Data Models    |  |
|  +------------------+    +-------------------+    +----------------+  |
+-------------------:-----------------------------------:---------------+
                    | SQL (SQLAlchemy ORM)              | S3 API / Direct IO
                    v                                   v
+---------------------------------------+   +---------------------------+
|           Database Layer              |   |   Object Storage Layer    |
|            (PostgreSQL)               |   |   (S3 / Cloud Storage)    |
|                                       |   |                           |
| - Users, Profiles, Auth Tokens        |   | - Transcoded MP4 Videos   |
| - Video Metadata & Hashes             |   | - JPEG / PNG Thumbnails   |
| - Likes, Comments, Saves, Follows     |   | - Profile Avatars         |
| - Forum Posts, Comments & Moderation  |   +---------------------------+
| - Notifications & Audit Logs          |
+---------------------------------------+
```

```mermaid
graph TD
    subgraph MobileClient["Mobile Client (Flutter)"]
        UI["UI Layer / Views"]
        VM["MVVM ViewModels (Riverpod)"]
        Repo["Repository Layer"]
        Network["Dio / ApiClient"]
        
        UI --> VM
        VM --> Repo
        Repo --> Network
    end

    subgraph BackendAPI["Backend API Layer (FastAPI)"]
        Router["API Routers"]
        AuthDep["Auth & Dependency Injection"]
        Service["Service Layer (Business Logic)"]
        StorageService["Storage Service Abstraction"]
        
        Router --> AuthDep
        AuthDep --> Service
        Service --> StorageService
    end

    subgraph Persistence["Persistence & Storage"]
        Postgres[(PostgreSQL Database)]
        S3Bucket[("Object Storage (S3 / Local Media)")]
    end

    Network -->|HTTPS / JSON REST API| Router
    Service -->|SQL via SQLAlchemy ORM| Postgres
    StorageService -->|Multipart Upload / S3 SDK| S3Bucket
```

### Data Flow Summaries
- **Mobile → API → Database**: Used for user authentication, profile queries, social interactions (likes, comments, follows, saves), search queries, notification delivery, and creator forum posts.
- **Mobile → API → Video Storage**: Used for video uploads. The mobile client sends a multipart request to `/api/v1/videos/upload-file`. The backend validates the file type and size limit (<= 100MB), writes the file to S3 / Local Media storage, obtains the media URL, and saves the metadata record in PostgreSQL.

---

## 5. 🛠️ Technology Stack

| Layer | Technology | Description |
|---|---|---|
| **Mobile App** | Flutter 3.x / Dart 3.x | Cross-platform mobile app targeting Android & iOS |
| **Mobile State** | Riverpod (`flutter_riverpod`) | Reactive MVVM state management & dependency injection |
| **Mobile Navigation** | `go_router` | Declarative routing with URL parsing |
| **Mobile Networking** | `http` / `dio` | HTTP client with authentication interceptors |
| **Backend Framework** | FastAPI (Python 3.10+) | High-performance asynchronous REST API framework |
| **Database** | PostgreSQL | Enterprise relational database |
| **ORM** | SQLAlchemy v2.0 | Python SQL toolkit and Object Relational Mapper |
| **DB Migrations** | Alembic | Lightweight database migration tool for SQLAlchemy |
| **Authentication** | PyJWT + `passlib` (bcrypt) | JWT token creation, decoding, and password hashing |
| **Validation** | Pydantic v2 | Data validation and settings management |
| **Object Storage** | AWS S3 / Local Media | Scalable cloud video & thumbnail storage abstraction |

---

## 6. 📱 Flutter Setup

### Prerequisites
- Flutter SDK (v3.10.0 or higher)
- Android Studio / Xcode (for iOS builds)

### Execution Steps
```bash
# 1. Navigate to the mobile workspace
cd mobile

# 2. Install dependencies
flutter pub get

# 3. Run static analysis
flutter analyze

# 4. Run automated test suite
flutter test

# 5. Launch app on connected device / simulator
flutter run
```

---

## 7. ⚡ Backend Setup

### Prerequisites
- Python 3.10+
- `virtualenv`

### Execution Steps
```bash
# 1. Navigate to the backend directory
cd backend

# 2. Create and activate a Python virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install required Python packages
pip install -r requirements.txt

# 4. Copy environment configuration
cp .env.example .env

# 5. Start development server with live reload
uvicorn app.main:app --reload --port 8000
```
Interactive OpenAPI documentation will be accessible at `http://localhost:8000/docs`.

---

## 8. 🐘 PostgreSQL Setup

1. Install PostgreSQL 15+ locally or launch via Docker:
   ```bash
   docker run --name vibereel-postgres -e POSTGRES_USER=vibereel -e POSTGRES_PASSWORD=vibereel -e POSTGRES_DB=vibereel_db -p 5432:5432 -d postgres:15
   ```
2. Update your `DATABASE_URL` in `backend/.env`:
   ```ini
   DATABASE_URL=postgresql://vibereel:vibereel@localhost:5432/vibereel_db
   ```

---

## 9. 📦 Storage Configuration

VibeReel features a flexible storage service abstraction ([storage_service.py](backend/app/services/storage_service.py)):

- **Local Storage (Default)**: Automatically saves uploaded videos to `backend/media/videos/` and thumbnails to `backend/media/thumbnails/`.
- **AWS S3 / S3-Compatible Storage**: To enable S3 cloud storage, set the following environment variables in `backend/.env`:
  ```ini
  S3_BUCKET_NAME=vibereel-media-bucket
  AWS_ACCESS_KEY_ID=your_access_key
  AWS_SECRET_ACCESS_KEY=your_secret_key
  AWS_REGION=us-east-1
  ```

---

## 10. 🔄 Database Migration Instructions

Database schema migrations are managed via **Alembic**:

```bash
cd backend

# Run all pending migrations to bring DB up to date
venv/bin/alembic upgrade head

# Generate a new migration script after model changes
venv/bin/alembic revision --autogenerate -m "Add new feature table"
```

---

## 11. 📄 API Documentation

For the full endpoint reference, request/response schemas, and example JSON payloads, consult:
- **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)**
- Interactive Swagger UI: `http://localhost:8000/docs`

---

## 12. 🧪 Testing

### Backend Unit & Integration Tests
```bash
cd backend
venv/bin/pytest
```
- **Result**: `32 passed in 2.37s` (100% pass rate)

### Backend Code Formatting & Type Checks
```bash
cd backend
venv/bin/ruff check .
venv/bin/mypy app tests
```

### Mobile Static Analysis & Widget Tests
```bash
cd mobile
flutter analyze
flutter test
```
- **Result**: `No issues found!`, `15/15 widget and unit specs passed`

---

## 13. 🔒 Security Best Practices

- **Zero Firebase Dependency**: Custom FastAPI REST API backend eliminating third-party lock-in.
- **Strict Password Policy**: Minimum 8 characters with mandatory digit enforcement.
- **Secure Token Handling**: JWT access tokens signed with `HS256` and refresh token rotation.
- **File Upload Protection**: Content extension whitelisting (`.mp4`, `.mov`, `.jpg`, `.png`), size limits (100MB), and sanitized UUID file paths.
- **Rate Limiting**: Throttling on sensitive routes (`/auth/login`, `/auth/register`, `/moderation/reports`).
- **Authorization Enforcement**: Strict owner checks on resource modification/deletion (`HTTP 403 Forbidden`).

---

## 14. 🔮 Future Improvements

- 📹 **HLS Video Transcoding**: Implement async background video transcoding (FFmpeg) to HLS adaptive bitrate streams (.m3u8).
- 💬 **Real-time WebSockets**: Upgrade notifications and comments to live WebSocket channels.
- 🤖 **ML Recommendation Engine**: Personalized feed ordering based on watch time metrics and creator affinities.
- 🎙️ **Live Streaming**: Creator live streaming support using RTMP / WebRTC.

---

## 📝 License

Distributed under the MIT License. See `LICENSE` for details.
