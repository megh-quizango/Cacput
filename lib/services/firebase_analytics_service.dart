import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service for logging Firebase Analytics events, specifically ad impressions,
/// revenue tracking with Google Mobile Ads onPaidEvent, and user engagements.
class FirebaseAnalyticsService {
  FirebaseAnalyticsService._();
  static final FirebaseAnalyticsService instance =
      FirebaseAnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // In-memory log of recent onPaid events for diagnostics and testing
  final List<Map<String, dynamic>> _recentPaidEvents = [];
  List<Map<String, dynamic>> get recentPaidEvents =>
      List.unmodifiable(_recentPaidEvents);

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

  /// Logs the standard `ad_impression` event with official AdMob revenue tracking
  /// from Google Mobile Ads [OnPaidEventCallback] as well as the custom `on_paid_event`.
  Future<void> logOnPaidAdImpression({
    required Ad ad,
    required double valueMicros,
    required PrecisionType precision,
    required String currencyCode,
    required String adFormat,
  }) async {
    // 1 micros = 1 / 1,000,000 unit of the given currency
    final double revenue = valueMicros / 1000000.0;
    final String unitId = ad.adUnitId;

    final eventData = {
      'ad_platform': 'AdMob',
      'ad_source': 'admob',
      'ad_unit_name': unitId,
      'ad_format': adFormat,
      'currency': currencyCode,
      'value': revenue,
      'value_micros': valueMicros,
      'precision_type': precision.name,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _recentPaidEvents.add(eventData);
    if (_recentPaidEvents.length > 50) {
      _recentPaidEvents.removeAt(0);
    }

    debugPrint(
      "AdMob onPaidEvent: format=$adFormat, revenue=$revenue $currencyCode, "
      "unit=$unitId, precision=${precision.name}",
    );

    try {
      if (_analytics != null) {
        // 1. Log standard Google Analytics ad_impression event
        await _analytics!.logAdImpression(
          adPlatform: 'AdMob',
          adSource: 'admob',
          adFormat: adFormat,
          adUnitName: unitId,
          value: revenue,
          currency: currencyCode,
          parameters: {
            'precision_type': precision.name,
            'value_micros': valueMicros,
          },
        );

        // 2. Log explicit on_paid_event for custom revenue metrics
        await _analytics!.logEvent(
          name: 'on_paid_event',
          parameters: {
            'ad_platform': 'AdMob',
            'ad_unit_id': unitId,
            'ad_format': adFormat,
            'currency': currencyCode,
            'value_micros': valueMicros,
            'revenue': revenue,
            'precision': precision.name,
          },
        );
      }
    } catch (e) {
      debugPrint("Error logging onPaidEvent to Firebase Analytics: $e");
    }
  }

  /// Logs standard ad impression without paid event value
  Future<void> logAdImpression({
    required String adFormat,
    required String adUnitId,
    String adPlatform = 'AdMob',
  }) async {
    try {
      if (_analytics != null) {
        await _analytics!.logAdImpression(
          adPlatform: adPlatform,
          adFormat: adFormat,
          adUnitName: adUnitId,
        );
      }
    } catch (e) {
      debugPrint("Error logging ad impression: $e");
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
