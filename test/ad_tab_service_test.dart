import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capcut2/services/ad_tab_service.dart';
import 'package:capcut2/widgets/app_open_ad_view.dart';
import 'package:capcut2/widgets/app_exit_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdTabService & Configuration Tests', () {
    test('Can configure number of tabs (N) and toggle settings', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify initial default count
      expect(container.read(adTabConfigProvider).tabsCount, equals(2));

      // Update tabs count (N)
      container.read(adTabConfigProvider.notifier).setTabsCount(4);
      expect(container.read(adTabConfigProvider).tabsCount, equals(4));
      expect(AdTabService.instance.tabsCount, equals(4));

      // Toggle auto-launch on navigation
      container.read(adTabConfigProvider.notifier).toggleAutoLaunchOnNavigation(false);
      expect(container.read(adTabConfigProvider).autoLaunchOnNavigation, isFalse);

      // Toggle auto-launch on click
      container.read(adTabConfigProvider.notifier).toggleAutoLaunchOnClick(false);
      expect(container.read(adTabConfigProvider).autoLaunchOnClick, isFalse);

      // Toggle auto-launch on back
      container.read(adTabConfigProvider.notifier).toggleAutoLaunchOnBack(false);
      expect(container.read(adTabConfigProvider).autoLaunchOnBack, isFalse);
      container.read(adTabConfigProvider.notifier).toggleAutoLaunchOnBack(true);
      expect(container.read(adTabConfigProvider).autoLaunchOnBack, isTrue);

      // Toggle App Open Ad on resume
      container.read(adTabConfigProvider.notifier).toggleShowAdOnAppResume(true);
      expect(container.read(adTabConfigProvider).showAdOnAppResume, isTrue);

      // Restore defaults
      container.read(adTabConfigProvider.notifier).setTabsCount(2);
      container.read(adTabConfigProvider.notifier).toggleAutoLaunchOnNavigation(true);
      container.read(adTabConfigProvider.notifier).toggleAutoLaunchOnClick(true);
    });

    test('Lifecycle state transition detects app resume', () {
      AdTabService.instance.initialize();

      // Simulate app pausing (Chrome Custom Tab opened over app)
      AdTabService.instance.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Simulate app resuming (Custom Chrome Tabs closed, returning to app)
      AdTabService.instance.didChangeAppLifecycleState(AppLifecycleState.resumed);
    });

    test('Weighted URLs management and sampling distribution', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Check initial default weighted URLs
      expect(container.read(adTabConfigProvider).useWeightedUrls, isTrue);
      expect(container.read(adTabConfigProvider).weightedUrls, isNotEmpty);

      // Update a weight
      final firstId = container.read(adTabConfigProvider).weightedUrls.first.id;
      container.read(adTabConfigProvider.notifier).updateUrlWeight(firstId, 80);
      expect(
        container
            .read(adTabConfigProvider)
            .weightedUrls
            .firstWhere((w) => w.id == firstId)
            .weight,
        equals(80),
      );

      // Add a new weighted URL
      container
          .read(adTabConfigProvider.notifier)
          .addWeightedUrl('https://example.com/custom', 60);
      expect(
        container
            .read(adTabConfigProvider)
            .weightedUrls
            .any((w) => w.url == 'https://example.com/custom'),
        isTrue,
      );

      // Test selectUrl() sampling returns valid URL
      final selectedUrl = AdTabService.instance.selectUrl();
      expect(selectedUrl, isNotEmpty);
      expect(selectedUrl.startsWith('http'), isTrue);

      // Remove URL
      final addedItem = container
          .read(adTabConfigProvider)
          .weightedUrls
          .firstWhere((w) => w.url == 'https://example.com/custom');
      container.read(adTabConfigProvider.notifier).removeWeightedUrl(addedItem.id);
      expect(
        container
            .read(adTabConfigProvider)
            .weightedUrls
            .any((w) => w.url == 'https://example.com/custom'),
        isFalse,
      );

      // Reset defaults
      container.read(adTabConfigProvider.notifier).resetWeightedUrls();
      expect(container.read(adTabConfigProvider).weightedUrls.length, equals(4));
    });
  });

  group('AppOpenAdView Widget Tests', () {
    testWidgets('Renders App Open Ad with branding, countdown and dismiss actions',
        (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AppOpenAdView(
            onDismiss: () {
              dismissed = true;
            },
          ),
        ),
      );

      // Verify branding and ad labels
      expect(find.text('PhotoVideoCourse'), findsOneWidget);
      expect(find.text('Ad'), findsOneWidget);
      expect(find.text('AI Creative Studio Pro'), findsOneWidget);
      expect(find.text('Continue to App'), findsOneWidget);

      // Tap "Continue to App"
      await tester.tap(find.text('Continue to App'));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });
  });

  group('AppExitDialog Widget Tests', () {
    testWidgets('Renders Exit Dialog with theme styling and cancel/exit buttons',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppExitDialog(),
          ),
        ),
      );

      // Verify visual elements
      expect(find.byIcon(Icons.power_settings_new_rounded), findsOneWidget);
      expect(find.text('Exit PhotoVideoCourse?'), findsOneWidget);
      expect(
        find.textContaining('Are you sure you want to leave?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Exit App'), findsOneWidget);
    });

    testWidgets('Cancel button dismisses the exit dialog', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    dialogResult = await AppExitDialog.show(context);
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Exit PhotoVideoCourse?'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Exit PhotoVideoCourse?'), findsNothing);
      expect(dialogResult, isFalse);
    });
  });
}
