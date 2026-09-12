import '../../domain/entities/forum_post_entity.dart';

class ForumPostDto {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final String category;
  final String? tags;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final String createdAt;
  final Map<String, dynamic>? author;

  ForumPostDto({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.category,
    this.tags,
    required this.viewsCount,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.author,
  });

  factory ForumPostDto.fromJson(Map<String, dynamic> json) {
    return ForumPostDto(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String? ?? 'video_editing',
      tags: json['tags'] as String?,
      viewsCount: json['views_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      author: json['author'] as Map<String, dynamic>?,
    );
  }

  ForumPostEntity toEntity() {
    return ForumPostEntity(
      id: id,
      authorId: authorId,
      authorUsername: author?['username'] as String? ?? 'creator',
      authorAvatarUrl: author?['avatar_url'] as String?,
      title: title,
      content: content,
      category: category,
      tags: tags,
      viewsCount: viewsCount,
      likesCount: likesCount,
      commentsCount: commentsCount,
      isLiked: isLiked,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }
}

class ForumCommentDto {
  final String id;
  final String postId;
  final String authorId;
  final String? parentCommentId;
  final String content;
  final int likesCount;
  final bool isLiked;
  final String createdAt;
  final Map<String, dynamic>? author;
  final List<ForumCommentDto> replies;

  ForumCommentDto({
    required this.id,
    required this.postId,
    required this.authorId,
    this.parentCommentId,
    required this.content,
    this.likesCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.author,
    this.replies = const [],
  });

  factory ForumCommentDto.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'] as List<dynamic>? ?? [];
    return ForumCommentDto(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorId: json['author_id'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      content: json['content'] as String,
      likesCount: json['likes_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      author: json['author'] as Map<String, dynamic>?,
      replies: rawReplies.map((r) => ForumCommentDto.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }

  ForumCommentEntity toEntity() {
    return ForumCommentEntity(
      id: id,
      postId: postId,
      authorId: authorId,
      authorUsername: author?['username'] as String? ?? 'anonymous',
      authorAvatarUrl: author?['avatar_url'] as String?,
      parentCommentId: parentCommentId,
      content: content,
      likesCount: likesCount,
      isLiked: isLiked,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      replies: replies.map((r) => r.toEntity()).toList(),
    );
  }
}

