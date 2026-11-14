import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/theme/app_colors.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';

/// An inline Native Ad formatted in the size of an inline banner,
/// occupying the complete width of the screen directly above the CTA / bottom bar.
/// Shows a themed shimmer placeholder until the Google Mobile Ads NativeAd loads.
class InlineNativeBannerAd extends StatefulWidget {
  final EdgeInsetsGeometry margin;

  const InlineNativeBannerAd({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 6),
  });

  /// Standard height for the inline native banner to ensure CTA button is never clipped
  static const double bannerHeight = 106.0;

  /// Google AdMob official test ad unit ID for Native Ads (Native Advanced)
  /// dynamically fetched from Firebase Remote Config
  static String get testAdUnitId {
    try {
      final remoteId =
          FirebaseRemoteConfigService.instance.getNativeAdUnitId();
      if (remoteId.isNotEmpty) return remoteId;
    } catch (_) {}
    if (!kIsWeb && Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/3986624511'; // Official iOS test native ad ID
    }
    return 'ca-app-pub-3940256099942544/2247696110'; // Official Android test native ad ID
  }

  // Preloaded NativeAd cache for immediate presentation right after splash
  static NativeAd? preloadedNativeAd;
  static bool isPreloadedAdReady = false;

  /// Eagerly preloads a NativeAd during splash screen so it displays immediately on arrival
  static Future<void> preload() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (preloadedNativeAd != null) return;

    try {
      await MobileAds.instance.initialize();
      final adUnitId = InlineNativeBannerAd.testAdUnitId;
      debugPrint("[AdUnit] NativeAd preload requested with id: $adUnitId");
      preloadedNativeAd = NativeAd(
        adUnitId: adUnitId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint("Google Mobile Ads: Preloaded NativeAd loaded successfully");
            isPreloadedAdReady = true;
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint("Google Mobile Ads: Preloaded NativeAd failed to load: $error");
            ad.dispose();
            preloadedNativeAd = null;
            isPreloadedAdReady = false;
          },
          onPaidEvent: (ad, valueMicros, precision, currencyCode) {
            FirebaseAnalyticsService.instance.logOnPaidAdImpression(
              ad: ad,
              valueMicros: valueMicros,
              precision: precision,
              currencyCode: currencyCode,
              adFormat: 'native',
            );
          },
        ),
        nativeTemplateStyle: _buildNativeTemplateStyle(),
      );
      await preloadedNativeAd!.load();
    } catch (e) {
      debugPrint("Error preloading NativeAd: $e");
    }
  }

  static NativeTemplateStyle _buildNativeTemplateStyle() {
    return NativeTemplateStyle(
      templateType: TemplateType.small,
      mainBackgroundColor: AppColors.cardSurface,
      cornerRadius: 0.0,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        backgroundColor: AppColors.brandPink,
        style: NativeTemplateFontStyle.bold,
        size: 13.0,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: Colors.white,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.bold,
        size: 13.0,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.textSecondary,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.normal,
        size: 11.0,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: AppColors.textMuted,
        backgroundColor: Colors.transparent,
        style: NativeTemplateFontStyle.normal,
        size: 10.0,
      ),
    );
  }

  @override
  State<InlineNativeBannerAd> createState() => _InlineNativeBannerAdState();
}

class _InlineNativeBannerAdState extends State<InlineNativeBannerAd>
    with SingleTickerProviderStateMixin {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  late final AnimationController _shimmerController;

  bool get _isTestBinding => WidgetsBinding.instance.runtimeType
      .toString()
      .contains('TestWidgetsFlutterBinding');

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (InlineNativeBannerAd.isPreloadedAdReady &&
        InlineNativeBannerAd.preloadedNativeAd != null) {
      _nativeAd = InlineNativeBannerAd.preloadedNativeAd;
      InlineNativeBannerAd.preloadedNativeAd = null;
      InlineNativeBannerAd.isPreloadedAdReady = false;
      _isAdLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint("[AdUnit] NativeAd on screen '${_screenName()}' shown from preload, id: ${_nativeAd?.adUnitId}");
        }
      });
      // Preload next ad in background
      InlineNativeBannerAd.preload();
    } else {
      if (!_isTestBinding) {
        _shimmerController.repeat();
      } else {
        _shimmerController.value = 0.5;
      }
      _loadNativeAd();
    }
  }

  Future<void> _loadNativeAd() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await MobileAds.instance.initialize();
        if (!mounted) return;
        final adUnitId = InlineNativeBannerAd.testAdUnitId;
        debugPrint("[AdUnit] NativeAd on screen '${_screenName()}' requested with id: $adUnitId");

        _nativeAd = NativeAd(
          adUnitId: adUnitId,
          request: const AdRequest(),
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              if (!mounted) return;
              _shimmerController.stop();
              setState(() {
                _isAdLoaded = true;
              });
              FirebaseAnalyticsService.instance.logAdImpression(
                adFormat: 'native',
                adUnitId: ad.adUnitId,
              );
            },
            onAdFailedToLoad: (ad, error) {
              debugPrint("InlineNativeBannerAd failed to load: $error");
              ad.dispose();
              if (identical(_nativeAd, ad)) _nativeAd = null; // avoid double dispose
              if (!mounted) return;
              // Shimmer kept animating at 60fps forever after a failed load.
              _shimmerController.stop();
              setState(() {
                _isAdLoaded = false;
              });
            },
            onPaidEvent: (ad, valueMicros, precision, currencyCode) {
              FirebaseAnalyticsService.instance.logOnPaidAdImpression(
                ad: ad,
                valueMicros: valueMicros,
                precision: precision,
                currencyCode: currencyCode,
                adFormat: 'native',
              );
            },
          ),
          nativeTemplateStyle: InlineNativeBannerAd._buildNativeTemplateStyle(),
        );

        await _nativeAd?.load();
      }
    } catch (e) {
      debugPrint("InlineNativeBannerAd init error: $e");
    }
  }

  String _screenName() =>
      ModalRoute.of(context)?.settings.name ?? widget.margin.toString();

  @override
  void dispose() {
    _shimmerController.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('inline_native_banner_ad'),
      width: double.infinity,
      margin: widget.margin,
      child: _buildNativeAdContent(),
    );
  }

  Widget _buildNativeAdContent() {
    if (_isAdLoaded && _nativeAd != null) {
      return Container(
        width: double.infinity,
        height: InlineNativeBannerAd.bannerHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: Border(
            top: BorderSide(
                color: AppColors.cardBorder.withValues(alpha: 0.6), width: 0.8),
            bottom: BorderSide(
                color: AppColors.cardBorder.withValues(alpha: 0.6), width: 0.8),
          ),
        ),
        child: AdWidget(ad: _nativeAd!),
      );
    }

    return _buildShimmerPlaceholder();
  }

  Widget _buildShimmerPlaceholder() {
    return RepaintBoundary(
      child: AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final t = _shimmerController.value;
        final slide = -1.6 + (t * 3.2);
        final baseGradient = LinearGradient(
          begin: Alignment(slide - 0.8, -0.2),
          end: Alignment(slide + 0.8, 0.2),
          colors: const [
            Color(0xFF1D1D2D),
            Color(0xFF2D2D46),
            Color(0xFF1D1D2D),
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        final ctaGradient = LinearGradient(
          begin: Alignment(slide - 0.8, -0.2),
          end: Alignment(slide + 0.8, 0.2),
          colors: [
            AppColors.brandPink.withValues(alpha: 0.16),
            AppColors.brandPink.withValues(alpha: 0.34),
            AppColors.brandPink.withValues(alpha: 0.16),
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        return Container(
          key: const ValueKey('banner_ad_shimmer'),
          width: double.infinity,
          height: InlineNativeBannerAd.bannerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            border: Border(
              top: BorderSide(
                  color: AppColors.cardBorder.withValues(alpha: 0.7),
                  width: 0.8),
              bottom: BorderSide(
                  color: AppColors.cardBorder.withValues(alpha: 0.7),
                  width: 0.8),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shimmer icon placeholder
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: baseGradient,
                  border: Border.all(
                    color: AppColors.cardBorder.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Shimmer headline & subtitle lines
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.62,
                      child: Container(
                        height: 13,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: baseGradient,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FractionallySizedBox(
                      widthFactor: 0.92,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          gradient: baseGradient,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FractionallySizedBox(
                      widthFactor: 0.48,
                      child: Container(
                        height: 9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4.5),
                          gradient: baseGradient,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Shimmer CTA pill placeholder
              Container(
                width: 82,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: ctaGradient,
                  border: Border.all(
                    color: AppColors.brandPink.withValues(alpha: 0.28),
                    width: 0.8,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      ),
    );
  }
}
