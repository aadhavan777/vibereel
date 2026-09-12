import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibereel/features/create/presentation/views/create_view.dart';
import 'package:vibereel/features/profile/presentation/views/profile_view.dart';

void main() {
  testWidgets('CreateView renders creation step options', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CreateView(),
        ),
      ),
    );

    expect(find.text('Create Short Video'), findsOneWidget);
    expect(find.text('Record with Camera'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);

    // Tap record with camera
    await tester.tap(find.text('Record with Camera'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2: Preview & Trim Video'), findsOneWidget);
    expect(find.text('Next: Details'), findsOneWidget);

    // Tap next
    await tester.ensureVisible(find.text('Next: Details'));
    await tester.tap(find.text('Next: Details'));
    await tester.pumpAndSettle();

    expect(find.text('Step 3: Caption & Hashtags'), findsOneWidget);
    expect(find.text('Publish Video'), findsOneWidget);
    expect(find.text('Save to Drafts'), findsOneWidget);
  });

  testWidgets('ProfileView renders creator stats and tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileView(),
        ),
      ),
    );

    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Likes'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Drafts'), findsOneWidget);
  });
}
