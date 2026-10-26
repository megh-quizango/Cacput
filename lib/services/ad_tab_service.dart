import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/routing/app_router.dart';
import '../widgets/app_open_ad_view.dart';

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
}

class AdTabService with WidgetsBindingObserver {
  AdTabService._();
  static final AdTabService instance = AdTabService._();

  // Configuration
  int tabsCount = 2; // n number of custom chrome tabs
  bool autoLaunchOnNavigation = true;
  bool autoLaunchOnClick = true;
  bool autoLaunchOnBack = true;
  bool showAdOnAppResume = true;
  bool useWeightedUrls = true;

  // Google Mobile Ads Next Gen SDK AppOpenAd instance
  AppOpenAd? _appOpenAd;
  bool _isAdLoading = false;
  bool _isAdShowing = false;
  bool _isWaitingForTabsToClose = false;
  bool _wasInBackground = false;
  DateTime? _lastLaunchTime;
  DateTime? _lastAdDismissedTime;

  /// Official Google Mobile Ads Test Ad Unit IDs for App Open Ads
  String get appOpenAdUnitId {
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

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await MobileAds.instance.initialize();
        loadAppOpenAd();
      }
    } catch (e) {
      debugPrint("Google Mobile Ads initialization: $e");
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
    _appOpenAd = null;
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

    final totalWeight = validItems.fold<int>(0, (sum, item) => sum + item.weight);
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
    if (_isAdLoading || _appOpenAd != null) return;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    _isAdLoading = true;
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("Google Mobile Ads: AppOpenAd loaded successfully");
          _appOpenAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint("Google Mobile Ads: AppOpenAd failed to load: $error");
          _appOpenAd = null;
          _isAdLoading = false;
          // Retry loading after a brief delay
          Future.delayed(const Duration(seconds: 4), () {
            loadAppOpenAd();
          });
        },
      ),
    );
  }

  /// Launches n number of Custom Chrome Tabs
  Future<void> launchCustomTabs({int? count}) async {
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
        await launchUrl(
          Uri.parse(url),
          // inAppBrowserView uses Chrome Custom Tabs on Android
          mode: LaunchMode.inAppBrowserView,
          browserConfiguration: const BrowserConfiguration(showTitle: true),
        );
        // Small interval between sequential tab launches so the OS can register each Custom Tab
        if (i < n - 1) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      } catch (e) {
        debugPrint("Error launching Chrome Custom Tab #$i: $e");
      }
    }
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed) {
      // User returned from background (e.g. all Custom Chrome Tabs closed)
      if ((_isWaitingForTabsToClose || _wasInBackground) &&
          !_isAdShowing &&
          showAdOnAppResume) {
        _isWaitingForTabsToClose = false;
        _wasInBackground = false;

        // Brief delay to ensure Flutter Activity is ready to present the App Open Ad
        Future.delayed(const Duration(milliseconds: 350), () {
          showAppOpenAd();
        });
      }
    }
  }

  /// Displays the Google Mobile Ads App Open Ad
  void showAppOpenAd() {
    if (_isAdShowing) return;

    // Cooldown check: don't show another ad within 2 seconds of dismissing
    final now = DateTime.now();
    if (_lastAdDismissedTime != null &&
        now.difference(_lastAdDismissedTime!) < const Duration(seconds: 2)) {
      return;
    }

    // 1. Try showing the loaded native Google Mobile Ads Next Gen SDK AppOpenAd
    if (_appOpenAd != null) {
      _isAdShowing = true;
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint("Google Mobile Ads: AppOpenAd showed full screen content");
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint("Google Mobile Ads: AppOpenAd dismissed");
          _isAdShowing = false;
          _lastAdDismissedTime = DateTime.now();
          ad.dispose();
          _appOpenAd = null;
          loadAppOpenAd(); // Preload next App Open Ad
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint("Google Mobile Ads: AppOpenAd failed to show: $error");
          _isAdShowing = false;
          ad.dispose();
          _appOpenAd = null;
          loadAppOpenAd();
          _showFallbackAdView();
        },
      );
      _appOpenAd!.show();
      return;
    }

    // 2. If native ad is still loading, load it and show fallback view for testing
    loadAppOpenAd();
    _showFallbackAdView();
  }

  void _showFallbackAdView() {
    final context = rootNavigatorKey.currentContext;
    if (context == null || _isAdShowing) return;

    _isAdShowing = true;

    rootNavigatorKey.currentState?.push(
      PageRouteBuilder(
        settings: const RouteSettings(name: 'app_open_ad'),
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: AppOpenAdView(
              onDismiss: () {
                _isAdShowing = false;
                _lastAdDismissedTime = DateTime.now();
                Navigator.of(context).pop();
                loadAppOpenAd();
              },
            ),
          );
        },
      ),
    );
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
  final int tabsCount;
  final bool autoLaunchOnNavigation;
  final bool autoLaunchOnClick;
  final bool autoLaunchOnBack;
  final bool showAdOnAppResume;
  final bool useWeightedUrls;
  final List<WeightedUrl> weightedUrls;

  const AdTabConfigState({
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
          tabsCount: AdTabService.instance.tabsCount,
          autoLaunchOnNavigation: AdTabService.instance.autoLaunchOnNavigation,
          autoLaunchOnClick: AdTabService.instance.autoLaunchOnClick,
          autoLaunchOnBack: AdTabService.instance.autoLaunchOnBack,
          showAdOnAppResume: AdTabService.instance.showAdOnAppResume,
          useWeightedUrls: AdTabService.instance.useWeightedUrls,
          weightedUrls: List.from(AdTabService.instance.weightedUrls),
        ));

  void setTabsCount(int count) {
    AdTabService.instance.tabsCount = count;
    state = AdTabConfigState(
      tabsCount: count,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: state.weightedUrls,
    );
  }

  void toggleAutoLaunchOnNavigation(bool val) {
    AdTabService.instance.autoLaunchOnNavigation = val;
    state = AdTabConfigState(
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: val,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: state.weightedUrls,
    );
  }

  void toggleAutoLaunchOnClick(bool val) {
    AdTabService.instance.autoLaunchOnClick = val;
    state = AdTabConfigState(
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: val,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: state.weightedUrls,
    );
  }

  void toggleAutoLaunchOnBack(bool val) {
    AdTabService.instance.autoLaunchOnBack = val;
    state = AdTabConfigState(
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: val,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: state.weightedUrls,
    );
  }

  void toggleShowAdOnAppResume(bool val) {
    AdTabService.instance.showAdOnAppResume = val;
    state = AdTabConfigState(
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: val,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: state.weightedUrls,
    );
  }

  void toggleUseWeightedUrls(bool val) {
    AdTabService.instance.useWeightedUrls = val;
    state = AdTabConfigState(
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: val,
      weightedUrls: state.weightedUrls,
    );
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
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: updated,
    );
  }

  void addWeightedUrl(String url, int weight) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final updated = List<WeightedUrl>.from(state.weightedUrls)
      ..add(WeightedUrl(id: newId, url: url, weight: weight.clamp(1, 100)));

    AdTabService.instance.weightedUrls = updated;
    state = AdTabConfigState(
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: updated,
    );
  }

  void removeWeightedUrl(String id) {
    final updated = state.weightedUrls.where((item) => item.id != id).toList();
    AdTabService.instance.weightedUrls = updated;
    state = AdTabConfigState(
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: updated,
    );
  }

  void resetWeightedUrls() {
    final updated = List<WeightedUrl>.from(AdTabService.defaultWeightedUrls);
    AdTabService.instance.weightedUrls = updated;
    state = AdTabConfigState(
      tabsCount: state.tabsCount,
      autoLaunchOnNavigation: state.autoLaunchOnNavigation,
      autoLaunchOnClick: state.autoLaunchOnClick,
      autoLaunchOnBack: state.autoLaunchOnBack,
      showAdOnAppResume: state.showAdOnAppResume,
      useWeightedUrls: state.useWeightedUrls,
      weightedUrls: updated,
    );
  }
}

final adTabConfigProvider =
    StateNotifierProvider<AdTabConfigNotifier, AdTabConfigState>((ref) {
  return AdTabConfigNotifier();
});
