import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/moderation_remote_datasource.dart';
import '../../data/moderation_repository.dart';

final moderationRemoteDataSourceProvider = Provider<ModerationRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ModerationRemoteDataSource(apiClient: apiClient);
});

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  final remote = ref.watch(moderationRemoteDataSourceProvider);
  return ModerationRepositoryImpl(remoteDataSource: remote);
});

class ModerationState {
  final bool isLoading;
  final List<String> blockedUserIds;
  final String? message;
  final String? error;

  ModerationState({
    this.isLoading = false,
    this.blockedUserIds = const [],
    this.message,
    this.error,
  });

  ModerationState copyWith({
    bool? isLoading,
    List<String>? blockedUserIds,
    String? message,
    String? error,
  }) {
    return ModerationState(
      isLoading: isLoading ?? this.isLoading,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      message: message,
      error: error,
    );
  }
}

class ModerationViewModel extends StateNotifier<ModerationState> {
  final ModerationRepository _repository;

  ModerationState get currentState => state;

  ModerationViewModel(this._repository) : super(ModerationState()) {
    fetchBlockedUsers();
  }

  Future<void> fetchBlockedUsers() async {
    try {
      final blocked = await _repository.getBlockedUserIds();
      state = state.copyWith(blockedUserIds: blocked);
    } catch (_) {}
  }

  Future<bool> reportContent({
    required String entityType,
    required String entityId,
    required String reason,
    String? details,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.reportContent(
        entityType: entityType,
        entityId: entityId,
        reason: reason,
        details: details,
      );
      state = state.copyWith(isLoading: false, message: 'Report submitted successfully. Thank you for keeping VibeReel safe.');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _repository.blockUser(userId);
      final updated = List<String>.from(state.blockedUserIds)..add(userId);
      state = state.copyWith(blockedUserIds: updated, message: 'User blocked');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _repository.unblockUser(userId);
      final updated = List<String>.from(state.blockedUserIds)..remove(userId);
      state = state.copyWith(blockedUserIds: updated, message: 'User unblocked');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final moderationViewModelProvider =
    StateNotifierProvider<ModerationViewModel, ModerationState>((ref) {
  final repo = ref.watch(moderationRepositoryProvider);
  return ModerationViewModel(repo);
});
