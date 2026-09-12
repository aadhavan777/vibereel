import 'package:equatable/equatable.dart';

class ForumPostEntity extends Equatable {
  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String title;
  final String content;
  final String category;
  final String? tags;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;

  const ForumPostEntity({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarUrl,
    required this.title,
    required this.content,
    required this.category,
    this.tags,
    required this.viewsCount,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  ForumPostEntity copyWith({
    String? id,
    String? authorId,
    String? authorUsername,
    String? authorAvatarUrl,
    String? title,
    String? content,
    String? category,
    String? tags,
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    DateTime? createdAt,
  }) {
    return ForumPostEntity(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        authorUsername,
        authorAvatarUrl,
        title,
        content,
        category,
        tags,
        viewsCount,
        likesCount,
        commentsCount,
        isLiked,
        createdAt,
      ];
}

class ForumCommentEntity extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String? parentCommentId;
  final String content;
  final int likesCount;
  final bool isLiked;
  final DateTime createdAt;
  final List<ForumCommentEntity> replies;

  const ForumCommentEntity({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarUrl,
    this.parentCommentId,
    required this.content,
    this.likesCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.replies = const [],
  });

  @override
  List<Object?> get props => [
        id,
        postId,
        authorId,
        authorUsername,
        authorAvatarUrl,
        parentCommentId,
        content,
        likesCount,
        isLiked,
        createdAt,
        replies,
      ];
}

