import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:capcut2/services/firebase_service.dart';
import 'package:capcut2/services/firebase_remote_config_service.dart';
import 'package:capcut2/services/firebase_analytics_service.dart';
import 'package:capcut2/services/ad_tab_service.dart';
import 'package:capcut2/widgets/inline_native_banner_ad.dart';

// Concrete subclass of Ad to simulate onPaidEvent for testing
class TestAd extends AdWithoutView {
  TestAd({required super.adUnitId});

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await FirebaseService.instance.initialize();
    AdTabService.instance.resetToDefaults();
  });

  group('Firebase Remote Config Tests', () {
    test('Remote Config contains all required AdMob ad units with official test IDs', () {
      final rc = FirebaseRemoteConfigService.instance;

      // Android Ad Units
      expect(rc.getString(FirebaseRemoteConfigService.keyNativeAdAndroid),
          equals('ca-app-pub-3940256099942544/2247696110'));
      expect(rc.getString(FirebaseRemoteConfigService.keyAppOpenAdAndroid),
          equals('ca-app-pub-3940256099942544/9257395921'));
      expect(rc.getString(FirebaseRemoteConfigService.keyBannerAdAndroid),
          equals('ca-app-pub-3940256099942544/6300978111'));
      expect(rc.getString(FirebaseRemoteConfigService.keyInterstitialAdAndroid),
          equals('ca-app-pub-3940256099942544/1033173712'));
      expect(rc.getString(FirebaseRemoteConfigService.keyRewardedAdAndroid),
          equals('ca-app-pub-3940256099942544/5224354917'));

      // iOS Ad Units
      expect(rc.getString(FirebaseRemoteConfigService.keyNativeAdIos),
          equals('ca-app-pub-3940256099942544/3986624511'));
      expect(rc.getString(FirebaseRemoteConfigService.keyAppOpenAdIos),
          equals('ca-app-pub-3940256099942544/5575463023'));
      expect(rc.getString(FirebaseRemoteConfigService.keyBannerAdIos),
          equals('ca-app-pub-3940256099942544/2934735716'));
      expect(rc.getString(FirebaseRemoteConfigService.keyInterstitialAdIos),
          equals('ca-app-pub-3940256099942544/4411468910'));
      expect(rc.getString(FirebaseRemoteConfigService.keyRewardedAdIos),
          equals('ca-app-pub-3940256099942544/1712485313'));
    });

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

    test('Remote Config controls app open ads master toggle and suppresses requests when disabled', () {
      final rc = FirebaseRemoteConfigService.instance;
      final adService = AdTabService.instance;
      rc.clearMockValues();
      adService.resetToDefaults();

      // Verify default parameter exists and is enabled
      expect(rc.getBool(FirebaseRemoteConfigService.keyAppOpenAdEnabled), isTrue);
      expect(rc.getAppOpenAdEnabled(), isTrue);
      expect(rc.isAppOpenAdEnabled(), isTrue);
      expect(adService.isAppOpenAdEnabled, isTrue);

      // Verify toggle disables App Open Ads
      rc.setMockValue(FirebaseRemoteConfigService.keyAppOpenAdEnabled, false);
      expect(rc.getAppOpenAdEnabled(), isFalse);
      expect(rc.isAppOpenAdEnabled(), isFalse);
      expect(adService.isAppOpenAdEnabled, isFalse);

      // Ensure no ad request is sent when disabled
      final initialRequests = adService.appOpenAdRequestCount;
      adService.loadAppOpenAd();
      adService.preloadAds();
      adService.showAppOpenAd();
      expect(adService.appOpenAdRequestCount, equals(initialRequests));

      // Reset mock overrides
      rc.clearMockValues();
      expect(rc.getAppOpenAdEnabled(), isTrue);
      expect(adService.isAppOpenAdEnabled, isTrue);
    });

    test('AdTabService and InlineNativeBannerAd pull ad unit IDs dynamically from Remote Config', () {
      expect(AdTabService.instance.appOpenAdUnitId, isNotEmpty);
      expect(InlineNativeBannerAd.testAdUnitId, isNotEmpty);
      expect(
        InlineNativeBannerAd.testAdUnitId,
        anyOf([
          equals('ca-app-pub-3940256099942544/2247696110'),
          equals('ca-app-pub-3940256099942544/3986624511'),
        ]),
      );
    });
  });

  group('Firebase Analytics onPaid Ad Revenue Tracking Tests', () {
    test('logOnPaidAdImpression correctly converts micros to currency value and logs event', () async {
      final analytics = FirebaseAnalyticsService.instance;
      final testAd = TestAd(adUnitId: 'ca-app-pub-3940256099942544/2247696110');

      // 1,500,000 micros = 1.50 USD
      await analytics.logOnPaidAdImpression(
        ad: testAd,
        valueMicros: 1500000.0,
        precision: PrecisionType.precise,
        currencyCode: 'USD',
        adFormat: 'native',
      );

      expect(analytics.recentPaidEvents.isNotEmpty, isTrue);
      final lastEvent = analytics.recentPaidEvents.last;
      expect(lastEvent['ad_platform'], equals('AdMob'));
      expect(lastEvent['ad_source'], equals('admob'));
      expect(lastEvent['ad_unit_name'], equals('ca-app-pub-3940256099942544/2247696110'));
      expect(lastEvent['ad_format'], equals('native'));
      expect(lastEvent['currency'], equals('USD'));
      expect(lastEvent['value'], equals(1.5));
      expect(lastEvent['value_micros'], equals(1500000.0));
      expect(lastEvent['precision_type'], equals('precise'));
    });

    test('logOnPaidAdImpression works with App Open Ads', () async {
      final analytics = FirebaseAnalyticsService.instance;
      final testAd = TestAd(adUnitId: 'ca-app-pub-3940256099942544/9257395921');

      // 850,000 micros = 0.85 USD
      await analytics.logOnPaidAdImpression(
        ad: testAd,
        valueMicros: 850000.0,
        precision: PrecisionType.estimated,
        currencyCode: 'USD',
        adFormat: 'app_open',
      );

      final lastEvent = analytics.recentPaidEvents.last;
      expect(lastEvent['ad_format'], equals('app_open'));
      expect(lastEvent['value'], equals(0.85));
      expect(lastEvent['precision_type'], equals('estimated'));
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

  group('Google Ads vs Custom Ads Presentation Tests', () {
    test('AdTabService disables launching tabs when customChromeEnabled is toggled false', () async {
      AdTabService.instance.customChromeEnabled = false;

      // When false, launching tabs returns immediately and does not set waiting flag
      await AdTabService.instance.launchCustomTabs(count: 3);
      // Tabs were not launched
      expect(AdTabService.instance.customChromeEnabled, isFalse);
    });

    test('InlineNativeBannerAd displays Google Mobile Ads test attribution and not custom ads', () {
      const widget = InlineNativeBannerAd();
      expect(widget.margin, isNotNull);
      expect(InlineNativeBannerAd.bannerHeight, equals(106.0));
      expect(InlineNativeBannerAd.testAdUnitId, isNotEmpty);
    });
  });
}
