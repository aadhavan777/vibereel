import 'notifications_remote_datasource.dart';

abstract class NotificationsRepository {
  Future<Map<String, dynamic>> getNotifications({bool unreadOnly, int page});
  Future<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remoteDataSource;

  NotificationsRepositoryImpl({required NotificationsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Map<String, dynamic>> getNotifications({bool unreadOnly = false, int page = 1}) {
    return _remoteDataSource.getNotifications(unreadOnly: unreadOnly, page: page);
  }

  @override
  Future<int> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() {
    return _remoteDataSource.markAllAsRead();
  }
}
