import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'connectivity_service.dart';

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
  static const String prefUseWeightedUrls = 'ad_tab_use_weighted_urls';
  static const String prefWeightedUrls = 'ad_tab_weighted_urls_json';

  // Configuration (persistent)
  bool customChromeEnabled = true; // Master toggle to enable/disable Custom Chrome Tabs
  int tabsCount = 2; // n number of custom chrome tabs
  bool autoLaunchOnNavigation = true;
  bool autoLaunchOnClick = true;
  bool autoLaunchOnBack = true;
  bool useWeightedUrls = true;

  /// True from launching a batch until the user is back in the app after its last tab.
  /// Blocks every other trigger meanwhile, so one action always shows exactly N tabs.
  bool _tabsOpen = false;
  bool _wentToBackground = false;
  Timer? _tabsOpenSafetyTimer;

  @visibleForTesting
  bool get tabsOpen => _tabsOpen;


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
    useWeightedUrls = true;
    weightedUrls = List.from(defaultWeightedUrls);
    _clearTabsOpen();
  }

  bool _isObserverAdded = false;

  Future<void> initialize({bool loadPrefs = true}) async {
    if (!_isObserverAdded) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverAdded = true;
    }
    if (loadPrefs) {
      await loadPersistedSettings();
    }
    unawaited(warmupCustomTabs());
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

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isObserverAdded = false;
    _clearTabsOpen();
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

  /// Shows n Custom Chrome Tabs one after another: the native side stacks one placeholder per
  /// tab, so closing a tab reveals the next one, and the app returns only after the last.
  Future<void> launchCustomTabs({int? count}) async {
    if (!customChromeEnabled) {
      debugPrint("Custom Chrome Tabs launching disabled via configuration");
      return;
    }
    final n = count ?? tabsCount;
    if (n <= 0) return;

    // One batch per user action: set before the await, so a tap and the navigation it causes
    // still give one batch. Never open tabs over the offline dialog.
    if (_tabsOpen || ConnectivityService.instance.isDialogShowing) return;
    _tabsOpen = true;
    _wentToBackground = false;

    final urls = List<String>.generate(n, (_) => selectUrl());
    bool launched = false;
    try {
      launched = await _launchBatch(urls);
    } catch (e) {
      debugPrint("Error launching Chrome Custom Tabs: $e");
    }
    if (!launched) {
      _clearTabsOpen();
      return;
    }
    // If nothing ever covered the app (launch silently dropped), unblock triggers.
    _tabsOpenSafetyTimer?.cancel();
    _tabsOpenSafetyTimer = Timer(const Duration(seconds: 3), () {
      if (!_wentToBackground) _clearTabsOpen();
    });
  }

  void _clearTabsOpen() {
    _tabsOpenSafetyTimer?.cancel();
    _tabsOpenSafetyTimer = null;
    _tabsOpen = false;
  }

  Future<bool> _launchBatch(List<String> urls) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final launched = await _customTabsChannel.invokeMethod<bool>(
          'launchBatch',
          <String, Object>{'urls': urls, 'showTitle': true},
        );
        if (launched == true) return true;
      } on MissingPluginException {
        // Fall through to url_launcher in test environments
      } catch (e) {
        debugPrint("Native CustomTabs batch fallback: $e");
      }
    }
    // Non-Android fallback: url_launcher can only open them all at once.
    var any = false;
    for (final url in urls) {
      try {
        if (await _launchViaUrlLauncher(url)) any = true;
      } catch (e) {
        debugPrint("Error launching Chrome Custom Tab $url: $e");
      }
    }
    return any;
  }

  Future<bool> _launchSingle(String url) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final launched = await _customTabsChannel.invokeMethod<bool>(
          'launch',
          <String, Object>{'url': url, 'showTitle': true},
        );
        if (launched == true) return true;
      } on MissingPluginException {
        // Fall through to url_launcher in test environments
      } catch (e) {
        debugPrint("Native CustomTabs launch fallback: $e");
      }
    }
    return _launchViaUrlLauncher(url);
  }

  /// Opens one URL in a Chrome Custom Tab regardless of the ad-tab toggles (e.g. legal pages).
  Future<bool> openUrlInCustomTab(String url) async {
    try {
      return await _launchSingle(url);
    } catch (e) {
      debugPrint("openUrlInCustomTab failed for $url: $e");
      return false;
    }
  }

  Future<bool> _launchViaUrlLauncher(String url) {
    return launchUrl(
      Uri.parse(url),
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
  }

  /// Set by the splash screen around its exit navigation when Remote Config
  /// `custom_chrome_launch_after_splash` is false.
  bool muteNavigationTrigger = false;

  /// Called whenever a navigation route changes
  void onNavigationTriggered() {
    if (!autoLaunchOnNavigation || muteNavigationTrigger) return;
    launchCustomTabs();
  }

  /// Called on user click/interaction
  void onUserInteraction() {
    if (!autoLaunchOnClick) return;
    launchCustomTabs();
  }

  /// Called on back press or back gesture
  void onBackTriggered() {
    if (!autoLaunchOnBack) return;
    launchCustomTabs();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wentToBackground = true;
    } else if (state == AppLifecycleState.resumed) {
      // The app only resumes once the last tab of the batch is closed.
      if (_wentToBackground) {
        _wentToBackground = false;
        _clearTabsOpen();
      }
      unawaited(warmupCustomTabs());
    }
  }
}

/// Navigator observer to launch Custom Chrome Tabs on route transitions and back navigation
class AdTabNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null &&
        route.settings.name != 'no_internet_dialog' &&
        route.settings.name != 'exit_dialog' &&
        route is! PopupRoute) {
      AdTabService.instance.onNavigationTriggered();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route.settings.name != 'no_internet_dialog' &&
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
  final bool useWeightedUrls;
  final List<WeightedUrl> weightedUrls;

  const AdTabConfigState({
    required this.customChromeEnabled,
    required this.tabsCount,
    required this.autoLaunchOnNavigation,
    required this.autoLaunchOnClick,
    required this.autoLaunchOnBack,
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
