import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../services/connectivity_service.dart';

class NoInternetDialog extends StatefulWidget {
  final VoidCallback? onDismiss;
  final Future<bool> Function()? onRetry;

  const NoInternetDialog({
    super.key,
    this.onDismiss,
    this.onRetry,
  });

  @override
  State<NoInternetDialog> createState() => _NoInternetDialogState();
}

class _NoInternetDialogState extends State<NoInternetDialog>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
    });

    bool isOnline = false;
    if (widget.onRetry != null) {
      isOnline = await widget.onRetry!();
    } else {
      isOnline = await ConnectivityService.instance.checkRealConnection();
    }

    if (!mounted) return;
    setState(() {
      _isChecking = false;
    });

    if (isOnline) {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      } else {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              SizedBox(width: 10),
              Text("Back online! Connection restored.",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: Color(0xFF161622),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Still offline. Please check your network settings."),
          backgroundColor: Color(0xFF221122),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents accidental back button dismissal while offline
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E1E2E),
                  Color(0xFF13131F),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.brandPink.withOpacity(0.4),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPink.withOpacity(0.2),
                  blurRadius: 36,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Animated Disconnected Icon
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandPink.withOpacity(0.12),
                      border: Border.all(
                        color: AppColors.brandPink.withOpacity(0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPink.withOpacity(0.35),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.wifi_off_rounded,
                        color: AppColors.brandPink,
                        size: 42,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Title
                Text(
                  "No Internet Connection",
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Subtitle Description
                Text(
                  "An active internet connection is required to sync assets, generate AI features, and load trending templates.",
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // Network Offline Status Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Device Offline",
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // Action Buttons
                // 1. Primary "Try Again" Button
                ElevatedButton(
                  onPressed: _isChecking ? null : _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: AppColors.brandPink.withOpacity(0.5),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Try Again",
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
