import 'moderation_remote_datasource.dart';

abstract class ModerationRepository {
  Future<Map<String, dynamic>> reportContent({
    required String entityType,
    required String entityId,
    required String reason,
    String? details,
  });
  Future<void> blockUser(String userId);
  Future<void> unblockUser(String userId);
  Future<List<String>> getBlockedUserIds();
}

class ModerationRepositoryImpl implements ModerationRepository {
  final ModerationRemoteDataSource _remoteDataSource;

  ModerationRepositoryImpl({required ModerationRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Map<String, dynamic>> reportContent({
    required String entityType,
    required String entityId,
    required String reason,
    String? details,
  }) {
    return _remoteDataSource.reportContent(
      entityType: entityType,
      entityId: entityId,
      reason: reason,
      details: details,
    );
  }

  @override
  Future<void> blockUser(String userId) {
    return _remoteDataSource.blockUser(userId);
  }

  @override
  Future<void> unblockUser(String userId) {
    return _remoteDataSource.unblockUser(userId);
  }

  @override
  Future<List<String>> getBlockedUserIds() {
    return _remoteDataSource.getBlockedUserIds();
  }
}
