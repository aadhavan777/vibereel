import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class NotificationsRemoteDataSource {
  final ApiClient _apiClient;

  NotificationsRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> getNotifications({bool unreadOnly = false, int page = 1}) async {
    final path = '${ApiEndpoints.notifications}?unread_only=$unreadOnly&page=$page';
    final response = await _apiClient.get(path);
    return Map<String, dynamic>.from(response as Map);
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(ApiEndpoints.notificationsUnreadCount);
    final map = Map<String, dynamic>.from(response as Map);
    return map['unread_count'] as int? ?? 0;
  }

  Future<void> markAsRead(String notificationId) async {
    await _apiClient.put(ApiEndpoints.markNotificationRead(notificationId));
  }

  Future<void> markAllAsRead() async {
    await _apiClient.put(ApiEndpoints.markAllNotificationsRead);
  }
}
