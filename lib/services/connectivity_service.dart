import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/routing/app_router.dart';
import '../widgets/no_internet_dialog.dart';

class ConnectivityService with WidgetsBindingObserver {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicCheckTimer;

  bool _isInitialized = false;
  Future<bool>? _inFlightCheck;
  bool _isOnline = true;
  DialogRoute<void>? _dialogRoute;
  bool _isSimulatedOffline = false;

  // While the app is behind Custom Tabs (or otherwise backgrounded) Android, and Samsung's
  // battery manager in particular, cuts the app's network, so checks there give false "offline".
  bool _isForeground = true;
  bool _recheckOnResume = false;
  Timer? _resumeRecheckTimer;

  bool get isOnline => !_isSimulatedOffline && _isOnline;
  bool get isDialogShowing => _dialogRoute != null;

  // Notifiers / listeners
  final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(true);

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);

    // Initial check
    checkRealConnection();

    // Listen to network changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _evaluateConnectivity(results);
    });

    // Periodic heartbeat to catch silent drops without excessive DNS churn
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_isSimulatedOffline && _isForeground) {
        checkRealConnection();
      }
    });
  }

  void dispose() {
    _isInitialized = false;
    WidgetsBinding.instance.removeObserver(this);
    _resumeRecheckTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
    connectionNotifier.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      if (_recheckOnResume || !_isOnline) {
        _recheckOnResume = false;
        // Give the radio / Samsung network policy a moment to restore app access.
        _resumeRecheckTimer?.cancel();
        _resumeRecheckTimer = Timer(const Duration(milliseconds: 1200), () {
          if (!_isSimulatedOffline) checkRealConnection();
        });
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isForeground = false;
      _resumeRecheckTimer?.cancel();
    }
  }

  /// Evaluates network interface results from connectivity_plus
  Future<void> _evaluateConnectivity(List<ConnectivityResult> results) async {
    if (_isSimulatedOffline) return;

    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      _updateConnectionStatus(false);
    } else {
      await checkRealConnection();
    }
  }

  /// Verifies active internet connectivity via socket / DNS lookup
  Future<bool> checkRealConnection() async {
    if (_isSimulatedOffline) {
      _updateConnectionStatus(false);
      return false;
    }

    if (kIsWeb) {
      _updateConnectionStatus(true);
      return true;
    }

    if (_inFlightCheck != null) return _inFlightCheck!;

    final check = _performConnectivityCheck();
    _inFlightCheck = check;
    try {
      return await check;
    } finally {
      if (identical(_inFlightCheck, check)) {
        _inFlightCheck = null;
      }
    }
  }

  Future<bool> _performConnectivityCheck() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
        _updateConnectionStatus(false);
        return false;
      }

      // One failed lookup is not proof of being offline (DNS hiccup, Wi-Fi handover,
      // network restored just after resume): confirm with a second attempt first.
      final online = await _canResolve() ||
          (await Future<void>.delayed(const Duration(milliseconds: 1500))
              .then((_) => _canResolve()));
      _updateConnectionStatus(online);
      return online;
    } catch (_) {
      _updateConnectionStatus(false);
      return false;
    }
  }

  Future<bool> _canResolve() async {
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _updateConnectionStatus(bool isConnected) {
    // Never go offline from a check made in the background; verify again on resume instead.
    if (!isConnected && !_isForeground && !_isSimulatedOffline) {
      _recheckOnResume = true;
      return;
    }
    if (_isOnline == isConnected) return;
    _isOnline = isConnected;
    connectionNotifier.value = isConnected;

    if (!isConnected) {
      _showNoInternetDialog();
    } else {
      _dismissNoInternetDialog();
    }
  }

  /// Public method to show the No Internet Dialog immediately if needed
  void showNoInternetDialog() {
    _showNoInternetDialog();
  }

  /// Shows the No Internet Dialog globally on top of any active screen
  void _showNoInternetDialog() {
    if (_dialogRoute != null) return;

    final navigator = rootNavigatorKey.currentState;
    final context = rootNavigatorKey.currentContext;
    if (navigator == null || context == null) return;

    late final DialogRoute<void> route;
    route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      settings: const RouteSettings(name: 'no_internet_dialog'),
      builder: (_) => NoInternetDialog(
        onDismiss: _dismissNoInternetDialog,
        onRetry: checkRealConnection,
      ),
    );
    _dialogRoute = route;
    navigator.push(route).whenComplete(() {
      if (identical(_dialogRoute, route)) _dialogRoute = null;
    });
  }

  /// Removes exactly the dialog route, wherever it is in the stack. The old code popped
  /// blindly from two places (auto-restore + Retry), so the second pop removed the screen
  /// underneath: blank screen, and that page pop fired the next Custom Tabs batch.
  void _dismissNoInternetDialog() {
    final route = _dialogRoute;
    _dialogRoute = null;
    if (route == null || !route.isActive) return;
    route.navigator?.removeRoute(route);
  }

  /// Developer Testing: Simulates offline mode
  void simulateOffline() {
    _isSimulatedOffline = true;
    _updateConnectionStatus(false);
  }

  /// Developer Testing: Simulates online mode
  void simulateOnline() {
    _isSimulatedOffline = false;
    _updateConnectionStatus(true);
  }
}

/// Provider for reactive connectivity state across the app
final connectivityStatusProvider = StateProvider<bool>((ref) {
  final service = ConnectivityService.instance;
  service.connectionNotifier.addListener(() {
    ref.controller.state = service.isOnline;
  });
  return service.isOnline;
});

/// Global manager wrapping the app view hierarchy to monitor connectivity
class ConnectivityOverlayManager extends StatefulWidget {
  final Widget child;

  const ConnectivityOverlayManager({super.key, required this.child});

  @override
  State<ConnectivityOverlayManager> createState() =>
      _ConnectivityOverlayManagerState();
}

class _ConnectivityOverlayManagerState extends State<ConnectivityOverlayManager> {
  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
