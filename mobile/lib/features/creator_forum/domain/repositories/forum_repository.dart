import '../entities/forum_post_entity.dart';

abstract class ForumRepository {
  Future<List<ForumPostEntity>> getPosts({
    String? category,
    String? search,
    String sortBy = 'latest',
    int page = 1,
  });
  Future<ForumPostEntity> createPost(String title, String content, String category, String? tags);
  Future<ForumPostEntity> getPostDetails(String postId);
  Future<ForumPostEntity> updatePost(
    String postId, {
    String? title,
    String? content,
    String? category,
    String? tags,
  });
  Future<void> deletePost(String postId);
  Future<void> likePost(String postId);
  Future<void> unlikePost(String postId);
  Future<List<ForumCommentEntity>> getComments(String postId);
  Future<ForumCommentEntity> createComment(String postId, String content, {String? parentCommentId});
  Future<void> reportContent({String? postId, String? commentId, required String reason, String? details});
}

