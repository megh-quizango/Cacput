import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capcut2/screens/shell/main_shell_screen.dart';
import 'package:capcut2/screens/home/home_dashboard_screen.dart';
import 'package:capcut2/widgets/inline_native_banner_ad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home Screen Inline Native Ad Tests', () {
    testWidgets('Home screen includes InlineNativeBannerAd occupying full width directly above bottom nav bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainShellScreen(initialIndex: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Home tab is active and InlineNativeBannerAd is present on Home screen
      final adFinder = find.byType(InlineNativeBannerAd);
      expect(adFinder, findsOneWidget);

      // 2. Verify "Ad" attribution badge and "Install" CTA are rendered
      expect(find.text('Ad'), findsOneWidget);
      final ctaFinder = find.text('Install');
      expect(ctaFinder, findsOneWidget);

      // 3. Verify the native ad is placed directly above the app bottom navigation bar
      final navBarFinder = find.byKey(const ValueKey('bottom_nav_safe_area'));
      expect(navBarFinder, findsOneWidget);

      final adRect = tester.getRect(adFinder);
      final navBarRect = tester.getRect(navBarFinder);

      // The ad bottom should be right at or above the bottom nav bar top
      expect(adRect.bottom, lessThanOrEqualTo(navBarRect.top));

      // 4. Verify the native ad occupies the complete screen width (edge-to-edge)
      final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(adRect.width, equals(screenWidth));
      expect(adRect.left, equals(0.0));
      expect(adRect.right, equals(screenWidth));

      // 5. Verify the CTA button is fully inside the ad and not clipped at bottom
      final ctaRect = tester.getRect(ctaFinder);
      expect(ctaRect.top, greaterThanOrEqualTo(adRect.top));
      expect(ctaRect.bottom, lessThanOrEqualTo(adRect.bottom));
      expect(adRect.bottom - ctaRect.bottom, greaterThanOrEqualTo(8.0));

      // 6. Verify switching to another tab hides the home screen ad (it goes offstage)
      final exploreTabFinder = find.descendant(
        of: navBarFinder,
        matching: find.text('Explore'),
      );
      await tester.tap(exploreTabFinder);
      await tester.pumpAndSettle();

      // When on Explore tab, the ad should be offstage (not visible on screen)
      expect(find.byType(InlineNativeBannerAd, skipOffstage: true), findsNothing);

      // 7. Switching back to Home tab brings the ad back on stage
      final homeTabFinder = find.descendant(
        of: navBarFinder,
        matching: find.text('Home'),
      );
      await tester.tap(homeTabFinder);
      await tester.pumpAndSettle();

      expect(find.byType(InlineNativeBannerAd, skipOffstage: true), findsOneWidget);
      expect(find.text('Google Mobile Ads'), findsOneWidget);
    });

    testWidgets('HomeDashboardScreen standalone renders InlineNativeBannerAd in bottomNavigationBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final adFinder = find.byType(InlineNativeBannerAd);
      expect(adFinder, findsOneWidget);
      expect(find.text('Ad'), findsOneWidget);
      expect(find.text('Install'), findsOneWidget);
    });
  });
}
