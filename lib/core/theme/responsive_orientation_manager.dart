import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResponsiveOrientationHelper {
  /// Defines the breakpoint (600dp) for distinguishing phones from tablets/large screens
  static const double mobileBreakpoint = 600.0;

  /// Returns true if the device is a mobile phone (shortest side < 600dp)
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide < mobileBreakpoint;
  }

  /// Returns true if the device is a tablet or large screen device (shortest side >= 600dp)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= mobileBreakpoint;
  }

  /// Enforces orientation lock: Portrait only for mobile; unlocked for tablets and large screens
  static void enforce(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    if (shortestSide < mobileBreakpoint) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// Initial platform view check before first build
  static void enforceFromPlatformDispatcher() {
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    if (view != null) {
      final physicalSize = view.physicalSize;
      final pixelRatio = view.devicePixelRatio;
      if (pixelRatio > 0) {
        final shortestSide = physicalSize.shortestSide / pixelRatio;
        if (shortestSide < mobileBreakpoint) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      }
    }
  }
}

/// Global widget manager that monitors window metrics and guarantees each screen follows orientation locking
class ResponsiveOrientationManager extends StatefulWidget {
  final Widget child;

  const ResponsiveOrientationManager({
    super.key,
    required this.child,
  });

  @override
  State<ResponsiveOrientationManager> createState() =>
      _ResponsiveOrientationManagerState();
}

class _ResponsiveOrientationManagerState
    extends State<ResponsiveOrientationManager> with WidgetsBindingObserver {
  bool? _wasMobile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ResponsiveOrientationHelper.enforceFromPlatformDispatcher();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Re-evaluate when window metrics, foldables, or display modes change
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    if (view != null && view.devicePixelRatio > 0) {
      final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
      final isMobile = shortestSide < ResponsiveOrientationHelper.mobileBreakpoint;
      if (_wasMobile != isMobile) {
        _wasMobile = isMobile;
        _applyOrientations(isMobile);
      }
    }
  }

  void _applyOrientations(bool isMobile) {
    if (isMobile) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final isMobile = shortestSide < ResponsiveOrientationHelper.mobileBreakpoint;
    if (_wasMobile != isMobile) {
      _wasMobile = isMobile;
      _applyOrientations(isMobile);
    }

    return widget.child;
  }
}

/// Route observer to re-enforce orientation rules each time a screen route is loaded
class OrientationLockRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _check();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _check();
  }

  void _check() {
    ResponsiveOrientationHelper.enforceFromPlatformDispatcher();
  }
}
