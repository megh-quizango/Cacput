import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routing/route_names.dart';
import '../../services/connectivity_service.dart';
import '../../services/ad_tab_service.dart';
import '../../services/firebase_service.dart';
import '../../services/firebase_remote_config_service.dart';
import '../../widgets/inline_native_banner_ad.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  DateTime? _startTime;
  bool _isProceeding = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // Start fully visible: the native launch screen already shows this content, so a fade-in would blink.
    _controller.value = 1.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInternetAndProceed();
    });
  }

  Future<void> _checkInternetAndProceed() async {
    final isOnline = await ConnectivityService.instance.checkRealConnection();
    if (!mounted) return;

    if (!isOnline) {
      // Internet is OFF: Splash is shown immediately with No Internet Connection Dialog!
      // SDKs are NOT loaded first.
      ConnectivityService.instance.showNoInternetDialog();

      // Listen for when internet connection is restored
      void onConnectionRestored() {
        if (ConnectivityService.instance.isOnline) {
          ConnectivityService.instance.connectionNotifier.removeListener(onConnectionRestored);
          _loadSdksAndNavigate();
        }
      }

      ConnectivityService.instance.connectionNotifier.addListener(onConnectionRestored);
    } else {
      _loadSdksAndNavigate();
    }
  }

  Future<void> _loadSdksAndNavigate() async {
    if (_isProceeding) return;
    _isProceeding = true;

    // Load cached prefs first so freshly fetched Remote Config overrides them cleanly.
    await AdTabService.instance.loadPersistedSettings();

    // Mobile Ads SDK init no longer blocks navigation (it could take up to 4s);
    // only Remote Config is awaited so ads load with the right ad unit ids.
    unawaited(AdTabService.instance.initialize(loadPrefs: false));
    await FirebaseService.instance.initialize();

    // Preload ads once the SDK is ready, off the navigation path.
    unawaited(MobileAds.instance.initialize().then((_) async {
      InlineNativeBannerAd.preload();
      // App Open ad waits for the fresh Remote Config fetch so a stale cached
      // "app_open_ad_enabled: true" can't send a request after it was disabled.
      await FirebaseRemoteConfigService.instance.waitForLatestConfig();
      AdTabService.instance.preloadAds();
    }).catchError((Object e) {
      debugPrint("Ad preload after MobileAds init failed: $e");
    }));

    // Keep splash animation smooth without adding an unnecessary long wait.
    if (_startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!);
      const minDuration = Duration(milliseconds: 900);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
    }

    if (mounted) {
      try {
        final isOnboardingEnabled =
            FirebaseRemoteConfigService.instance.getOnboardingEnabled();
        if (isOnboardingEnabled) {
          context.go(RouteNames.onboarding);
        } else {
          context.go(RouteNames.home);
        }
      } catch (e) {
        debugPrint("Navigation error from splash: $e");
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: SafeArea(
        child: Stack(
          children: [
          // Ambient neon glow in background
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandPink.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandCyan.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Central Branding elements matching Screen 01
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Logo with glowing border
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandPink.withOpacity(0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          AppConstants.appIconAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.cardSurface,
                              child: const Icon(
                                Icons.movie_filter_rounded,
                                size: 48,
                                color: AppColors.brandPink,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // "Photo Video Course Guide" title
                    Text(
                      "Photo Video Course Guide",
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // "Create. Edit. Inspire." tagline
                    Text(
                      "Create. Edit. Inspire.",
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.brandPink,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Loading indicator
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.brandPink.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
