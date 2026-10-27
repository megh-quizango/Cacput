import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capcut2/screens/onboarding/onboarding_wrapper_screen.dart';
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

    testWidgets('Native ad occupies complete screen width, has ample height, and CTA is not clipped at bottom',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingWrapperScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify the inline native ad widget is found
      final adFinder = find.byType(InlineNativeBannerAd);
      expect(adFinder, findsOneWidget);

      // 2. Verify "Ad" attribution badge is displayed
      expect(find.text('Ad'), findsOneWidget);

      // 3. Verify "Continue" button is found
      final continueButtonFinder = find.text('Continue');
      expect(continueButtonFinder, findsOneWidget);

      // 4. Verify the native ad is placed directly above the Continue button
      final adRect = tester.getRect(adFinder);
      final buttonRect = tester.getRect(continueButtonFinder);
      expect(adRect.bottom, lessThanOrEqualTo(buttonRect.top));

      // 5. Verify the native ad occupies the complete screen width (edge-to-edge)
      final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(adRect.width, equals(screenWidth));
      expect(adRect.left, equals(0.0));
      expect(adRect.right, equals(screenWidth));

      // 6. Verify native ad has slightly larger banner height (106dp banner + 6dp bottom margin = 112dp)
      expect(adRect.height, equals(InlineNativeBannerAd.bannerHeight + 6.0));
      expect(adRect.height, greaterThanOrEqualTo(90.0));
      expect(adRect.height, lessThanOrEqualTo(125.0));

      // 7. Verify the CTA button ("Install") is fully positioned within the ad container and not clipped at bottom
      final ctaFinder = find.text('Install');
      expect(ctaFinder, findsOneWidget);
      final ctaRect = tester.getRect(ctaFinder);
      expect(ctaRect.top, greaterThanOrEqualTo(adRect.top));
      expect(ctaRect.bottom, lessThanOrEqualTo(adRect.bottom));
      expect(adRect.bottom - ctaRect.bottom, greaterThanOrEqualTo(8.0)); // Ample margin from bottom edge
    });
  });
}
