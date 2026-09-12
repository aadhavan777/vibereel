import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/forum_post_dto.dart';

class ForumRemoteDatasource {
  final ApiClient _apiClient;

  ForumRemoteDatasource(this._apiClient);

  Future<List<ForumPostDto>> getPosts({
    String? category,
    String? search,
    String sortBy = 'latest',
    int page = 1,
  }) async {
    String path = '${ApiEndpoints.forumPosts}?page=$page&sort_by=$sortBy';
    if (category != null && category.toLowerCase() != 'all') {
      path += '&category=$category';
    }
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    final response = await _apiClient.get(path);
    final items = (response['items'] as List<dynamic>? ?? []);
    return items.map((item) => ForumPostDto.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ForumPostDto> createPost(
    String title,
    String content,
    String category,
    String? tags,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.forumPosts,
      body: {
        'title': title,
        'content': content,
        'category': category,
        'tags': tags,
      },
    );
    return ForumPostDto.fromJson(response as Map<String, dynamic>);
  }

  Future<ForumPostDto> getPostDetails(String postId) async {
    final response = await _apiClient.get('${ApiEndpoints.forumPosts}/$postId');
    return ForumPostDto.fromJson(response as Map<String, dynamic>);
  }

  Future<ForumPostDto> updatePost(
    String postId, {
    String? title,
    String? content,
    String? category,
    String? tags,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.forumPosts}/$postId',
      body: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (category != null) 'category': category,
        if (tags != null) 'tags': tags,
      },
    );
    return ForumPostDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deletePost(String postId) async {
    await _apiClient.delete('${ApiEndpoints.forumPosts}/$postId');
  }

  Future<Map<String, dynamic>> likePost(String postId) async {
    final response = await _apiClient.post('${ApiEndpoints.forumPosts}/$postId/like');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlikePost(String postId) async {
    final response = await _apiClient.delete('${ApiEndpoints.forumPosts}/$postId/like');
    return response as Map<String, dynamic>;
  }

  Future<List<ForumCommentDto>> getComments(String postId) async {
    final response = await _apiClient.get('${ApiEndpoints.forumPosts}/$postId/comments');
    final items = response as List<dynamic>;
    return items.map((item) => ForumCommentDto.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ForumCommentDto> createComment(
    String postId,
    String content, {
    String? parentCommentId,
  }) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.forumPosts}/$postId/comments',
      body: {
        'content': content,
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      },
    );
    return ForumCommentDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> reportContent({
    String? postId,
    String? commentId,
    required String reason,
    String? details,
  }) async {
    await _apiClient.post(
      '/forum/reports',
      body: {
        if (postId != null) 'post_id': postId,
        if (commentId != null) 'comment_id': commentId,
        'reason': reason,
        if (details != null) 'details': details,
      },
    );
  }
}

