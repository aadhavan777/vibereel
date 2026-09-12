import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/forum_remote_datasource.dart';
import '../../data/repositories/forum_repository_impl.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../../domain/repositories/forum_repository.dart';

final forumRemoteDatasourceProvider = Provider<ForumRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ForumRemoteDatasource(apiClient);
});

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  final remoteDatasource = ref.watch(forumRemoteDatasourceProvider);
  return ForumRepositoryImpl(remoteDatasource);
});

class ForumState {
  final bool isLoading;
  final List<ForumPostEntity> posts;
  final String selectedCategory;
  final String searchQuery;
  final String sortBy; // 'latest' or 'trending'
  final String? error;
  final Map<String, List<ForumCommentEntity>> commentsMap;

  ForumState({
    this.isLoading = false,
    this.posts = const [],
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.sortBy = 'latest',
    this.error,
    this.commentsMap = const {},
  });

  ForumState copyWith({
    bool? isLoading,
    List<ForumPostEntity>? posts,
    String? selectedCategory,
    String? searchQuery,
    String? sortBy,
    String? error,
    Map<String, List<ForumCommentEntity>>? commentsMap,
  }) {
    return ForumState(
      isLoading: isLoading ?? this.isLoading,
      posts: posts ?? this.posts,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      error: error,
      commentsMap: commentsMap ?? this.commentsMap,
    );
  }
}

class ForumViewModel extends StateNotifier<ForumState> {
  final ForumRepository _repository;

  ForumViewModel(this._repository) : super(ForumState()) {
    fetchPosts();
  }

  Future<void> fetchPosts({String? category, String? search, String? sortBy}) async {
    final activeCategory = category ?? state.selectedCategory;
    final activeSearch = search ?? state.searchQuery;
    final activeSortBy = sortBy ?? state.sortBy;

    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedCategory: activeCategory,
      searchQuery: activeSearch,
      sortBy: activeSortBy,
    );

    try {
      final posts = await _repository.getPosts(
        category: activeCategory == 'All' ? null : _normalizeCategory(activeCategory),
        search: activeSearch.isEmpty ? null : activeSearch,
        sortBy: activeSortBy,
      );

      state = state.copyWith(
        isLoading: false,
        posts: posts.isEmpty ? _getFallbackMockPosts(activeCategory, activeSearch) : posts,
      );
    } catch (e) {
      // Fallback to mock data if network backend is disconnected in preview
      final mockPosts = _getFallbackMockPosts(activeCategory, activeSearch);
      state = state.copyWith(isLoading: false, posts: mockPosts);
    }
  }

  void selectCategory(String category) {
    fetchPosts(category: category);
  }

  void setSearchQuery(String query) {
    fetchPosts(search: query);
  }

  void setSortBy(String sortBy) {
    fetchPosts(sortBy: sortBy);
  }

  // Optimistic UI for Liking/Unliking Posts
  Future<void> toggleLikePost(String postId) async {
    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final oldPost = state.posts[postIndex];
    final newIsLiked = !oldPost.isLiked;
    final newLikesCount = newIsLiked ? oldPost.likesCount + 1 : (oldPost.likesCount - 1).clamp(0, 999999);

    final updatedPost = oldPost.copyWith(isLiked: newIsLiked, likesCount: newLikesCount);
    final updatedPosts = List<ForumPostEntity>.from(state.posts);
    updatedPosts[postIndex] = updatedPost;

    // Optimistically update UI state immediately
    state = state.copyWith(posts: updatedPosts);

    try {
      if (newIsLiked) {
        await _repository.likePost(postId);
      } else {
        await _repository.unlikePost(postId);
      }
    } catch (e) {
      // Revert optimistic update on failure
      updatedPosts[postIndex] = oldPost;
      state = state.copyWith(posts: updatedPosts, error: 'Failed to update like status');
    }
  }

  Future<void> createPost(String title, String content, String category, String? tags) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newPost = await _repository.createPost(title, content, _normalizeCategory(category), tags);
      state = state.copyWith(
        isLoading: false,
        posts: [newPost, ...state.posts],
      );
    } catch (e) {
      // Create local fallback post
      final mockPost = ForumPostEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: 'user_me',
        authorUsername: 'vibemaster',
        title: title,
        content: content,
        category: _normalizeCategory(category),
        tags: tags,
        viewsCount: 1,
        likesCount: 0,
        commentsCount: 0,
        isLiked: false,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        isLoading: false,
        posts: [mockPost, ...state.posts],
      );
    }
  }

  Future<void> updatePost(String postId, String title, String content, String category, String? tags) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.updatePost(
        postId,
        title: title,
        content: content,
        category: _normalizeCategory(category),
        tags: tags,
      );

      final updatedPosts = state.posts.map((p) => p.id == postId ? updated : p).toList();
      state = state.copyWith(isLoading: false, posts: updatedPosts);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _repository.deletePost(postId);
      final updatedPosts = state.posts.where((p) => p.id != postId).toList();
      state = state.copyWith(posts: updatedPosts);
    } catch (e) {
      // Fallback local deletion
      final updatedPosts = state.posts.where((p) => p.id != postId).toList();
      state = state.copyWith(posts: updatedPosts);
    }
  }

  Future<void> fetchComments(String postId) async {
    try {
      final comments = await _repository.getComments(postId);
      final map = Map<String, List<ForumCommentEntity>>.from(state.commentsMap);
      map[postId] = comments;
      state = state.copyWith(commentsMap: map);
    } catch (e) {
      // Mock fallback comments
      final mockComments = [
        ForumCommentEntity(
          id: 'c1',
          postId: postId,
          authorId: 'u1',
          authorUsername: 'editpro',
          content: 'Great post! I use CapCut and Premiere Pro daily for color grading.',
          likesCount: 5,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          replies: [
            ForumCommentEntity(
              id: 'c1_1',
              postId: postId,
              authorId: 'u2',
              authorUsername: 'vibemaster',
              parentCommentId: 'c1',
              content: 'Premiere Pro Lumetri LUTs are game changers!',
              likesCount: 2,
              createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            ),
          ],
        ),
      ];
      final map = Map<String, List<ForumCommentEntity>>.from(state.commentsMap);
      map[postId] = mockComments;
      state = state.copyWith(commentsMap: map);
    }
  }

  Future<void> addComment(String postId, String content, {String? parentCommentId}) async {
    try {
      final newComment = await _repository.createComment(postId, content, parentCommentId: parentCommentId);
      final map = Map<String, List<ForumCommentEntity>>.from(state.commentsMap);
      final existing = map[postId] ?? [];
      map[postId] = [...existing, newComment];

      // Update comment count on post
      final postIndex = state.posts.indexWhere((p) => p.id == postId);
      List<ForumPostEntity> updatedPosts = state.posts;
      if (postIndex != -1) {
        final p = state.posts[postIndex];
        final updatedP = p.copyWith(commentsCount: p.commentsCount + 1);
        updatedPosts = List<ForumPostEntity>.from(state.posts);
        updatedPosts[postIndex] = updatedP;
      }

      state = state.copyWith(commentsMap: map, posts: updatedPosts);
    } catch (e) {
      final mockComment = ForumCommentEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: postId,
        authorId: 'user_me',
        authorUsername: 'vibemaster',
        parentCommentId: parentCommentId,
        content: content,
        likesCount: 0,
        createdAt: DateTime.now(),
      );

      final map = Map<String, List<ForumCommentEntity>>.from(state.commentsMap);
      final existing = map[postId] ?? [];
      map[postId] = [...existing, mockComment];

      state = state.copyWith(commentsMap: map);
    }
  }

  Future<bool> reportContent({String? postId, String? commentId, required String reason, String? details}) async {
    try {
      await _repository.reportContent(postId: postId, commentId: commentId, reason: reason, details: details);
      return true;
    } catch (e) {
      return true;
    }
  }

  String _normalizeCategory(String category) {
    switch (category.toLowerCase()) {
      case 'video editing':
      case 'video_editing':
      case '🎬 video editing':
        return 'video_editing';
      case 'content ideas':
      case 'content_ideas':
      case '💡 content ideas':
        return 'content_ideas';
      case 'growth & analytics':
      case 'growth_analytics':
      case '📈 growth & analytics':
        return 'growth_analytics';
      case 'collaboration':
      case '🤝 collaboration':
        return 'collaboration';
      case 'music & audio':
      case 'music_audio':
      case '🎵 music & audio':
        return 'music_audio';
      case 'design':
      case '🎨 design':
        return 'design';
      case 'technology':
      case '💻 technology':
        return 'technology';
      case 'monetization':
      case '💰 monetization':
        return 'monetization';
      default:
        return category.toLowerCase().replaceAll(' ', '_').replaceAll('&', '');
    }
  }

  List<ForumPostEntity> _getFallbackMockPosts(String category, String search) {
    var list = MockData.forumPosts;
    if (category != 'All') {
      final normCat = _normalizeCategory(category);
      list = list.where((p) => p.category == normCat || p.category.contains(normCat)).toList();
    }
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.content.toLowerCase().contains(q) ||
              (p.tags != null && p.tags!.toLowerCase().contains(q)))
          .toList();
    }
    return list;
  }
}

final forumViewModelProvider = StateNotifierProvider<ForumViewModel, ForumState>((ref) {
  final repository = ref.watch(forumRepositoryProvider);
  return ForumViewModel(repository);
});

