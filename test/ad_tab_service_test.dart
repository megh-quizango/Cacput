import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capcut2/services/ad_tab_service.dart';
import 'package:capcut2/services/firebase_remote_config_service.dart';
import 'package:capcut2/widgets/app_open_ad_view.dart';
import 'package:capcut2/widgets/app_exit_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdTabService.instance.resetToDefaults();
  });

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

    test('Settings toggles, app open ad, weighted distribution, and number of tabs persist across app relaunch',
        () async {
      // 1. First session: User modifies settings in the settings screen
      final session1 = ProviderContainer();

      session1.read(adTabConfigProvider.notifier).setTabsCount(5);
      session1.read(adTabConfigProvider.notifier).toggleAutoLaunchOnNavigation(false);
      session1.read(adTabConfigProvider.notifier).toggleAutoLaunchOnClick(false);
      session1.read(adTabConfigProvider.notifier).toggleAutoLaunchOnBack(false);
      session1.read(adTabConfigProvider.notifier).toggleShowAdOnAppResume(false);
      session1.read(adTabConfigProvider.notifier).toggleUseWeightedUrls(false);
      session1.read(adTabConfigProvider.notifier).addWeightedUrl('https://mycompany.org/ad', 95);

      // Allow async SharedPreferences write to complete
      await Future.delayed(const Duration(milliseconds: 50));
      session1.dispose();

      // 2. Simulate app termination: reset in-memory singleton to defaults
      AdTabService.instance.resetToDefaults();
      expect(AdTabService.instance.tabsCount, equals(2));
      expect(AdTabService.instance.autoLaunchOnNavigation, isTrue);

      // 3. Second session: App launched again (initialize loads persistent settings)
      await AdTabService.instance.initialize();

      final session2 = ProviderContainer();
      addTearDown(session2.dispose);

      final state = session2.read(adTabConfigProvider);

      // Assert that all configured settings persisted
      expect(state.tabsCount, equals(5));
      expect(state.autoLaunchOnNavigation, isFalse);
      expect(state.autoLaunchOnClick, isFalse);
      expect(state.autoLaunchOnBack, isFalse);
      expect(state.showAdOnAppResume, isFalse);
      expect(state.useWeightedUrls, isFalse);
      expect(state.weightedUrls.any((w) => w.url == 'https://mycompany.org/ad' && w.weight == 95), isTrue);

      expect(AdTabService.instance.tabsCount, equals(5));
      expect(AdTabService.instance.autoLaunchOnNavigation, isFalse);
      expect(AdTabService.instance.autoLaunchOnClick, isFalse);
      expect(AdTabService.instance.autoLaunchOnBack, isFalse);
      expect(AdTabService.instance.showAdOnAppResume, isFalse);
      expect(AdTabService.instance.useWeightedUrls, isFalse);
    });

    test('warmupCustomTabs sorts weighted URLs and launchCustomTabs uses warmed Android channel',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final calls = <MethodCall>[];
      const channel = MethodChannel('com.creativemedia.capcut/custom_tabs');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'launch') return true;
        return null;
      });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      await AdTabService.instance.warmupCustomTabs();
      final warmupCall = calls.firstWhere((c) => c.method == 'warmup');
      final warmedUrls = List<String>.from(warmupCall.arguments as List<dynamic>);
      expect(warmedUrls.first, equals('https://flutter.dev'));
      expect(warmedUrls.length, equals(4));

      await AdTabService.instance.launchCustomTabs(count: 2);
      final launchCalls = calls.where((c) => c.method == 'launch').toList();
      expect(launchCalls.length, equals(2));
      for (final call in launchCalls) {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        expect(args['showTitle'], isTrue);
        expect((args['url'] as String).startsWith('https://'), isTrue);
      }
    });
  });

  group('AppOpenAdView Widget Tests', () {
    tearDown(() {
      FirebaseRemoteConfigService.instance.clearMockValues();
      AdTabService.instance.resetToDefaults();
    });

    testWidgets('Renders themed App Open loading screen without custom ad UI when enabled',
        (tester) async {
      bool dismissed = false;
      // App Open ads are off until Remote Config says otherwise.
      FirebaseRemoteConfigService.instance.setMockValue(
        FirebaseRemoteConfigService.keyAppOpenAdEnabled,
        true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppOpenAdView(
            onDismiss: () {
              dismissed = true;
            },
          ),
        ),
      );
      await tester.pump();

      // Verify themed loading screen is displayed
      expect(find.byKey(const ValueKey('app_open_loading_screen')), findsOneWidget);
      expect(find.text('Photo Video Course Guide'), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify custom fake ad elements are completely removed
      expect(find.text('Ad'), findsNothing);
      expect(find.text('AI Creative Studio Pro'), findsNothing);
      expect(find.text('Install Now'), findsNothing);
      expect(find.text('Continue to App'), findsNothing);
      expect(dismissed, isFalse);
    });

    testWidgets('Neither renders nor appears when App Open Ads are disabled via Remote Config',
        (tester) async {
      bool dismissed = false;

      // Disable App Open Ads via Remote Config
      FirebaseRemoteConfigService.instance.setMockValue(
        FirebaseRemoteConfigService.keyAppOpenAdEnabled,
        false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AppOpenAdView(
            onDismiss: () {
              dismissed = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Loading screen does NOT appear
      expect(find.byKey(const ValueKey('app_open_loading_screen')), findsNothing);
      expect(find.text('Photo Video Course Guide'), findsNothing);
      expect(find.text('Loading...'), findsNothing);
      expect(find.byType(Scaffold), findsNothing);
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
      expect(find.text('Exit Photo Video Course Guide?'), findsOneWidget);
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

      expect(find.text('Exit Photo Video Course Guide?'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Exit Photo Video Course Guide?'), findsNothing);
      expect(dialogResult, isFalse);
    });
  });
}
