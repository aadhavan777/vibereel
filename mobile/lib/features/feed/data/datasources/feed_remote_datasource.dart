import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/video_dto.dart';

class FeedRemoteDatasource {
  final ApiClient _apiClient;

  FeedRemoteDatasource(this._apiClient);

  Future<List<VideoDto>> getFeed({int page = 1, int limit = 10}) async {
    final response = await _apiClient.get('${ApiEndpoints.feed}?page=$page&limit=$limit');
    final items = (response as Map<String, dynamic>)['items'] as List<dynamic>;
    return items.map((item) => VideoDto.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<VideoDto> getVideoDetails(String videoId) async {
    final response = await _apiClient.get('${ApiEndpoints.feed}/$videoId');
    return VideoDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> likeVideo(String videoId) async {
    await _apiClient.post('${ApiEndpoints.feed}/$videoId/like');
  }

  Future<void> unlikeVideo(String videoId) async {
    await _apiClient.delete('${ApiEndpoints.feed}/$videoId/like');
  }

  Future<void> saveVideo(String videoId) async {
    await _apiClient.post('${ApiEndpoints.feed}/$videoId/save');
  }

  Future<void> unsaveVideo(String videoId) async {
    await _apiClient.delete('${ApiEndpoints.feed}/$videoId/save');
  }

  Future<List<Map<String, dynamic>>> getComments(String videoId) async {
    final response = await _apiClient.get('${ApiEndpoints.feed}/$videoId/comments');
    final items = response as List<dynamic>;
    return items.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> addComment(String videoId, String content) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.feed}/$videoId/comments',
      body: {'content': content},
    );
    return response as Map<String, dynamic>;
  }

  Future<void> followUser(String userId) async {
    await _apiClient.post('/users/$userId/follow');
  }

  Future<void> unfollowUser(String userId) async {
    await _apiClient.delete('/users/$userId/follow');
  }
}
