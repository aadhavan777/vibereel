# VibeReel PostgreSQL Database Schema & Model Specification

## Entity Relationship Summary

```text
[ users ] 1 --- * [ videos ]
[ users ] 1 --- * [ video_likes ]
[ users ] 1 --- * [ video_comments ]
[ users ] 1 --- * [ video_saves ]
[ users ] 1 --- * [ follows ] (follower & following)
[ users ] 1 --- * [ forum_posts ]
[ users ] 1 --- * [ forum_comments ]
[ users ] 1 --- * [ collaborations ]
[ users ] 1 --- * [ notifications ]

[ videos ] 1 --- * [ video_likes ]
[ videos ] 1 --- * [ video_comments ]
[ videos ] 1 --- * [ video_saves ]

[ forum_posts ] 1 --- * [ forum_comments ]
```

---

## Database Tables

### 1. `users`
- `id` (UUID, Primary Key, Default: gen_random_uuid())
- `email` (VARCHAR(255), Unique, Indexed, NOT NULL)
- `username` (VARCHAR(50), Unique, Indexed, NOT NULL)
- `hashed_password` (VARCHAR(255), NOT NULL)
- `full_name` (VARCHAR(100))
- `bio` (TEXT)
- `avatar_url` (VARCHAR(512))
- `is_active` (BOOLEAN, Default: TRUE)
- `is_creator` (BOOLEAN, Default: FALSE)
- `created_at` (TIMESTAMPTZ, Default: now())
- `updated_at` (TIMESTAMPTZ, Default: now())

### 2. `videos`
- `id` (UUID, Primary Key)
- `creator_id` (UUID, FK -> users.id ON DELETE CASCADE, Indexed)
- `caption` (TEXT)
- `video_url` (VARCHAR(512), NOT NULL)
- `thumbnail_url` (VARCHAR(512))
- `duration_seconds` (DOUBLE PRECISION)
- `is_draft` (BOOLEAN, Default: FALSE)
- `is_private` (BOOLEAN, Default: FALSE)
- `likes_count` (INTEGER, Default: 0)
- `comments_count` (INTEGER, Default: 0)
- `saves_count` (INTEGER, Default: 0)
- `shares_count` (INTEGER, Default: 0)
- `created_at` (TIMESTAMPTZ, Default: now())
- `updated_at` (TIMESTAMPTZ, Default: now())

### 3. `video_likes`
- `id` (UUID, Primary Key)
- `user_id` (UUID, FK -> users.id ON DELETE CASCADE)
- `video_id` (UUID, FK -> videos.id ON DELETE CASCADE)
- `created_at` (TIMESTAMPTZ, Default: now())
- UNIQUE CONSTRAINT (`user_id`, `video_id`)

### 4. `video_comments`
- `id` (UUID, Primary Key)
- `user_id` (UUID, FK -> users.id ON DELETE CASCADE)
- `video_id` (UUID, FK -> videos.id ON DELETE CASCADE)
- `content` (TEXT, NOT NULL)
- `parent_comment_id` (UUID, FK -> video_comments.id ON DELETE CASCADE, Nullable)
- `created_at` (TIMESTAMPTZ, Default: now())

### 5. `video_saves`
- `id` (UUID, Primary Key)
- `user_id` (UUID, FK -> users.id ON DELETE CASCADE)
- `video_id` (UUID, FK -> videos.id ON DELETE CASCADE)
- `created_at` (TIMESTAMPTZ, Default: now())
- UNIQUE CONSTRAINT (`user_id`, `video_id`)

### 6. `follows`
- `id` (UUID, Primary Key)
- `follower_id` (UUID, FK -> users.id ON DELETE CASCADE)
- `following_id` (UUID, FK -> users.id ON DELETE CASCADE)
- `created_at` (TIMESTAMPTZ, Default: now())
- UNIQUE CONSTRAINT (`follower_id`, `following_id`)

### 7. `forum_posts`
- `id` (UUID, Primary Key)
- `author_id` (UUID, FK -> users.id ON DELETE CASCADE)
- `title` (VARCHAR(255), NOT NULL)
- `content` (TEXT, NOT NULL)
- `category` (VARCHAR(50), NOT NULL) -- e.g., 'discussion', 'collaboration', 'feedback'
- `tags` (VARCHAR(255))
- `views_count` (INTEGER, Default: 0)
- `created_at` (TIMESTAMPTZ, Default: now())
- `updated_at` (TIMESTAMPTZ, Default: now())

### 8. `forum_comments`
- `id` (UUID, Primary Key)
- `post_id` (UUID, FK -> forum_posts.id ON DELETE CASCADE)
- `author_id` (UUID, FK -> users.id ON DELETE CASCADE)
- `content` (TEXT, NOT NULL)
- `created_at` (TIMESTAMPTZ, Default: now())

### 9. `collaborations`
- `id` (UUID, Primary Key)
- `initiator_id` (UUID, FK -> users.id ON DELETE CASCADE)
- `target_user_id` (UUID, FK -> users.id ON DELETE CASCADE)
- `title` (VARCHAR(255), NOT NULL)
- `description` (TEXT, NOT NULL)
- `status` (VARCHAR(50), Default: 'pending') -- 'pending', 'accepted', 'declined'
- `created_at` (TIMESTAMPTZ, Default: now())

### 10. `notifications`
- `id` (UUID, Primary Key)
- `recipient_id` (UUID, FK -> users.id ON DELETE CASCADE, Indexed)
- `sender_id` (UUID, FK -> users.id ON DELETE CASCADE, Nullable)
- `type` (VARCHAR(50), NOT NULL) -- 'like', 'comment', 'follow', 'forum_reply'
- `title` (VARCHAR(255), NOT NULL)
- `message` (TEXT, NOT NULL)
- `is_read` (BOOLEAN, Default: FALSE)
- `created_at` (TIMESTAMPTZ, Default: now())
