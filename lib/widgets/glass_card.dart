import 'package:flutter/material.dart';
import '../theme/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.borderRadius = 12.0,
    this.blurSigma = 0.0,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ??
        Border.all(
          color: isSelected ? AppColors.accentTeal : AppColors.glassBorder,
          width: isSelected ? 1.5 : 1.0,
        );

    final effectiveBgColor = backgroundColor ??
        (isSelected
            ? AppColors.surfaceCard.withValues(alpha: 0.95)
            : AppColors.surfaceCard);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: AppColors.accentTeal.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );
  }
}
