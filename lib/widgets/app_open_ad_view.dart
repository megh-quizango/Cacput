import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../services/ad_tab_service.dart';

class AppOpenAdView extends StatefulWidget {
  final VoidCallback onDismiss;

  const AppOpenAdView({
    super.key,
    required this.onDismiss,
  });

  @override
  State<AppOpenAdView> createState() => _AppOpenAdViewState();
}

class _AppOpenAdViewState extends State<AppOpenAdView> {
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!AdTabService.instance.isAppOpenAdEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDismiss();
      });
      return;
    }
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdTabService.instance.isAppOpenAdEnabled) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      backgroundColor: const Color(0xFF090911),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top App Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: AppColors.heroPinkGradient,
                        ),
                        child: const Icon(
                          Icons.movie_creation_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PhotoVideoCourse",
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.brandGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "Ad",
                              style: TextStyle(
                                color: AppColors.brandGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Countdown or Dismiss Button
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _countdown > 0
                                ? "Dismiss in $_countdown"
                                : "Dismiss",
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.close_rounded,
                              size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Main Sponsored Creative Banner
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPink.withOpacity(0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Creative Icon Badge
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.heroPinkGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandPink.withOpacity(0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 46,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        "AI Creative Studio Pro",
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Auto Captions, Background Eraser & 4K AI Upscaling with zero watermarks.",
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Ratings & Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.brandGold, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            "4.9",
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "• 1.2M Downloads",
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Sponsor Action Button
                      ElevatedButton(
                        onPressed: widget.onDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPink,
                          minimumSize: const Size(200, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Install Now",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Bottom Action & Ad Attribution
              ElevatedButton(
                onPressed: widget.onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardSurface,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                child: Text(
                  "Continue to App",
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Google AdMob • App Open Ad (Test Mode)",
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
