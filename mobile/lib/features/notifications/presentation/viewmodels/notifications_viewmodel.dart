import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

import '../../data/notifications_remote_datasource.dart';
import '../../data/notifications_repository.dart';

final notificationsRemoteDataSourceProvider = Provider<NotificationsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsRemoteDataSource(apiClient: apiClient);
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final remote = ref.watch(notificationsRemoteDataSourceProvider);
  return NotificationsRepositoryImpl(remoteDataSource: remote);
});

class NotificationsState {
  final bool isLoading;
  final List<dynamic> items;
  final int unreadCount;
  final bool unreadOnlyFilter;
  final String? error;

  NotificationsState({
    this.isLoading = false,
    this.items = const [],
    this.unreadCount = 0,
    this.unreadOnlyFilter = false,
    this.error,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<dynamic>? items,
    int? unreadCount,
    bool? unreadOnlyFilter,
    String? error,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadOnlyFilter: unreadOnlyFilter ?? this.unreadOnlyFilter,
      error: error,
    );
  }
}

class NotificationsViewModel extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsState get currentState => state;

  NotificationsViewModel(this._repository) : super(NotificationsState()) {
    fetchNotifications();
  }


  Future<void> fetchNotifications({bool? unreadOnly}) async {
    final filter = unreadOnly ?? state.unreadOnlyFilter;
    state = state.copyWith(isLoading: true, unreadOnlyFilter: filter, error: null);

    try {
      final res = await _repository.getNotifications(unreadOnly: filter);
      state = state.copyWith(
        isLoading: false,
        items: res['items'] ?? [],
        unreadCount: res['unread_count'] ?? 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      final updatedItems = state.items.map((item) {
        if (item['id'] == id) {
          final copy = Map<String, dynamic>.from(item as Map);
          copy['is_read'] = true;
          return copy;
        }
        return item;
      }).toList();
      final newUnread = (state.unreadCount - 1).clamp(0, 999);
      state = state.copyWith(items: updatedItems, unreadCount: newUnread);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      final updatedItems = state.items.map((item) {
        final copy = Map<String, dynamic>.from(item as Map);
        copy['is_read'] = true;
        return copy;
      }).toList();
      state = state.copyWith(items: updatedItems, unreadCount: 0);
    } catch (_) {}
  }

  void toggleUnreadFilter() {
    fetchNotifications(unreadOnly: !state.unreadOnlyFilter);
  }
}

final notificationsViewModelProvider =
    StateNotifierProvider<NotificationsViewModel, NotificationsState>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return NotificationsViewModel(repo);
});
