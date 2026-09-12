import 'package:flutter_test/flutter_test.dart';
import 'package:vibereel/features/creator_forum/domain/entities/forum_post_entity.dart';
import 'package:vibereel/features/creator_forum/domain/repositories/forum_repository.dart';
import 'package:vibereel/features/creator_forum/presentation/viewmodels/forum_viewmodel.dart';

class MockForumRepository implements ForumRepository {
  List<ForumPostEntity> mockPosts = [
    ForumPostEntity(
      id: 'fp1',
      authorId: 'u1',
      authorUsername: 'editmaster',
      title: 'Premiere Pro vs DaVinci Resolve for 4K Shorts',
      content: 'Which video editor has faster render times for vertical export?',
      category: 'video_editing',
      tags: 'editing, premiere',
      viewsCount: 100,
      likesCount: 10,
      commentsCount: 2,
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<ForumPostEntity>> getPosts({
    String? category,
    String? search,
    String sortBy = 'latest',
    int page = 1,
  }) async {
    var list = mockPosts;
    if (category != null) {
      list = list.where((p) => p.category == category).toList();
    }
    if (search != null) {
      list = list.where((p) => p.title.contains(search)).toList();
    }
    return list;
  }

  @override
  Future<ForumPostEntity> createPost(String title, String content, String category, String? tags) async {
    final newP = ForumPostEntity(
      id: 'fp2',
      authorId: 'u2',
      authorUsername: 'vibemaster',
      title: title,
      content: content,
      category: category,
      tags: tags,
      viewsCount: 0,
      likesCount: 0,
      commentsCount: 0,
      createdAt: DateTime.now(),
    );
    mockPosts.add(newP);
    return newP;
  }

  @override
  Future<ForumPostEntity> getPostDetails(String postId) async {
    return mockPosts.firstWhere((p) => p.id == postId);
  }

  @override
  Future<ForumPostEntity> updatePost(String postId, {String? title, String? content, String? category, String? tags}) async {
    final p = mockPosts.firstWhere((element) => element.id == postId);
    final updated = p.copyWith(title: title, content: content, category: category, tags: tags);
    return updated;
  }

  @override
  Future<void> deletePost(String postId) async {
    mockPosts.removeWhere((p) => p.id == postId);
  }

  @override
  Future<void> likePost(String postId) async {}

  @override
  Future<void> unlikePost(String postId) async {}

  @override
  Future<List<ForumCommentEntity>> getComments(String postId) async {
    return [
      ForumCommentEntity(
        id: 'fc1',
        postId: postId,
        authorId: 'u3',
        authorUsername: 'colorist',
        content: 'DaVinci Resolve has much faster GPU rendering!',
        likesCount: 3,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<ForumCommentEntity> createComment(String postId, String content, {String? parentCommentId}) async {
    return ForumCommentEntity(
      id: 'fc2',
      postId: postId,
      authorId: 'u2',
      authorUsername: 'vibemaster',
      parentCommentId: parentCommentId,
      content: content,
      likesCount: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> reportContent({String? postId, String? commentId, required String reason, String? details}) async {}
}

void main() {
  test('ForumViewModel handles post creation, optimistic likes, comments, and reports', () async {
    final repository = MockForumRepository();
    final viewModel = ForumViewModel(repository);

    // Initial fetch
    await Future.delayed(const Duration(milliseconds: 50));
    expect(viewModel.state.posts.length, greaterThanOrEqualTo(1));

    // Optimistic Liking
    final firstPostId = viewModel.state.posts.first.id;
    final initialLikes = viewModel.state.posts.first.likesCount;
    final initialIsLiked = viewModel.state.posts.first.isLiked;

    viewModel.toggleLikePost(firstPostId);
    expect(viewModel.state.posts.first.isLiked, equals(!initialIsLiked));
    expect(viewModel.state.posts.first.likesCount, equals(initialLikes + 1));

    // Create New Discussion Post
    await viewModel.createPost('Growth Hacking 101', 'How to gain 10k followers in 30 days?', 'growth_analytics', 'growth, analytics');
    expect(viewModel.state.posts.any((p) => p.title == 'Growth Hacking 101'), isTrue);

    // Fetch Comments
    await viewModel.fetchComments(firstPostId);
    expect(viewModel.state.commentsMap[firstPostId], isNotNull);
    expect(viewModel.state.commentsMap[firstPostId]!.length, equals(1));

    // Report Content
    final reported = await viewModel.reportContent(postId: firstPostId, reason: 'inappropriate');
    expect(reported, isTrue);
  });
}
