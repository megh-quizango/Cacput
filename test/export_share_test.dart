import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:capcut2/screens/editor/timeline_editor_screen.dart';

class MockSharePlatform extends SharePlatform {
  ShareParams? lastParams;

  @override
  Future<ShareResult> share(ShareParams params) async {
    lastParams = params;
    return const ShareResult('success', ShareResultStatus.success);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSharePlatform mockSharePlatform;
  late SharePlatform originalPlatform;

  setUp(() {
    mockSharePlatform = MockSharePlatform();
    originalPlatform = SharePlatform.instance;
    SharePlatform.instance = mockSharePlatform;
  });

  tearDown(() {
    SharePlatform.instance = originalPlatform;
  });

  group('Export Share Video Button Tests', () {
    testWidgets(
        'Export complete bottom sheet Share Video button launches share text intent with text "Check out this video"',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TimelineEditorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Export button in the top navigation bar
      final exportButtonFinder = find.widgetWithText(TextButton, 'Export');
      expect(exportButtonFinder, findsOneWidget);
      await tester.tap(exportButtonFinder);
      await tester.pumpAndSettle();

      // Tap "Start 4K Rendering" button to start the export
      final startRenderFinder = find.widgetWithText(ElevatedButton, 'Start 4K Rendering');
      expect(startRenderFinder, findsOneWidget);
      await tester.tap(startRenderFinder);
      await tester.pump();

      // Advance through export progress simulation (5 intervals of 300ms = 1500ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Modal bottom sheet should now be showing "Export Complete!"
      expect(find.text('Export Complete!'), findsOneWidget);

      // Verify the "Share Video" button exists
      final shareButtonFinder = find.widgetWithText(ElevatedButton, 'Share Video');
      expect(shareButtonFinder, findsOneWidget);

      // Tap the Share Video button
      await tester.tap(shareButtonFinder);
      await tester.pumpAndSettle();

      // Assert that share text intent was invoked with text "Check out this video"
      expect(mockSharePlatform.lastParams, isNotNull);
      expect(mockSharePlatform.lastParams!.text, equals('Check out this video'));
    });
  });
}
