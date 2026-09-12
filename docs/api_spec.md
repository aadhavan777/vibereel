# VibeReel REST API Documentation

> Complete OpenAPI / RESTful API Specification for the VibeReel Backend Service (`/api/v1`).

---

## 🔑 Base URL & Authentication

- **Development Base URL**: `http://localhost:8000/api/v1`
- **Android Emulator Base URL**: `http://10.0.2.2:8000/api/v1`
- **Authentication**: Bearer Token (`Authorization: Bearer <access_token>`)

---

## 📋 Endpoints Overview

| Category | Endpoint | Method | Auth Required | Description |
|---|---|---|---|---|
| **Health** | `/health` | `GET` | No | System health check |
| **Auth** | `/auth/register` | `POST` | No | Register new creator account |
| **Auth** | `/auth/login` | `POST` | No | Authenticate & get JWT tokens |
| **Auth** | `/auth/refresh` | `POST` | No | Refresh expired access token |
| **Users** | `/users/me` | `GET` | Yes | Get current user profile |
| **Users** | `/users/me` | `PUT` | Yes | Update profile info |
| **Users** | `/users/me/password` | `PUT` | Yes | Change password |
| **Users** | `/users/me/drafts` | `GET` | Yes | Get current user draft videos |
| **Users** | `/users/{id}` | `GET` | No | Get public creator profile |
| **Users** | `/users/{id}/videos` | `GET` | No | Get creator's published videos |
| **Users** | `/users/{id}/follow` | `POST` | Yes | Follow a creator |
| **Users** | `/users/{id}/follow` | `DELETE` | Yes | Unfollow a creator |
| **Videos** | `/feed` | `GET` | Optional | Get personalized short-video feed |
| **Videos** | `/videos` | `POST` | Yes | Create video metadata record |
| **Videos** | `/videos/upload-file` | `POST` | Yes | Upload video file & thumbnail (Multipart) |
| **Videos** | `/videos/{id}` | `GET` | Optional | Get video details |
| **Videos** | `/videos/{id}` | `PUT` | Yes | Update draft / video caption |
| **Videos** | `/videos/{id}` | `DELETE` | Yes | Delete owned video |
| **Videos** | `/videos/{id}/like` | `POST` | Yes | Like a video |
| **Videos** | `/videos/{id}/like` | `DELETE` | Yes | Unlike a video |
| **Videos** | `/videos/{id}/save` | `POST` | Yes | Bookmark / Save a video |
| **Videos** | `/videos/{id}/save` | `DELETE` | Yes | Unsave a video |
| **Videos** | `/videos/{id}/comments` | `GET` | Optional | Get video comments |
| **Videos** | `/videos/{id}/comments` | `POST` | Yes | Add comment on video |
| **Forum** | `/forum/posts` | `GET` | Optional | List forum posts (Category & Sort) |
| **Forum** | `/forum/posts` | `POST` | Yes | Create creator discussion post |
| **Forum** | `/forum/posts/{id}` | `GET` | Optional | Get forum post details & increment view |
| **Forum** | `/forum/posts/{id}` | `PUT` | Yes | Edit owned forum post |
| **Forum** | `/forum/posts/{id}` | `DELETE` | Yes | Delete owned forum post |
| **Forum** | `/forum/posts/{id}/like` | `POST` | Yes | Upvote forum post |
| **Forum** | `/forum/posts/{id}/like` | `DELETE` | Yes | Remove upvote |
| **Forum** | `/forum/posts/{id}/comments` | `GET` | Optional | Get post comments & replies |
| **Forum** | `/forum/posts/{id}/comments` | `POST` | Yes | Comment / reply on post |
| **Notifications** | `/notifications` | `GET` | Yes | Get notifications list (unread filter) |
| **Notifications** | `/notifications/unread-count` | `GET` | Yes | Get unread notifications badge count |
| **Notifications** | `/notifications/{id}/read` | `PUT` | Yes | Mark notification as read |
| **Notifications** | `/notifications/read-all` | `PUT` | Yes | Mark all notifications as read |
| **Search** | `/search` | `GET` | Optional | Multi-domain search (Videos, Users, Forum) |
| **Search** | `/search/trending` | `GET` | No | Get trending search queries & topics |
| **Moderation** | `/moderation/reports` | `POST` | Yes | Submit content report |
| **Moderation** | `/moderation/blocks/{id}` | `POST` | Yes | Block user |
| **Moderation** | `/moderation/blocks/{id}` | `DELETE` | Yes | Unblock user |
| **Moderation** | `/moderation/blocks` | `GET` | Yes | Get list of blocked user IDs |
