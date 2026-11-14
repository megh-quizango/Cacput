import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'ad_tab_service.dart';

/// Firebase Remote Config Service for dynamically fetching and updating:
/// 1. All Google AdMob ad units (Native, App Open, Banner, Interstitial, Rewarded)
/// 2. Custom Chrome launching master toggle (enabled/disabled)
/// 3. Number of tabs to launch (N)
/// 4. Weighted URL distribution
class FirebaseRemoteConfigService {
  FirebaseRemoteConfigService._();
  static final FirebaseRemoteConfigService instance =
      FirebaseRemoteConfigService._();

  FirebaseRemoteConfig? _remoteConfig;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void>? _backgroundRefresh;
  bool _isRefreshPending = false;

  /// True while the startup refresh is in flight and cached values may be stale.
  bool get isRefreshPending => _isRefreshPending;

  /// Completes once the startup refresh has the latest cloud values (or after [timeout]).
  /// Ads gated by Remote Config flags wait on this so a stale cached "enabled" never sends a request.
  Future<void> waitForLatestConfig({Duration timeout = const Duration(seconds: 4)}) async {
    final refresh = _backgroundRefresh;
    if (refresh == null) return;
    await refresh.timeout(timeout, onTimeout: () {});
  }

  // Remote Config Parameter Keys
  static const String keyNativeAdAndroid = 'ad_unit_native_android';
  static const String keyNativeAdIos = 'ad_unit_native_ios';
  static const String keyAppOpenAdAndroid = 'ad_unit_app_open_android';
  static const String keyAppOpenAdIos = 'ad_unit_app_open_ios';
  static const String keyBannerAdAndroid = 'ad_unit_banner_android';
  static const String keyBannerAdIos = 'ad_unit_banner_ios';
  static const String keyInterstitialAdAndroid = 'ad_unit_interstitial_android';
  static const String keyInterstitialAdIos = 'ad_unit_interstitial_ios';
  static const String keyRewardedAdAndroid = 'ad_unit_rewarded_android';
  static const String keyRewardedAdIos = 'ad_unit_rewarded_ios';

  static const String keyAppOpenAdEnabled = 'app_open_ad_enabled';
  static const String keyAppOpenAdsEnabled = 'app_open_ads_enabled';
  static const String keyOnboardingEnabled = 'onboarding_enabled';

  static const String keyPrivacyPolicyUrl = 'privacy_policy_url';
  static const String keyTermsOfServiceUrl = 'terms_of_service_url';

  static const String keyCustomChromeEnabled = 'custom_chrome_enabled';
  static const String keyCustomChromeTabsCount = 'custom_chrome_tabs_count';
  static const String keyAutoLaunchOnNavigation = 'custom_chrome_auto_launch_on_navigation';
  static const String keyAutoLaunchOnClick = 'custom_chrome_auto_launch_on_click';
  static const String keyAutoLaunchOnBack = 'custom_chrome_auto_launch_on_back';
  static const String keyShowAdOnAppResume = 'custom_chrome_show_ad_on_app_resume';
  static const String keyUseWeightedUrls = 'custom_chrome_use_weighted_urls';
  static const String keyWeightedUrlsJson = 'custom_chrome_weighted_urls_json';

  // In-app defaults
  static final Map<String, dynamic> defaultParameters = {
    keyNativeAdAndroid: 'ca-app-pub-3940256099942544/2247696110',
    keyNativeAdIos: 'ca-app-pub-3940256099942544/3986624511',
    keyAppOpenAdAndroid: 'ca-app-pub-3940256099942544/9257395921',
    keyAppOpenAdIos: 'ca-app-pub-3940256099942544/5575463023',
    keyBannerAdAndroid: 'ca-app-pub-3940256099942544/6300978111',
    keyBannerAdIos: 'ca-app-pub-3940256099942544/2934735716',
    keyInterstitialAdAndroid: 'ca-app-pub-3940256099942544/1033173712',
    keyInterstitialAdIos: 'ca-app-pub-3940256099942544/4411468910',
    keyRewardedAdAndroid: 'ca-app-pub-3940256099942544/5224354917',
    keyRewardedAdIos: 'ca-app-pub-3940256099942544/1712485313',
    keyAppOpenAdEnabled: true,
    keyOnboardingEnabled: true,
    keyPrivacyPolicyUrl: '', // set in Firebase Remote Config
    keyTermsOfServiceUrl: '', // set in Firebase Remote Config
    keyCustomChromeEnabled: true,
    keyCustomChromeTabsCount: 2,
    keyAutoLaunchOnNavigation: true,
    keyAutoLaunchOnClick: true,
    keyAutoLaunchOnBack: true,
    keyShowAdOnAppResume: true,
    keyUseWeightedUrls: true,
    keyWeightedUrlsJson: jsonEncode(
      AdTabService.defaultWeightedUrls.map((u) => u.toJson()).toList(),
    ),
  };

  /// Initializes Remote Config with in-app defaults and real-time updates
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig!.setDefaults(defaultParameters);

      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 3),
          minimumFetchInterval: Duration.zero, // Real-time fetch for latest config
        ),
      );

      // Startup: if a previous fetch succeeded, use the cached config right away and
      // refresh in the background (the real-time listener below also pushes changes).
      // Only a first launch waits on the network, so it never shows default test ad units.
      final hasCache = _remoteConfig!.lastFetchTime.millisecondsSinceEpoch > 0;
      if (hasCache) {
        await _remoteConfig!.activate();
        _isRefreshPending = true;
        _backgroundRefresh = fetchAndActivate()
            .then<void>((_) {}) // Future<void>, so timeout(onTimeout: () {}) type-checks
            .whenComplete(() => _isRefreshPending = false);
      } else {
        try {
          await _remoteConfig!.fetchAndActivate();
        } catch (e) {
          debugPrint("Remote Config fetchAndActivate notice, activating cache: $e");
          await _remoteConfig!.activate();
        }
      }
      _isInitialized = true;
      debugPrint("Firebase Remote Config initialized and activated");

      // Apply latest cloud config
      _syncToAdTabService();

      // Listen for real-time config updates pushed from Firebase Console
      _remoteConfig!.onConfigUpdated.listen((RemoteConfigUpdate event) async {
        debugPrint("Remote Config real-time update received: ${event.updatedKeys}");
        await _remoteConfig!.activate();
        _syncToAdTabService();
      });
    } catch (e) {
      debugPrint("Remote Config initialization notice: $e");
      // Fallback: apply defaults directly
      _isInitialized = true;
      _syncToAdTabService();
    }
  }

  /// Manually force a fetch and activation
  Future<bool> fetchAndActivate() async {
    if (_remoteConfig == null) return false;
    try {
      final updated = await _remoteConfig!.fetchAndActivate();
      _syncToAdTabService();
      return updated;
    } catch (e) {
      debugPrint("Remote Config fetchAndActivate error: $e");
      return false;
    }
  }

  /// Synchronizes Remote Config values into the AdTabService runtime configuration
  void _syncToAdTabService() {
    try {
      final isChromeEnabled = getCustomChromeEnabled();
      final tabsCount = getCustomChromeTabsCount();
      final autoNav = getBool(keyAutoLaunchOnNavigation);
      final autoClick = getBool(keyAutoLaunchOnClick);
      final autoBack = getBool(keyAutoLaunchOnBack);
      final showResumeAd = getBool(keyShowAdOnAppResume);
      final useWeights = getBool(keyUseWeightedUrls);
      final urls = getWeightedUrls();

      AdTabService.instance.customChromeEnabled = isChromeEnabled;
      AdTabService.instance.tabsCount = tabsCount;
      AdTabService.instance.autoLaunchOnNavigation = autoNav;
      AdTabService.instance.autoLaunchOnClick = autoClick;
      AdTabService.instance.autoLaunchOnBack = autoBack;
      AdTabService.instance.showAdOnAppResume = showResumeAd;
      AdTabService.instance.useWeightedUrls = useWeights;
      final isAppOpenEnabled = getAppOpenAdEnabled();
      AdTabService.instance.appOpenAdEnabled = isAppOpenEnabled;
      if (!isAppOpenEnabled) {
        AdTabService.instance.disposeAppOpenAd();
      }
      if (urls.isNotEmpty) {
        AdTabService.instance.weightedUrls = urls;
      }
      unawaited(AdTabService.instance.warmupCustomTabs());

      debugPrint("AdTabService synced with Remote Config (custom_chrome_enabled: $isChromeEnabled, tabs: $tabsCount)");
      logAllAdUnitIds();
    } catch (e) {
      debugPrint("Remote Config sync error: $e");
    }
  }

  // --- Ad Unit Lookups ---

  String getNativeAdUnitId() =>
      _adUnitId(!kIsWeb && Platform.isIOS ? keyNativeAdIos : keyNativeAdAndroid);

  String getAppOpenAdUnitId() =>
      _adUnitId(!kIsWeb && Platform.isIOS ? keyAppOpenAdIos : keyAppOpenAdAndroid);

  String getBannerAdUnitId() =>
      _adUnitId(!kIsWeb && Platform.isIOS ? keyBannerAdIos : keyBannerAdAndroid);

  String getInterstitialAdUnitId() =>
      _adUnitId(!kIsWeb && Platform.isIOS ? keyInterstitialAdIos : keyInterstitialAdAndroid);

  String getRewardedAdUnitId() =>
      _adUnitId(!kIsWeb && Platform.isIOS ? keyRewardedAdIos : keyRewardedAdAndroid);

  /// Resolves an ad unit id and logs where it came from (remote / in-app default / mock).
  String _adUnitId(String key) {
    final id = getString(key);
    debugPrint("[AdUnit] $key = $id (source: ${adUnitSource(key)})");
    return id;
  }

  /// 'remote' means the value came from Firebase; anything else means a fallback is in use.
  String adUnitSource(String key) {
    if (mockOverrides.containsKey(key)) return 'mock';
    final value = _remoteConfig?.getAll()[key];
    if (value == null || value.asString().isEmpty) return 'in-app default';
    switch (value.source) {
      case ValueSource.valueRemote:
        return 'remote';
      case ValueSource.valueDefault:
        return 'in-app default';
      case ValueSource.valueStatic:
        return 'static';
    }
  }

  /// Logs every active ad unit id so Remote Config values can be verified in logcat.
  void logAllAdUnitIds() {
    final keys = !kIsWeb && Platform.isIOS
        ? [keyNativeAdIos, keyAppOpenAdIos, keyBannerAdIos, keyInterstitialAdIos, keyRewardedAdIos]
        : [keyNativeAdAndroid, keyAppOpenAdAndroid, keyBannerAdAndroid, keyInterstitialAdAndroid, keyRewardedAdAndroid];
    debugPrint("[AdUnit] ---- active ad unit ids (last fetch: ${_remoteConfig?.lastFetchStatus}) ----");
    for (final key in keys) {
      debugPrint("[AdUnit] $key = ${getString(key)} (source: ${adUnitSource(key)})");
    }
  }

  // --- App Flow & Feature Lookups ---

  /// Determines if App Open Ads (both Google Mobile Ads requests and custom App Open views) are enabled.
  /// When disabled, no ad requests are sent and no custom app open ad appears.
  bool getAppOpenAdEnabled() {
    if (mockOverrides.containsKey(keyAppOpenAdEnabled)) {
      return mockOverrides[keyAppOpenAdEnabled] as bool;
    }
    if (mockOverrides.containsKey(keyAppOpenAdsEnabled)) {
      return mockOverrides[keyAppOpenAdsEnabled] as bool;
    }
    if (_remoteConfig != null) {
      final all = _remoteConfig!.getAll();
      // Prefer an explicitly fetched remote key so setting either
      // app_open_ad_enabled or app_open_ads_enabled overrides the local default.
      for (final key in [keyAppOpenAdEnabled, keyAppOpenAdsEnabled]) {
        if (all[key]?.source == ValueSource.valueRemote) {
          return _remoteConfig!.getBool(key);
        }
      }
      if (all.containsKey(keyAppOpenAdEnabled)) {
        return _remoteConfig!.getBool(keyAppOpenAdEnabled);
      }
      if (all.containsKey(keyAppOpenAdsEnabled)) {
        return _remoteConfig!.getBool(keyAppOpenAdsEnabled);
      }
    }
    return (defaultParameters[keyAppOpenAdEnabled] as bool?) ?? true;
  }

  bool isAppOpenAdEnabled() => getAppOpenAdEnabled();

  /// Determines if onboarding screens flow is enabled.
  /// When disabled, the app bypasses onboarding and navigates directly to Home.
  bool getOnboardingEnabled() {
    return getBool(keyOnboardingEnabled);
  }

  bool isOnboardingEnabled() => getOnboardingEnabled();

  // --- Legal Pages ---

  String getPrivacyPolicyUrl() => getString(keyPrivacyPolicyUrl).trim();

  String getTermsOfServiceUrl() => getString(keyTermsOfServiceUrl).trim();

  // --- Custom Chrome & Behavior Lookups ---

  bool getCustomChromeEnabled() {
    return getBool(keyCustomChromeEnabled);
  }

  int getCustomChromeTabsCount() {
    return getInt(keyCustomChromeTabsCount);
  }

  List<WeightedUrl> getWeightedUrls() {
    try {
      final raw = getString(keyWeightedUrlsJson);
      if (raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        return list.map((e) => WeightedUrl.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint("Error parsing remote config weighted URLs: $e");
    }
    return List.from(AdTabService.defaultWeightedUrls);
  }

  // --- Test & Mock Overrides ---

  @visibleForTesting
  final Map<String, dynamic> mockOverrides = {};

  @visibleForTesting
  void setMockValue(String key, dynamic value) {
    mockOverrides[key] = value;
  }

  @visibleForTesting
  void clearMockValues() {
    mockOverrides.clear();
  }

  // --- Value Getters with In-App Fallbacks ---

  String getString(String key) {
    if (mockOverrides.containsKey(key)) {
      return mockOverrides[key] as String;
    }
    if (_remoteConfig != null) {
      final val = _remoteConfig!.getString(key);
      if (val.isNotEmpty) return val;
    }
    return (defaultParameters[key] as String?) ?? '';
  }

  bool getBool(String key) {
    if (mockOverrides.containsKey(key)) {
      return mockOverrides[key] as bool;
    }
    if (_remoteConfig != null) {
      return _remoteConfig!.getBool(key);
    }
    return (defaultParameters[key] as bool?) ?? true;
  }

  int getInt(String key) {
    if (mockOverrides.containsKey(key)) {
      return mockOverrides[key] as int;
    }
    if (_remoteConfig != null) {
      final val = _remoteConfig!.getInt(key);
      if (val > 0) return val;
    }
    return (defaultParameters[key] as int?) ?? 2;
  }

  double getDouble(String key) {
    if (mockOverrides.containsKey(key)) {
      return mockOverrides[key] as double;
    }
    if (_remoteConfig != null) {
      return _remoteConfig!.getDouble(key);
    }
    return (defaultParameters[key] as double?) ?? 0.0;
  }
}
