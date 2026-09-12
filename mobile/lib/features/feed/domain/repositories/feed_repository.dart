import '../entities/video_entity.dart';

abstract class FeedRepository {
  Future<List<VideoEntity>> getFeed({int page = 1, int limit = 10});
  Future<VideoEntity> getVideoDetails(String videoId);
  Future<void> likeVideo(String videoId);
  Future<void> unlikeVideo(String videoId);
  Future<void> saveVideo(String videoId);
  Future<void> unsaveVideo(String videoId);
  Future<List<Map<String, dynamic>>> getComments(String videoId);
  Future<Map<String, dynamic>> addComment(String videoId, String content);
  Future<void> followUser(String userId);
  Future<void> unfollowUser(String userId);
}
