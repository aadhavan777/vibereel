import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibereel/core/mock/mock_data.dart';
import 'package:vibereel/features/feed/presentation/views/feed_view.dart';
import 'package:vibereel/features/feed/presentation/widgets/comments_bottom_sheet.dart';
import 'package:vibereel/features/feed/presentation/widgets/share_bottom_sheet.dart';

void main() {
  testWidgets('CommentsBottomSheet renders comments list and accepts new comment', (WidgetTester tester) async {
    final video = MockData.videos.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommentsBottomSheet(video: video),
        ),
      ),
    );

    expect(find.text('${video.commentsCount} Comments'), findsOneWidget);
    expect(find.text('Add a comment...'), findsOneWidget);

    // Enter comment text
    await tester.enterText(find.byType(TextField), 'Awesome reel!');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(find.text('Awesome reel!'), findsOneWidget);
  });

  testWidgets('ShareBottomSheet renders share options', (WidgetTester tester) async {
    final video = MockData.videos.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShareBottomSheet(video: video),
        ),
      ),
    );

    expect(find.text('Share Video'), findsOneWidget);
    expect(find.text('Copy Link'), findsOneWidget);
    expect(find.text('Share to Story'), findsOneWidget);
  });

  testWidgets('FeedView renders vertical feed layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FeedView(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('VibeReel'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
  });
}
