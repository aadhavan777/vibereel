import '../../domain/entities/forum_post_entity.dart';
import '../../domain/repositories/forum_repository.dart';
import '../datasources/forum_remote_datasource.dart';

class ForumRepositoryImpl implements ForumRepository {
  final ForumRemoteDatasource _remoteDatasource;

  ForumRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<ForumPostEntity>> getPosts({
    String? category,
    String? search,
    String sortBy = 'latest',
    int page = 1,
  }) async {
    final dtos = await _remoteDatasource.getPosts(
      category: category,
      search: search,
      sortBy: sortBy,
      page: page,
    );
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<ForumPostEntity> createPost(
    String title,
    String content,
    String category,
    String? tags,
  ) async {
    final dto = await _remoteDatasource.createPost(title, content, category, tags);
    return dto.toEntity();
  }

  @override
  Future<ForumPostEntity> getPostDetails(String postId) async {
    final dto = await _remoteDatasource.getPostDetails(postId);
    return dto.toEntity();
  }

  @override
  Future<ForumPostEntity> updatePost(
    String postId, {
    String? title,
    String? content,
    String? category,
    String? tags,
  }) async {
    final dto = await _remoteDatasource.updatePost(
      postId,
      title: title,
      content: content,
      category: category,
      tags: tags,
    );
    return dto.toEntity();
  }

  @override
  Future<void> deletePost(String postId) async {
    await _remoteDatasource.deletePost(postId);
  }

  @override
  Future<void> likePost(String postId) async {
    await _remoteDatasource.likePost(postId);
  }

  @override
  Future<void> unlikePost(String postId) async {
    await _remoteDatasource.unlikePost(postId);
  }

  @override
  Future<List<ForumCommentEntity>> getComments(String postId) async {
    final dtos = await _remoteDatasource.getComments(postId);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<ForumCommentEntity> createComment(
    String postId,
    String content, {
    String? parentCommentId,
  }) async {
    final dto = await _remoteDatasource.createComment(
      postId,
      content,
      parentCommentId: parentCommentId,
    );
    return dto.toEntity();
  }

  @override
  Future<void> reportContent({
    String? postId,
    String? commentId,
    required String reason,
    String? details,
  }) async {
    await _remoteDatasource.reportContent(
      postId: postId,
      commentId: commentId,
      reason: reason,
      details: details,
    );
  }
}

