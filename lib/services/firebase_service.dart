import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'firebase_analytics_service.dart';
import 'firebase_remote_config_service.dart';

/// Central Firebase initialization and Crashlytics management service
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes all Firebase core services, Crashlytics error handlers,
  /// Remote Config, and Analytics
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }
      _isInitialized = true;
      debugPrint("Firebase core initialized successfully");

      // Setup Crashlytics error handling
      _setupCrashlytics();

      // Initialize Remote Config & Analytics services
      await FirebaseRemoteConfigService.instance.initialize();
      await FirebaseAnalyticsService.instance.initialize();
    } catch (e) {
      debugPrint("FirebaseService initialization notice (e.g. mock test env): $e");
      // Still ensure Remote Config and Analytics defaults are initialized in mock/test envs
      await FirebaseRemoteConfigService.instance.initialize();
      await FirebaseAnalyticsService.instance.initialize();
    }
  }

  void _setupCrashlytics() {
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        // Enable automatic crash collection
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

        // Catch all fatal Flutter framework errors
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };

        // Catch all uncaught asynchronous errors
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };

        debugPrint("Firebase Crashlytics error handlers attached");
      }
    } catch (e) {
      debugPrint("Firebase Crashlytics setup notice: $e");
    }
  }

  final List<Map<String, dynamic>> _recentErrors = [];
  List<Map<String, dynamic>> get recentErrors => List.unmodifiable(_recentErrors);

  /// Manually logs a non-fatal or fatal error with optional stack trace to Crashlytics
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    _recentErrors.add({
      'exception': exception.toString(),
      'stack': stack?.toString(),
      'reason': reason?.toString(),
      'fatal': fatal,
      'timestamp': DateTime.now().toIso8601String(),
    });

    try {
      if (_isInitialized &&
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await FirebaseCrashlytics.instance.recordError(
          exception,
          stack,
          reason: reason,
          fatal: fatal,
        );
      }
    } catch (e) {
      debugPrint("Crashlytics recordError: $e");
    }
  }

  /// Logs a custom breadcrumb to Crashlytics
  Future<void> log(String message) async {
    try {
      if (_isInitialized &&
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await FirebaseCrashlytics.instance.log(message);
      }
    } catch (e) {
      debugPrint("Crashlytics log: $e");
    }
  }

  /// Sets custom key-value pair for enhanced crash diagnosis
  Future<void> setCustomKey(String key, Object value) async {
    try {
      if (_isInitialized &&
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await FirebaseCrashlytics.instance.setCustomKey(key, value);
      }
    } catch (e) {
      debugPrint("Crashlytics setCustomKey: $e");
    }
  }

  /// Sets user identifier in crash reports
  Future<void> setUserIdentifier(String identifier) async {
    try {
      if (_isInitialized &&
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
      }
    } catch (e) {
      debugPrint("Crashlytics setUserIdentifier: $e");
    }
  }
}
