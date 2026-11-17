import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service for logging Firebase Analytics events and user engagements.
class FirebaseAnalyticsService {
  FirebaseAnalyticsService._();
  static final FirebaseAnalyticsService instance =
      FirebaseAnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes Firebase Analytics
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _isInitialized = true;
      debugPrint("Firebase Analytics initialized successfully");
    } catch (e) {
      debugPrint("Firebase Analytics initialization notice (e.g. test environment): $e");
      _isInitialized = true;
    }
  }

  /// Logs a custom Analytics event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      if (_analytics != null) {
        await _analytics!.logEvent(
          name: name,
          parameters: parameters,
        );
      }
    } catch (e) {
      debugPrint("Error logging event '$name': $e");
    }
  }

  /// Logs screen view navigation
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      if (_analytics != null) {
        await _analytics!.logScreenView(
          screenName: screenName,
          screenClass: screenClass,
        );
      }
    } catch (e) {
      debugPrint("Error logging screen view '$screenName': $e");
    }
  }
}
