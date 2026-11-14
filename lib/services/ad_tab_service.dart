import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/routing/app_router.dart';
import '../widgets/app_open_ad_view.dart';
import 'firebase_analytics_service.dart';
import 'firebase_remote_config_service.dart';

/// Model representing a URL with an assigned probability weight
class WeightedUrl {
  final String id;
  final String url;
  final int weight;

  const WeightedUrl({
    required this.id,
    required this.url,
    required this.weight,
  });

  WeightedUrl copyWith({String? url, int? weight}) {
    return WeightedUrl(
      id: id,
      url: url ?? this.url,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'weight': weight,
      };

  factory WeightedUrl.fromJson(Map<String, dynamic> json) {
    return WeightedUrl(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      url: json['url'] as String? ?? 'https://flutter.dev',
      weight: (json['weight'] as num?)?.toInt() ?? 20,
    );
  }
}

class AdTabService with WidgetsBindingObserver {
  AdTabService._();
  static final AdTabService instance = AdTabService._();

  static const MethodChannel _customTabsChannel =
      MethodChannel('com.creativemedia.capcut/custom_tabs');

  // SharedPreferences Keys
  static const String prefCustomChromeEnabled = 'ad_tab_custom_chrome_enabled';
  static const String prefTabsCount = 'ad_tab_tabs_count';
  static const String prefAutoLaunchOnNavigation =
      'ad_tab_auto_launch_on_navigation';
  static const String prefAutoLaunchOnClick = 'ad_tab_auto_launch_on_click';
  static const String prefAutoLaunchOnBack = 'ad_tab_auto_launch_on_back';
  static const String prefShowAdOnAppResume = 'ad_tab_show_ad_on_app_resume';
  static const String prefUseWeightedUrls = 'ad_tab_use_weighted_urls';
  static const String prefWeightedUrls = 'ad_tab_weighted_urls_json';

  // Configuration (persistent)
  bool customChromeEnabled = true; // Master toggle to enable/disable Custom Chrome Tabs
  int tabsCount = 2; // n number of custom chrome tabs
  bool autoLaunchOnNavigation = true;
  bool autoLaunchOnClick = true;
  bool autoLaunchOnBack = true;
  bool showAdOnAppResume = true;
  bool useWeightedUrls = true;
  bool appOpenAdEnabled = true;

  /// Returns whether App Open Ads are active, dynamically consulting Firebase Remote Config
  bool get isAppOpenAdEnabled {
    try {
      final rc = FirebaseRemoteConfigService.instance;
      // Until Remote Config is loaded the flag would read the in-app default (true); treat as disabled.
      // Same while the startup refresh is pending: the cached value may be stale.
      if ((!rc.isInitialized || rc.isRefreshPending) && rc.mockOverrides.isEmpty) {
        return false;
      }
      return rc.getAppOpenAdEnabled() && appOpenAdEnabled;
    } catch (_) {
      return appOpenAdEnabled;
    }
  }

  @visibleForTesting
  int appOpenAdRequestCount = 0;

  // Google Mobile Ads Next Gen SDK AppOpenAd instance
  AppOpenAd? _appOpenAd;
  bool _isAdLoading = false;
  bool _isAdShowing = false;
  bool _isShowingLoadingScreen = false;
  Route<void>? _loadingRoute;
  Timer? _loadingTimeoutTimer;
  bool _isWaitingForTabsToClose = false;
  bool _wasInBackground = false;
  DateTime? _lastLaunchTime;
  DateTime? _lastAdDismissedTime;

  /// Ad Unit ID fetched dynamically from Firebase Remote Config with official fallback
  String get appOpenAdUnitId {
    try {
      final remoteId =
          FirebaseRemoteConfigService.instance.getAppOpenAdUnitId();
      if (remoteId.isNotEmpty) return remoteId;
    } catch (_) {}
    if (!kIsWeb && Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/9257395921'; // Official Google App Open test unit for Android
    } else if (!kIsWeb && Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5575463023'; // Official Google App Open test unit for iOS
    }
    return 'ca-app-pub-3940256099942544/9257395921';
  }

  // Fallback test URLs
  final List<String> testUrls = [
    'https://flutter.dev',
    'https://dart.dev',
    'https://google.com',
    'https://pub.dev',
    'https://firebase.google.com',
  ];

  // Default weighted URLs
  static const List<WeightedUrl> defaultWeightedUrls = [
    WeightedUrl(id: '1', url: 'https://flutter.dev', weight: 40),
    WeightedUrl(id: '2', url: 'https://dart.dev', weight: 25),
    WeightedUrl(id: '3', url: 'https://google.com', weight: 20),
    WeightedUrl(id: '4', url: 'https://pub.dev', weight: 15),
  ];

  late List<WeightedUrl> weightedUrls = List.from(defaultWeightedUrls);

  int _roundRobinIndex = 0;
  final math.Random _random = math.Random();

  /// Loads configuration from persistent local storage
  Future<void> loadPersistedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(prefCustomChromeEnabled)) {
        customChromeEnabled = prefs.getBool(prefCustomChromeEnabled) ?? true;
      }
      if (prefs.containsKey(prefTabsCount)) {
        tabsCount = prefs.getInt(prefTabsCount) ?? 2;
      }
      if (prefs.containsKey(prefAutoLaunchOnNavigation)) {
        autoLaunchOnNavigation =
            prefs.getBool(prefAutoLaunchOnNavigation) ?? true;
      }
      if (prefs.containsKey(prefAutoLaunchOnClick)) {
        autoLaunchOnClick = prefs.getBool(prefAutoLaunchOnClick) ?? true;
      }
      if (prefs.containsKey(prefAutoLaunchOnBack)) {
        autoLaunchOnBack = prefs.getBool(prefAutoLaunchOnBack) ?? true;
      }
      if (prefs.containsKey(prefShowAdOnAppResume)) {
        showAdOnAppResume = prefs.getBool(prefShowAdOnAppResume) ?? true;
      }
      if (prefs.containsKey(prefUseWeightedUrls)) {
        useWeightedUrls = prefs.getBool(prefUseWeightedUrls) ?? true;
      }
      if (prefs.containsKey(prefWeightedUrls)) {
        final raw = prefs.getString(prefWeightedUrls);
        if (raw != null && raw.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
          weightedUrls = decoded
              .map((e) => WeightedUrl.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("AdTabService loadPersistedSettings error: $e");
    }
  }

  /// Saves current configuration to persistent local storage
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefCustomChromeEnabled, customChromeEnabled);
      await prefs.setInt(prefTabsCount, tabsCount);
      await prefs.setBool(prefAutoLaunchOnNavigation, autoLaunchOnNavigation);
      await prefs.setBool(prefAutoLaunchOnClick, autoLaunchOnClick);
      await prefs.setBool(prefAutoLaunchOnBack, autoLaunchOnBack);
      await prefs.setBool(prefShowAdOnAppResume, showAdOnAppResume);
      await prefs.setBool(prefUseWeightedUrls, useWeightedUrls);
      final raw = jsonEncode(weightedUrls.map((e) => e.toJson()).toList());
      await prefs.setString(prefWeightedUrls, raw);
    } catch (e) {
      debugPrint("AdTabService saveSettings error: $e");
    }
  }

  /// Resets configuration to original defaults
  void resetToDefaults() {
    customChromeEnabled = true;
    tabsCount = 2;
    autoLaunchOnNavigation = true;
    autoLaunchOnClick = true;
    autoLaunchOnBack = true;
    showAdOnAppResume = true;
    useWeightedUrls = true;
    appOpenAdEnabled = true;
    appOpenAdRequestCount = 0;
    disposeAppOpenAd();
    weightedUrls = List.from(defaultWeightedUrls);
  }

  bool _isMobileAdsInitialized = false;
  bool _isObserverAdded = false;
  int _appOpenRetryCount = 0;

  Future<void> initialize({
    bool loadPrefs = true,
    bool awaitMobileAds = false,
  }) async {
    if (!_isObserverAdded) {
      // Adding twice fired lifecycle callbacks (and resume ads) twice.
      WidgetsBinding.instance.addObserver(this);
      _isObserverAdded = true;
    }
    if (loadPrefs) {
      await loadPersistedSettings();
    }
    unawaited(warmupCustomTabs());
    if (_isMobileAdsInitialized) return;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _isMobileAdsInitialized = true;
      // Do not call loadAppOpenAd() here: Remote Config may still be fetching.
      // SplashScreen calls preloadAds() after FirebaseService.initialize() completes.
      final initFuture = MobileAds.instance
          .initialize()
          .then<void>((_) {})
          .catchError((Object e) {
        _isMobileAdsInitialized = false;
        debugPrint("Google Mobile Ads initialization: $e");
      });
      if (awaitMobileAds) {
        await initFuture.timeout(
          const Duration(seconds: 4),
          onTimeout: () {},
        );
      } else {
        unawaited(initFuture);
      }
    }
  }

  /// Pre-warms Chrome Custom Tabs service and prefetches configured URLs
  Future<void> warmupCustomTabs() async {
    if (!customChromeEnabled) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    final List<String> urls;
    if (useWeightedUrls && weightedUrls.isNotEmpty) {
      final sorted = List<WeightedUrl>.from(weightedUrls)
        ..sort((a, b) => b.weight.compareTo(a.weight));
      urls = sorted.map((w) => w.url).toList();
    } else {
      urls = List<String>.from(testUrls);
    }
    if (urls.isEmpty) return;

    try {
      await _customTabsChannel.invokeMethod<void>('warmup', urls);
    } on MissingPluginException {
      // Ignored in unit/widget tests
    } catch (e) {
      debugPrint("CustomTabs warmup notice: $e");
    }
  }

  /// Disposes any loaded App Open Ad and resets loading state
  void disposeAppOpenAd() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = null;
    _isShowingLoadingScreen = false;
    _loadingRoute = null;
    _isAdShowing = false;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isAdLoading = false;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isObserverAdded = false;
    disposeAppOpenAd();
  }

  /// Selects a URL based on weighted probability distribution or round-robin
  String selectUrl() {
    if (!useWeightedUrls || weightedUrls.isEmpty) {
      if (testUrls.isEmpty) return 'https://flutter.dev';
      final url = testUrls[_roundRobinIndex % testUrls.length];
      _roundRobinIndex++;
      return url;
    }

    final validItems = weightedUrls.where((w) => w.weight > 0).toList();
    if (validItems.isEmpty) {
      return weightedUrls.first.url;
    }

    final totalWeight =
        validItems.fold<int>(0, (sum, item) => sum + item.weight);
    if (totalWeight <= 0) {
      return validItems.first.url;
    }

    final rand = _random.nextInt(totalWeight);
    int cumulative = 0;
    for (final item in validItems) {
      cumulative += item.weight;
      if (rand < cumulative) {
        return item.url;
      }
    }
    return validItems.last.url;
  }

  /// Preloads an App Open Ad via Google Mobile Ads Next Gen SDK
  void loadAppOpenAd() {
    if (!isAppOpenAdEnabled) {
      debugPrint("Google Mobile Ads: AppOpenAd disabled via Remote Config. Skipping request.");
      return;
    }
    appOpenAdRequestCount++;
    if (_isAdLoading || _appOpenAd != null) return;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    _isAdLoading = true;
    final adUnitId = appOpenAdUnitId;
    debugPrint("[AdUnit] AppOpenAd requested with id: $adUnitId");
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("Google Mobile Ads: AppOpenAd loaded successfully");
          if (!isAppOpenAdEnabled) {
            ad.dispose();
            _appOpenAd = null;
            _isAdLoading = false;
            _closeLoadingScreen(resetShowingFlag: true);
            return;
          }
          _appOpenAd = ad;
          _isAdLoading = false;
          _appOpenRetryCount = 0;
          _appOpenAd!.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            FirebaseAnalyticsService.instance.logOnPaidAdImpression(
              ad: ad,
              valueMicros: valueMicros,
              precision: precision,
              currencyCode: currencyCode,
              adFormat: 'app_open',
            );
          };
          if (_isShowingLoadingScreen) {
            _closeLoadingScreen(resetShowingFlag: false);
            _presentLoadedAppOpenAd(ad);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint("Google Mobile Ads: AppOpenAd failed to load: $error");
          _appOpenAd = null;
          _isAdLoading = false;
          if (_isShowingLoadingScreen) {
            _closeLoadingScreen(resetShowingFlag: true);
          }
          if (!isAppOpenAdEnabled) return;
          // Bounded retry with backoff: the old endless 4s loop kept requesting forever on no-fill/offline.
          if (_appOpenRetryCount >= 3) return;
          _appOpenRetryCount++;
          Future.delayed(Duration(seconds: 4 * _appOpenRetryCount), () {
            if (isAppOpenAdEnabled) {
              loadAppOpenAd();
            }
          });
        },
      ),
    );
  }

  /// Eagerly preloads Google Mobile Ads and warms Custom Chrome Tabs
  Future<void> preloadAds() async {
    unawaited(warmupCustomTabs());
    try {
      if (!isAppOpenAdEnabled) {
        debugPrint("Skipping App Open Ad preload - disabled via Remote Config.");
        return;
      }
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        loadAppOpenAd();
      }
    } catch (e) {
      debugPrint("Error preloading Google ads: $e");
    }
  }

  /// Launches n number of Custom Chrome Tabs using pre-warmed session when available
  Future<void> launchCustomTabs({int? count}) async {
    if (!customChromeEnabled) {
      debugPrint("Custom Chrome Tabs launching disabled via configuration");
      return;
    }

    final n = count ?? tabsCount;
    if (n <= 0) return;

    // Cooldown check (min 1.5 seconds between batch launches)
    final now = DateTime.now();
    if (_lastLaunchTime != null &&
        now.difference(_lastLaunchTime!) < const Duration(milliseconds: 1500)) {
      return;
    }
    _lastLaunchTime = now;
    _isWaitingForTabsToClose = true;

    for (int i = 0; i < n; i++) {
      final url = selectUrl();
      try {
        await _launchSingleCustomTab(url);
      } catch (e) {
        debugPrint("Error launching Chrome Custom Tab #$i: $e");
      }
    }
  }

  /// Opens one URL in a Chrome Custom Tab regardless of the ad-tab toggles (e.g. legal pages).
  Future<bool> openUrlInCustomTab(String url) async {
    try {
      await _launchSingleCustomTab(url);
      return true;
    } catch (e) {
      debugPrint("openUrlInCustomTab failed for $url: $e");
      return false;
    }
  }

  Future<void> _launchSingleCustomTab(String url) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final launched = await _customTabsChannel.invokeMethod<bool>(
          'launch',
          <String, Object>{'url': url, 'showTitle': true},
        );
        if (launched == true) return;
      } on MissingPluginException {
        // Fall through to url_launcher in test environments
      } catch (e) {
        debugPrint("Native CustomTabs launch fallback: $e");
      }
    }

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
  }

  /// Called whenever a navigation route changes
  void onNavigationTriggered() {
    if (!autoLaunchOnNavigation || _isAdShowing) return;
    launchCustomTabs();
  }

  /// Called on user click/interaction
  void onUserInteraction() {
    if (!autoLaunchOnClick || _isAdShowing) return;
    launchCustomTabs();
  }

  /// Called on back press or back gesture
  void onBackTriggered() {
    if (!autoLaunchOnBack || _isAdShowing) return;
    launchCustomTabs();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only a real background counts; `inactive` also fires for the notification shade,
    // system dialogs and the app-open ad itself, which triggered unwanted ads on return.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed) {
      unawaited(warmupCustomTabs());
      // User returned from background (e.g. all Custom Chrome Tabs closed)
      if ((_isWaitingForTabsToClose || _wasInBackground) &&
          !_isAdShowing &&
          showAdOnAppResume &&
          isAppOpenAdEnabled) {
        _isWaitingForTabsToClose = false;
        _wasInBackground = false;

        // Brief delay to ensure Flutter Activity is ready to present the App Open Ad
        Future.delayed(const Duration(milliseconds: 350), () {
          if (isAppOpenAdEnabled) {
            showAppOpenAd();
          }
        });
      }
    }
  }

  /// Displays the Google Mobile Ads App Open Ad, or shows a themed loading screen while loading.
  void showAppOpenAd() {
    if (!isAppOpenAdEnabled) {
      debugPrint("Google Mobile Ads: AppOpenAd disabled via Remote Config. Skipping show.");
      return;
    }
    if (_isAdShowing) return;

    // Cooldown check: don't show another ad within 2 seconds of dismissing
    final now = DateTime.now();
    if (_lastAdDismissedTime != null &&
        now.difference(_lastAdDismissedTime!) < const Duration(seconds: 2)) {
      return;
    }

    // 1. Show preloaded Google Mobile Ads AppOpenAd immediately if ready
    if (_appOpenAd != null) {
      _presentLoadedAppOpenAd(_appOpenAd!);
      return;
    }

    // 2. Otherwise show themed loading screen while fetching the real AppOpenAd
    final navState = rootNavigatorKey.currentState;
    if (navState != null && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _showLoadingScreenAndLoadAd(navState);
    } else if (isAppOpenAdEnabled) {
      loadAppOpenAd();
    }
  }

  void _presentLoadedAppOpenAd(AppOpenAd ad) {
    _isAdShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint("Google Mobile Ads: AppOpenAd showed full screen content");
        FirebaseAnalyticsService.instance.logAdImpression(
          adFormat: 'app_open',
          adUnitId: ad.adUnitId,
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint("Google Mobile Ads: AppOpenAd dismissed");
        _isAdShowing = false;
        _lastAdDismissedTime = DateTime.now();
        ad.dispose();
        _appOpenAd = null;
        if (isAppOpenAdEnabled) {
          loadAppOpenAd();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint("Google Mobile Ads: AppOpenAd failed to show: $error");
        _isAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        if (isAppOpenAdEnabled) {
          loadAppOpenAd();
        }
      },
    );
    ad.show();
  }

  void _showLoadingScreenAndLoadAd(NavigatorState navState) {
    _isAdShowing = true;
    _isShowingLoadingScreen = true;

    late final PageRouteBuilder<void> route;
    route = PageRouteBuilder<void>(
      settings: const RouteSettings(name: 'app_open_ad'),
      opaque: true,
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: AppOpenAdView(
            onDismiss: () => _closeLoadingScreen(resetShowingFlag: true),
          ),
        );
      },
    );

    _loadingRoute = route;
    navState.push(route);

    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(const Duration(seconds: 5), () {
      _closeLoadingScreen(resetShowingFlag: true);
    });

    loadAppOpenAd();
  }

  void _closeLoadingScreen({required bool resetShowingFlag}) {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = null;
    _isShowingLoadingScreen = false;

    final route = _loadingRoute;
    _loadingRoute = null;
    final navState = rootNavigatorKey.currentState;
    if (route != null && navState != null && route.isActive) {
      if (route.isCurrent) {
        navState.pop();
      } else {
        navState.removeRoute(route);
      }
    }

    if (resetShowingFlag) {
      _isAdShowing = false;
    }
  }
}

/// Navigator observer to launch Custom Chrome Tabs on route transitions and back navigation
class AdTabNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null &&
        route.settings.name != 'app_open_ad' &&
        route.settings.name != 'no_internet_dialog' &&
        route.settings.name != 'exit_dialog' &&
        route is! PopupRoute) {
      AdTabService.instance.onNavigationTriggered();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route.settings.name != 'app_open_ad' &&
        route.settings.name != 'no_internet_dialog' &&
        route.settings.name != 'exit_dialog' &&
        route is! PopupRoute) {
      AdTabService.instance.onBackTriggered();
    }
  }
}

/// State notifier for reactive UI control (settings, weighted URLs, testing controls)
class AdTabConfigState {
  final bool customChromeEnabled;
  final int tabsCount;
  final bool autoLaunchOnNavigation;
  final bool autoLaunchOnClick;
  final bool autoLaunchOnBack;
  final bool showAdOnAppResume;
  final bool useWeightedUrls;
  final List<WeightedUrl> weightedUrls;

  const AdTabConfigState({
    required this.customChromeEnabled,
    required this.tabsCount,
    required this.autoLaunchOnNavigation,
    required this.autoLaunchOnClick,
    required this.autoLaunchOnBack,
    required this.showAdOnAppResume,
    required this.useWeightedUrls,
    required this.weightedUrls,
  });
}

class AdTabConfigNotifier extends StateNotifier<AdTabConfigState> {
  AdTabConfigNotifier()
      : super(AdTabConfigState(
          customChromeEnabled: AdTabService.instance.customChromeEnabled,
          tabsCount: AdTabService.instance.tabsCount,
          autoLaunchOnNavigation: AdTabService.instance.autoLaunchOnNavigation,
          autoLaunchOnClick: AdTabService.instance.autoLaunchOnClick,
          autoLaunchOnBack: AdTabService.instance.autoLaunchOnBack,
          showAdOnAppResume: AdTabService.instance.showAdOnAppResume,
          useWeightedUrls: AdTabService.instance.useWeightedUrls,
          weightedUrls: List.from(AdTabService.instance.weightedUrls),
        ));

  /// Refreshes state from persistent storage
  Future<void> loadPersistedSettings() async {
    await AdTabService.instance.loadPersistedSettings();
    state = AdTabConfigState(
      customChromeEnabled: AdTabService.instance.customChromeEnabled,
      tabsCount: AdTabService.instance.tabsCount,
      autoLaunchOnNavigation: AdTabService.instance.autoLaunchOnNavigation,
      autoLaunchOnClick: AdTabService.instance.autoLaunchOnClick,
      autoLaunchOnBack: AdTabService.instance.autoLaunchOnBack,
      showAdOnAppResume: AdTabService.instance.showAdOnAppResume,
      useWeightedUrls: AdTabService.instance.useWeightedUrls,
      weightedUrls: List.from(AdTabService.instance.weightedUrls),
    );
  }

  void _persist() {
    AdTabService.instance.saveSettings();
    unawaited(AdTabService.instance.warmupCustomTabs());
  }

  void toggleCustomChromeEnabled(bool val) {
    AdTabService.instance.customChromeEnabled = val;
    state = AdTabConfigState(
      customChromeEnabled: val,
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: state.weightedUrls,
    );
    _persist();
  }

  void setTabsCount(int count) {
    AdTabService.instance.tabsCount = count;
    state = AdTabConfigState(
      customChromeEnabled: state.customChromeEnabled,
      tabsCount: count,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: state.weightedUrls,
    );
    _persist();
  }

  void toggleAutoLaunchOnNavigation(bool val) {
    AdTabService.instance.autoLaunchOnNavigation = val;
    state = AdTabConfigState(
      customChromeEnabled: state.customChromeEnabled,
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: val,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: state.weightedUrls,
    );
    _persist();
  }

  void toggleAutoLaunchOnClick(bool val) {
    AdTabService.instance.autoLaunchOnClick = val;
    state = AdTabConfigState(
      customChromeEnabled: state.customChromeEnabled,
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: val,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: state.weightedUrls,
    );
    _persist();
  }

  void toggleAutoLaunchOnBack(bool val) {
    AdTabService.instance.autoLaunchOnBack = val;
    state = AdTabConfigState(
      customChromeEnabled: state.customChromeEnabled,
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: val,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: state.weightedUrls,
    );
    _persist();
  }

  void toggleShowAdOnAppResume(bool val) {
    AdTabService.instance.showAdOnAppResume = val;
    state = AdTabConfigState(
      customChromeEnabled: state.customChromeEnabled,
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: val,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: state.weightedUrls,
    );
    _persist();
  }

  void toggleUseWeightedUrls(bool val) {
    AdTabService.instance.useWeightedUrls = val;
    state = AdTabConfigState(
      customChromeEnabled: state.customChromeEnabled,
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: val,
      weightedUrls: state.weightedUrls,
    );
    _persist();
  }

  void updateUrlWeight(String id, int weight) {
    final updated = state.weightedUrls.map((item) {
      if (item.id == id) {
        return item.copyWith(weight: weight.clamp(1, 100));
      }
      return item;
    }).toList();

    AdTabService.instance.weightedUrls = updated;
    state = AdTabConfigState(
      customChromeEnabled: state.customChromeEnabled,
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: updated,
    );
    _persist();
  }

  void addWeightedUrl(String url, int weight) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final updated = List<WeightedUrl>.from(state.weightedUrls)
      ..add(WeightedUrl(id: newId, url: url, weight: weight.clamp(1, 100)));

    AdTabService.instance.weightedUrls = updated;
    state = AdTabConfigState(
      customChromeEnabled: state.customChromeEnabled,
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: updated,
    );
    _persist();
  }

  void removeWeightedUrl(String id) {
    final updated = state.weightedUrls.where((item) => item.id != id).toList();
    AdTabService.instance.weightedUrls = updated;
    state = AdTabConfigState(
      customChromeEnabled: state.customChromeEnabled,
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: updated,
    );
    _persist();
  }

  void resetWeightedUrls() {
    final updated = List<WeightedUrl>.from(AdTabService.defaultWeightedUrls);
    AdTabService.instance.weightedUrls = updated;
    state = AdTabConfigState(
      customChromeEnabled: state.customChromeEnabled,
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: updated,
    );
    _persist();
  }
}

final adTabConfigProvider =
    StateNotifierProvider<AdTabConfigNotifier, AdTabConfigState>((ref) {
  return AdTabConfigNotifier();
});
