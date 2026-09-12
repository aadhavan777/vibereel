import '../../../../core/mock/mock_data.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_datasource.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDatasource _remoteDatasource;

  FeedRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<VideoEntity>> getFeed({int page = 1, int limit = 10}) async {
    try {
      final dtos = await _remoteDatasource.getFeed(page: page, limit: limit);
      if (dtos.isEmpty) return MockData.videos;
      return dtos.map((dto) => dto.toEntity()).toList();
    } catch (_) {
      // Fallback to MockData if backend is unreachable or offline
      return MockData.videos;
    }
  }

  @override
  Future<VideoEntity> getVideoDetails(String videoId) async {
    try {
      final dto = await _remoteDatasource.getVideoDetails(videoId);
      return dto.toEntity();
    } catch (_) {
      return MockData.videos.firstWhere(
        (v) => v.id == videoId,
        orElse: () => MockData.videos.first,
      );
    }
  }

  @override
  Future<void> likeVideo(String videoId) async {
    try {
      await _remoteDatasource.likeVideo(videoId);
    } catch (_) {}
  }

  @override
  Future<void> unlikeVideo(String videoId) async {
    try {
      await _remoteDatasource.unlikeVideo(videoId);
    } catch (_) {}
  }

  @override
  Future<void> saveVideo(String videoId) async {
    try {
      await _remoteDatasource.saveVideo(videoId);
    } catch (_) {}
  }

  @override
  Future<void> unsaveVideo(String videoId) async {
    try {
      await _remoteDatasource.unsaveVideo(videoId);
    } catch (_) {}
  }

  @override
  Future<List<Map<String, dynamic>>> getComments(String videoId) async {
    try {
      return await _remoteDatasource.getComments(videoId);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> addComment(String videoId, String content) async {
    try {
      return await _remoteDatasource.addComment(videoId, content);
    } catch (_) {
      return {
        'id': 'comment_mock',
        'content': content,
        'username': 'vibemaster',
        'created_at': DateTime.now().toIso8601String(),
      };
    }
  }

  @override
  Future<void> followUser(String userId) async {
    try {
      await _remoteDatasource.followUser(userId);
    } catch (_) {}
  }

  @override
  Future<void> unfollowUser(String userId) async {
    try {
      await _remoteDatasource.unfollowUser(userId);
    } catch (_) {}
  }
}
