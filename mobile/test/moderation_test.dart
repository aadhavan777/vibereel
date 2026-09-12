import 'package:flutter_test/flutter_test.dart';
import 'package:vibereel/features/moderation/data/moderation_repository.dart';
import 'package:vibereel/features/moderation/presentation/viewmodels/moderation_viewmodel.dart';

class MockModerationRepository implements ModerationRepository {
  List<String> mockBlockedUserIds = [];
  List<Map<String, dynamic>> mockReports = [];

  @override
  Future<Map<String, dynamic>> reportContent({
    required String entityType,
    required String entityId,
    required String reason,
    String? details,
  }) async {
    final report = {
      'id': 'rep_1',
      'entity_type': entityType,
      'entity_id': entityId,
      'reason': reason,
      'details': details,
      'status': 'pending',
    };
    mockReports.add(report);
    return report;
  }

  @override
  Future<void> blockUser(String userId) async {
    if (!mockBlockedUserIds.contains(userId)) {
      mockBlockedUserIds.add(userId);
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    mockBlockedUserIds.remove(userId);
  }

  @override
  Future<List<String>> getBlockedUserIds() async {
    return List.from(mockBlockedUserIds);
  }
}

void main() {
  group('ModerationViewModel Tests', () {
    test('reportContent submits report successfully', () async {
      final mockRepo = MockModerationRepository();
      final viewModel = ModerationViewModel(mockRepo);

      final success = await viewModel.reportContent(
        entityType: 'video',
        entityId: 'v123',
        reason: 'Spam or Scam',
        details: 'Suspicious link',
      );

      expect(success, isTrue);
      expect(mockRepo.mockReports.length, 1);
      expect(mockRepo.mockReports.first['reason'], 'Spam or Scam');
      expect(viewModel.currentState.message, contains('submitted successfully'));
    });

    test('blockUser and unblockUser update state correctly', () async {
      final mockRepo = MockModerationRepository();
      final viewModel = ModerationViewModel(mockRepo);

      await viewModel.blockUser('user_bad_actor');
      expect(viewModel.currentState.blockedUserIds.contains('user_bad_actor'), isTrue);

      await viewModel.unblockUser('user_bad_actor');
      expect(viewModel.currentState.blockedUserIds.contains('user_bad_actor'), isFalse);
    });
  });
}
