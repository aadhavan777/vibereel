import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibereel/core/mock/mock_data.dart';
import 'package:vibereel/features/feed/presentation/viewmodels/feed_viewmodel.dart';
import 'package:vibereel/features/creator_forum/presentation/viewmodels/forum_viewmodel.dart';

void main() {
  test('MockData contains initial short video items and forum posts', () {
    expect(MockData.videos.length, greaterThan(0));
    expect(MockData.forumPosts.length, greaterThan(0));
    expect(MockData.currentUser.username, equals('vibemaster'));
  });

  test('FeedState initializes in loading state when constructed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final feedState = container.read(feedViewModelProvider);
    expect(feedState.isLoading, isTrue);
    expect(feedState.videos, isEmpty);
  });

  test('ForumState initializes in loading state when constructed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final forumState = container.read(forumViewModelProvider);
    expect(forumState.isLoading, isTrue);
    expect(forumState.posts, isEmpty);
  });
}
