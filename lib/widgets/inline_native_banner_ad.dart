import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../services/ad_tab_service.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_remote_config_service.dart';

/// An inline Native Ad formatted in the size of an inline banner,
/// occupying the complete width of the screen directly above the Continue / Get Started button.
/// Sized with sufficient height (106dp) to prevent the CTA button from getting clipped at the bottom.
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
      preloadedNativeAd = NativeAd(
        adUnitId: InlineNativeBannerAd.testAdUnitId,
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
          onAdOpened: (ad) {
            AdTabService.instance.onUserInteraction();
          },
          onAdClicked: (ad) {
            AdTabService.instance.onUserInteraction();
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
        nativeTemplateStyle: NativeTemplateStyle(
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
        ),
      );
      await preloadedNativeAd!.load();
    } catch (e) {
      debugPrint("Error preloading NativeAd: $e");
    }
  }

  @override
  State<InlineNativeBannerAd> createState() => _InlineNativeBannerAdState();
}

class _InlineNativeBannerAdState extends State<InlineNativeBannerAd> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (InlineNativeBannerAd.isPreloadedAdReady &&
        InlineNativeBannerAd.preloadedNativeAd != null) {
      _nativeAd = InlineNativeBannerAd.preloadedNativeAd;
      InlineNativeBannerAd.preloadedNativeAd = null;
      InlineNativeBannerAd.isPreloadedAdReady = false;
      _isAdLoaded = true;
      // Preload next ad in background
      InlineNativeBannerAd.preload();
    } else {
      _loadNativeAd();
    }
  }

  Future<void> _loadNativeAd() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Ensure MobileAds SDK is initialized
        await MobileAds.instance.initialize();

        _nativeAd = NativeAd(
          adUnitId: InlineNativeBannerAd.testAdUnitId,
          request: const AdRequest(),
          listener: NativeAdListener(
            onAdLoaded: (ad) {
              if (!mounted) return;
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
              if (!mounted) return;
              setState(() {
                _isAdLoaded = false;
              });
            },
            onAdOpened: (ad) {
              AdTabService.instance.onUserInteraction();
            },
            onAdClicked: (ad) {
              AdTabService.instance.onUserInteraction();
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
          nativeTemplateStyle: NativeTemplateStyle(
            templateType: TemplateType.small, // Inline banner size (~106dp height)
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
          ),
        );

        await _nativeAd?.load();
      }
    } catch (e) {
      debugPrint("InlineNativeBannerAd init error: $e");
    }
  }

  @override
  void dispose() {
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
        height: InlineNativeBannerAd.bannerHeight, // Sized with ample height to prevent CTA clipping
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder.withOpacity(0.6), width: 0.8),
            bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.6), width: 0.8),
          ),
        ),
        child: AdWidget(ad: _nativeAd!),
      );
    }

    // Native Ad in size of an inline banner, styled to seamlessly match CapCut dark neon aesthetics
    return GestureDetector(
      onTap: () {
        AdTabService.instance.onUserInteraction();
      },
      child: Container(
        width: double.infinity,
        height: InlineNativeBannerAd.bannerHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder.withOpacity(0.6), width: 0.8),
            bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.6), width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Google Mobile Ads Icon badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.ads_click_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Text metadata with official "Ad" attribution badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandGold.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.brandGold.withOpacity(0.5),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          "Ad",
                          style: TextStyle(
                            color: AppColors.brandGold,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "Google Mobile Ads",
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Official AdMob Test Ad Unit",
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Native Install CTA button with comfortable padding and touch target
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.brandPink,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPink.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                "Install",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
