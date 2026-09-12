import '../../../../core/network/api_client.dart';

class CreateRemoteDatasource {
  final ApiClient _apiClient;

  CreateRemoteDatasource(this._apiClient);

  Future<Map<String, dynamic>> createVideo({
    required String videoUrl,
    String? thumbnailUrl,
    String? caption,
    List<String> hashtags = const [],
    bool isDraft = false,
  }) async {
    final response = await _apiClient.post(
      '/videos',
      body: {
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'caption': caption,
        'hashtags': hashtags,
        'is_draft': isDraft,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateVideo({
    required String videoId,
    String? caption,
    String? thumbnailUrl,
    bool isDraft = false,
  }) async {
    final response = await _apiClient.post(
      '/videos/$videoId',
      body: {
        'caption': caption,
        'thumbnail_url': thumbnailUrl,
        'is_draft': isDraft,
      },
    );
    return response as Map<String, dynamic>;
  }
}
