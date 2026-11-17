import 'dart:async';
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'ad_tab_service.dart';

/// Firebase Remote Config Service for dynamically fetching and updating:
/// 1. Custom Chrome launching master toggle (enabled/disabled)
/// 2. Number of tabs to launch (N)
/// 3. Weighted URL distribution
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

  static const String keyOnboardingEnabled = 'onboarding_enabled';

  static const String keyPrivacyPolicyUrl = 'privacy_policy_url';
  static const String keyTermsOfServiceUrl = 'terms_of_service_url';

  static const String keyCustomChromeEnabled = 'custom_chrome_enabled';
  static const String keyCustomChromeTabsCount = 'custom_chrome_tabs_count';
  static const String keyAutoLaunchOnNavigation = 'custom_chrome_auto_launch_on_navigation';
  static const String keyAutoLaunchOnClick = 'custom_chrome_auto_launch_on_click';
  static const String keyAutoLaunchOnBack = 'custom_chrome_auto_launch_on_back';
  static const String keyLaunchAfterSplash = 'custom_chrome_launch_after_splash';
  static const String keyUseWeightedUrls = 'custom_chrome_use_weighted_urls';
  static const String keyWeightedUrlsJson = 'custom_chrome_weighted_urls_json';

  // In-app defaults
  static final Map<String, dynamic> defaultParameters = {
    keyOnboardingEnabled: true,
    keyPrivacyPolicyUrl: '', // set in Firebase Remote Config
    keyTermsOfServiceUrl: '', // set in Firebase Remote Config
    keyCustomChromeEnabled: true,
    keyCustomChromeTabsCount: 2,
    keyAutoLaunchOnNavigation: true,
    keyAutoLaunchOnClick: true,
    keyAutoLaunchOnBack: true,
    keyLaunchAfterSplash: true,
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
      final useWeights = getBool(keyUseWeightedUrls);
      final urls = getWeightedUrls();

      AdTabService.instance.customChromeEnabled = isChromeEnabled;
      AdTabService.instance.tabsCount = tabsCount;
      AdTabService.instance.autoLaunchOnNavigation = autoNav;
      AdTabService.instance.autoLaunchOnClick = autoClick;
      AdTabService.instance.autoLaunchOnBack = autoBack;
      AdTabService.instance.useWeightedUrls = useWeights;
      if (urls.isNotEmpty) {
        AdTabService.instance.weightedUrls = urls;
      }
      unawaited(AdTabService.instance.warmupCustomTabs());

      debugPrint("AdTabService synced with Remote Config (custom_chrome_enabled: $isChromeEnabled, tabs: $tabsCount)");
    } catch (e) {
      debugPrint("Remote Config sync error: $e");
    }
  }

  // --- App Flow & Feature Lookups ---

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

  /// Test builds made with --dart-define=LOCAL_CONFIG=true ignore Firebase and use the
  /// in-app defaults above (tabs on, onboarding on); TABS_COUNT fixes the tab count.
  /// Builds without the flag are fully controlled by Remote Config.
  static const bool _useLocalValues = bool.fromEnvironment('LOCAL_CONFIG');
  static const int _localTabsCount = int.fromEnvironment('TABS_COUNT', defaultValue: 2);

  /// Only the Custom Tabs and onboarding settings are pinned; legal URLs etc. stay remote.
  bool _isLocal(String key) =>
      _useLocalValues &&
      (key.startsWith('custom_chrome_') || key == keyOnboardingEnabled);


  String getString(String key) {
    if (mockOverrides.containsKey(key)) {
      return mockOverrides[key] as String;
    }
    if (_isLocal(key)) return (defaultParameters[key] as String?) ?? '';
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
    if (_isLocal(key)) return (defaultParameters[key] as bool?) ?? true;
    if (_remoteConfig != null) {
      return _remoteConfig!.getBool(key);
    }
    return (defaultParameters[key] as bool?) ?? true;
  }

  int getInt(String key) {
    if (mockOverrides.containsKey(key)) {
      return mockOverrides[key] as int;
    }
    if (_isLocal(key)) {
      return key == keyCustomChromeTabsCount
          ? _localTabsCount
          : (defaultParameters[key] as int?) ?? 2;
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
    if (_isLocal(key)) return (defaultParameters[key] as double?) ?? 0.0;
    if (_remoteConfig != null) {
      return _remoteConfig!.getDouble(key);
    }
    return (defaultParameters[key] as double?) ?? 0.0;
  }
}
