import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capcut2/screens/onboarding/onboarding_wrapper_screen.dart';
import 'package:capcut2/services/ad_tab_service.dart';
import 'package:capcut2/widgets/inline_native_banner_ad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Inline Native Ad Tests', () {
    test('InlineNativeBannerAd uses official Google AdMob test ad unit ID for Native Ads', () {
      expect(InlineNativeBannerAd.testAdUnitId, isNotEmpty);
      expect(
        InlineNativeBannerAd.testAdUnitId,
        anyOf([
          equals('ca-app-pub-3940256099942544/2247696110'), // Android Native Ad test unit ID
          equals('ca-app-pub-3940256099942544/3986624511'), // iOS Native Ad test unit ID
        ]),
      );
    });

    testWidgets('Shows shimmer placeholder until native ad loads, occupying full width above Continue button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingWrapperScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify the inline native ad widget and shimmer placeholder are found
      final adFinder = find.byType(InlineNativeBannerAd);
      expect(adFinder, findsOneWidget);
      final shimmerFinder = find.byKey(const ValueKey('banner_ad_shimmer'));
      expect(shimmerFinder, findsOneWidget);

      // 2. Verify custom fake ad texts are completely removed
      expect(find.text('Google Mobile Ads'), findsNothing);
      expect(find.text('Official AdMob Test Ad Unit'), findsNothing);
      expect(find.text('Install'), findsNothing);

      // 3. Verify "Continue" button is found
      final continueButtonFinder = find.text('Continue');
      expect(continueButtonFinder, findsOneWidget);

      // 4. Verify the native ad is placed directly above the Continue button
      final adRect = tester.getRect(adFinder);
      final buttonRect = tester.getRect(continueButtonFinder);
      expect(adRect.bottom, lessThanOrEqualTo(buttonRect.top));

      // 5. Verify the native ad & shimmer occupy the complete screen width (edge-to-edge)
      final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(adRect.width, equals(screenWidth));
      expect(adRect.left, equals(0.0));
      expect(adRect.right, equals(screenWidth));

      // 6. Verify banner height (106dp banner + 6dp bottom margin = 112dp)
      expect(adRect.height, equals(InlineNativeBannerAd.bannerHeight + 6.0));
      expect(tester.getRect(shimmerFinder).height, equals(InlineNativeBannerAd.bannerHeight));
    });

    testWidgets('Tapping InlineNativeBannerAd does not launch Custom Chrome Tabs',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final calls = <MethodCall>[];
      const channel = MethodChannel('com.creativemedia.capcut/custom_tabs');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        AdTabService.instance.resetToDefaults();
      });

      try {
        AdTabService.instance.autoLaunchOnClick = true;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InlineNativeBannerAd(),
            ),
          ),
        );

        await tester.tap(find.byType(InlineNativeBannerAd));
        await tester.pump();

        expect(calls.where((c) => c.method == 'launch'), isEmpty);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
