import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class GlowingActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final double height;
  final double? width;
  final EdgeInsetsGeometry padding;

  const GlowingActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
    this.icon,
    this.color,
    this.height = 54,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.brandPink;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: isEnabled ? effectiveColor : AppColors.buttonDisabled,
        borderRadius: BorderRadius.circular(50),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: effectiveColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: isEnabled && !isLoading
              ? () {
                  HapticFeedback.lightImpact();
                  onTap?.call();
                }
              : null,
          child: Padding(
            padding: padding,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: isEnabled ? Colors.white : AppColors.buttonDisabledText),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: AppTypography.labelLarge.copyWith(
                            color: isEnabled
                                ? Colors.white
                                : AppColors.buttonDisabledText,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
