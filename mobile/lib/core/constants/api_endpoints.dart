class ApiEndpoints {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator default
  static const String iosBaseUrl = 'http://localhost:8000/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Users
  static const String me = '/users/me';
  static String userProfile(String userId) => '/users/$userId';

  // Feed & Videos
  static const String feed = '/feed';
  static const String uploadVideo = '/videos/upload';

  // Creator Forum
  static const String forumPosts = '/forum/posts';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // Search
  static const String search = '/search';
  static const String trendingSearches = '/search/trending';

  // Moderation
  static const String reportContent = '/moderation/reports';
  static String blockUser(String userId) => '/moderation/blocks/$userId';
  static const String blockedUsers = '/moderation/blocks';
}


