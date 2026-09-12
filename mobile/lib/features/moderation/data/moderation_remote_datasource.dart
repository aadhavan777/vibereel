import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class ModerationRemoteDataSource {
  final ApiClient _apiClient;

  ModerationRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> reportContent({
    required String entityType,
    required String entityId,
    required String reason,
    String? details,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.reportContent,
      body: {
        'entity_type': entityType,
        'entity_id': entityId,
        'reason': reason,
        'details': details,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> blockUser(String userId) async {
    await _apiClient.post(ApiEndpoints.blockUser(userId));
  }

  Future<void> unblockUser(String userId) async {
    await _apiClient.delete(ApiEndpoints.blockUser(userId));
  }

  Future<List<String>> getBlockedUserIds() async {
    final response = await _apiClient.get(ApiEndpoints.blockedUsers);
    final map = Map<String, dynamic>.from(response as Map);
    final list = (map['blocked_user_ids'] as List? ?? []);
    return list.map((e) => e.toString()).toList();
  }
}
