import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capcut2/screens/splash/splash_screen.dart';
import 'package:capcut2/screens/explore/template_detail_screen.dart';
import 'package:capcut2/screens/ai_studio/auto_caption_screen.dart';
import 'package:capcut2/screens/studio/widgets/new_project_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Device Bottom Navigation Bar Safe Area Tests', () {
    testWidgets('SplashScreen includes SafeArea protecting content from bottom navigation bar',
        (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 48);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      final safeAreaFinder = find.descendant(
        of: find.byType(SplashScreen),
        matching: find.byType(SafeArea),
      );
      expect(safeAreaFinder, findsOneWidget);

      final safeArea = tester.widget<SafeArea>(safeAreaFinder);
      expect(safeArea.bottom, isTrue);

      tester.view.resetPadding();
    });

    testWidgets('TemplateDetailScreen bottom CTA is enclosed in SafeArea above bottom bar',
        (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 48);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TemplateDetailScreen(templateId: 'temp_travel'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final ctaFinder = find.text('Use Template & Edit');
      expect(ctaFinder, findsOneWidget);

      final safeAreaFinder = find.ancestor(
        of: ctaFinder,
        matching: find.byType(SafeArea),
      );
      expect(safeAreaFinder, findsOneWidget);

      final safeArea = tester.widget<SafeArea>(safeAreaFinder);
      expect(safeArea.bottom, isTrue);

      final ctaRect = tester.getRect(ctaFinder);
      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
      final bottomInset = tester.view.padding.bottom / tester.view.devicePixelRatio;
      expect(ctaRect.bottom, lessThan(screenSize.height - bottomInset));

      tester.view.resetPadding();
    });

    testWidgets('AutoCaptionScreen bottomSheet CTA is enclosed in SafeArea above bottom bar',
        (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 48);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AutoCaptionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final ctaFinder = find.text('Generate Captions');
      expect(ctaFinder, findsOneWidget);

      final safeAreaFinder = find.ancestor(
        of: ctaFinder,
        matching: find.byType(SafeArea),
      );
      expect(safeAreaFinder, findsOneWidget);

      final safeArea = tester.widget<SafeArea>(safeAreaFinder);
      expect(safeArea.bottom, isTrue);

      final ctaRect = tester.getRect(ctaFinder);
      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
      final bottomInset = tester.view.padding.bottom / tester.view.devicePixelRatio;
      expect(ctaRect.bottom, lessThan(screenSize.height - bottomInset));

      tester.view.resetPadding();
    });

    testWidgets('NewProjectModal includes SafeArea preventing bottom navigation overlap',
        (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 48);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NewProjectModal(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final safeAreaFinder = find.descendant(
        of: find.byType(NewProjectModal),
        matching: find.byType(SafeArea),
      );
      expect(safeAreaFinder, findsOneWidget);

      final safeArea = tester.widget<SafeArea>(safeAreaFinder);
      expect(safeArea.bottom, isTrue);

      final sampleOptionFinder = find.text('Sample Photo');
      expect(sampleOptionFinder, findsOneWidget);

      final optionRect = tester.getRect(sampleOptionFinder);
      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
      final bottomInset = tester.view.padding.bottom / tester.view.devicePixelRatio;
      expect(optionRect.bottom, lessThan(screenSize.height - bottomInset));

      tester.view.resetPadding();
    });
  });
}
