import 'package:flutter_test/flutter_test.dart';
import 'package:vibereel/features/notifications/data/notifications_repository.dart';
import 'package:vibereel/features/notifications/presentation/viewmodels/notifications_viewmodel.dart';
import 'package:vibereel/features/search/data/search_repository.dart';
import 'package:vibereel/features/search/presentation/viewmodels/search_viewmodel.dart';


class MockSearchRepository implements SearchRepository {
  @override
  Future<Map<String, dynamic>> search(String query, {String type = 'all', int page = 1}) async {
    return {
      'query': query,
      'videos': [
        {'id': 'v1', 'caption': 'Flutter search test video', 'creator_username': 'flutter_dev'}
      ],
      'creators': [
        {'id': 'c1', 'username': 'flutter_dev', 'email': 'dev@vibereel.com'}
      ],
      'hashtags': [
        {'tag': '#flutter', 'posts_count': 100, 'trending': true}
      ],
      'forum_posts': [
        {'id': 'p1', 'title': 'Flutter 3.x Tips', 'category': 'technology'}
      ],
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getTrendingSearches() async {
    return [
      {'tag': '#FlutterDev', 'category': 'Tech & Mobile', 'views': '1.2M'}
    ];
  }
}

class MockNotificationsRepository implements NotificationsRepository {
  List<Map<String, dynamic>> mockNotifs = [
    {
      'id': 'n1',
      'type': 'follow',
      'title': 'New Follower',
      'message': '@dev started following you',
      'is_read': false,
      'created_at': '2026-09-11'
    }
  ];

  @override
  Future<Map<String, dynamic>> getNotifications({bool unreadOnly = false, int page = 1}) async {
    final filtered = unreadOnly ? mockNotifs.where((n) => !n['is_read']).toList() : mockNotifs;
    final unreadCount = mockNotifs.where((n) => !n['is_read']).length;
    return {
      'items': filtered,
      'unread_count': unreadCount,
      'total': filtered.length,
      'page': page,
      'limit': 20,
    };
  }

  @override
  Future<int> getUnreadCount() async {
    return mockNotifs.where((n) => !n['is_read']).length;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    for (var n in mockNotifs) {
      if (n['id'] == notificationId) {
        n['is_read'] = true;
      }
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (var n in mockNotifs) {
      n['is_read'] = true;
    }
  }
}

void main() {
  group('SearchViewModel & NotificationsViewModel Tests', () {
    test('SearchViewModel performs search and updates state correctly', () async {
      final mockSearchRepo = MockSearchRepository();
      final searchViewModel = SearchViewModel(mockSearchRepo);

      expect(searchViewModel.currentState.query, '');
      
      await searchViewModel.performSearch('Flutter');

      expect(searchViewModel.currentState.query, 'Flutter');
      expect(searchViewModel.currentState.videos.length, 1);
      expect(searchViewModel.currentState.creators.length, 1);
      expect(searchViewModel.currentState.forumPosts.length, 1);
      expect(searchViewModel.currentState.recentSearches.contains('Flutter'), isTrue);

      searchViewModel.clearSearch();
      expect(searchViewModel.currentState.query, '');
      expect(searchViewModel.currentState.videos.isEmpty, isTrue);
    });

    test('NotificationsViewModel fetches and marks notifications as read', () async {
      final mockNotifRepo = MockNotificationsRepository();
      final notifViewModel = NotificationsViewModel(mockNotifRepo);

      await notifViewModel.fetchNotifications();

      expect(notifViewModel.currentState.items.length, 1);
      expect(notifViewModel.currentState.unreadCount, 1);

      await notifViewModel.markAsRead('n1');

      expect(notifViewModel.currentState.items.first['is_read'], isTrue);
      expect(notifViewModel.currentState.unreadCount, 0);
    });
  });
}

