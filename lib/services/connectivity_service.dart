import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/routing/app_router.dart';
import '../widgets/no_internet_dialog.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicCheckTimer;

  bool _isOnline = true;
  bool _isDialogShowing = false;
  bool _isSimulatedOffline = false;

  bool get isOnline => !_isSimulatedOffline && _isOnline;
  bool get isDialogShowing => _isDialogShowing;

  // Notifiers / listeners
  final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(true);

  void initialize() {
    // Initial check
    checkRealConnection();

    // Listen to network changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _evaluateConnectivity(results);
    });

    // Periodic heartbeat to catch silent drops (e.g. router disconnected, captive portal)
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_isSimulatedOffline) {
        checkRealConnection();
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _periodicCheckTimer?.cancel();
    connectionNotifier.dispose();
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

    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
        _updateConnectionStatus(false);
        return false;
      }

      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 2500));
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        _updateConnectionStatus(true);
        return true;
      } else {
        _updateConnectionStatus(false);
        return false;
      }
    } on SocketException catch (_) {
      _updateConnectionStatus(false);
      return false;
    } on TimeoutException catch (_) {
      _updateConnectionStatus(false);
      return false;
    } catch (_) {
      _updateConnectionStatus(false);
      return false;
    }
  }

  void _updateConnectionStatus(bool isConnected) {
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
    if (_isDialogShowing) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      routeSettings: const RouteSettings(name: 'no_internet_dialog'),
      builder: (dialogContext) {
        return NoInternetDialog(
          onDismiss: () {
            _isDialogShowing = false;
            Navigator.of(dialogContext, rootNavigator: true).pop();
          },
          onRetry: () async {
            return await checkRealConnection();
          },
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  /// Dismisses the dialog automatically when internet connection is restored
  void _dismissNoInternetDialog() {
    if (!_isDialogShowing) return;

    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context, rootNavigator: true).popUntil((route) {
        // Pop if dialog is on top
        return route is! DialogRoute || route.settings.name != null;
      });
    }
    _isDialogShowing = false;
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
