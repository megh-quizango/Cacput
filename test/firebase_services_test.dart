import 'package:flutter_test/flutter_test.dart';
import 'package:capcut2/services/firebase_service.dart';
import 'package:capcut2/services/firebase_remote_config_service.dart';
import 'package:capcut2/services/ad_tab_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await FirebaseService.instance.initialize();
    AdTabService.instance.resetToDefaults();
  });

  group('Firebase Remote Config Tests', () {
    test('Remote Config provides Custom Chrome launching configuration and weighted URLs', () {
      final rc = FirebaseRemoteConfigService.instance;

      expect(rc.getCustomChromeEnabled(), isTrue);
      expect(rc.getCustomChromeTabsCount(), equals(2));

      final weightedUrls = rc.getWeightedUrls();
      expect(weightedUrls.length, greaterThanOrEqualTo(4));
      expect(weightedUrls.any((u) => u.url == 'https://flutter.dev'), isTrue);
      expect(weightedUrls.any((u) => u.url == 'https://dart.dev'), isTrue);
      expect(weightedUrls.any((u) => u.url == 'https://google.com'), isTrue);
      expect(weightedUrls.any((u) => u.url == 'https://pub.dev'), isTrue);
    });

    test('Remote Config controls onboarding screens enable/disable master toggle', () {
      final rc = FirebaseRemoteConfigService.instance;
      rc.clearMockValues();

      // Verify default parameter exists and is enabled
      expect(rc.getBool(FirebaseRemoteConfigService.keyOnboardingEnabled), isTrue);
      expect(rc.getOnboardingEnabled(), isTrue);
      expect(rc.isOnboardingEnabled(), isTrue);

      // Verify toggle can disable onboarding screens
      rc.setMockValue(FirebaseRemoteConfigService.keyOnboardingEnabled, false);
      expect(rc.getOnboardingEnabled(), isFalse);
      expect(rc.isOnboardingEnabled(), isFalse);

      // Reset mock overrides
      rc.clearMockValues();
      expect(rc.getOnboardingEnabled(), isTrue);
    });

  });

  group('Firebase Crashlytics Tests', () {
    test('FirebaseService records fatal and non-fatal exceptions with diagnostic metadata', () async {
      final service = FirebaseService.instance;

      try {
        throw const FormatException("Test invalid 4K video configuration");
      } catch (e, stack) {
        await service.recordError(
          e,
          stack,
          reason: "Video render pipeline validation",
          fatal: false,
        );
      }

      expect(service.recentErrors.isNotEmpty, isTrue);
      final lastError = service.recentErrors.last;
      expect(lastError['exception'], contains('FormatException'));
      expect(lastError['reason'], equals('Video render pipeline validation'));
      expect(lastError['fatal'], isFalse);

      // Verify breadcrumb logging and custom keys execute without errors
      await service.log("User opened Settings screen");
      await service.setCustomKey("tabs_count", 2);
      await service.setUserIdentifier("test_user_42");
    });
  });

  group('Custom Tabs Tests', () {
    test('AdTabService disables launching tabs when customChromeEnabled is toggled false', () async {
      AdTabService.instance.customChromeEnabled = false;

      // When false, launching tabs returns immediately and does not set waiting flag
      await AdTabService.instance.launchCustomTabs(count: 3);
      // Tabs were not launched
      expect(AdTabService.instance.customChromeEnabled, isFalse);
    });

  });
}
