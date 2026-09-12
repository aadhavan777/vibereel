import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibereel/main.dart';

void main() {
  testWidgets('VibeReel main app initializes successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VibeReelApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('VibeReel'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
  });
}
