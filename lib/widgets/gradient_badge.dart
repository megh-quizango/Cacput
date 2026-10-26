import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class GradientBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final IconData? icon;

  const GradientBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius = 50,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.brandPink.withOpacity(0.18),
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor ?? AppColors.brandPink),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: textColor ?? AppColors.brandPink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
