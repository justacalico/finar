import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/app_theme.dart';
import 'glass_container.dart';

/// A card with glass morphism effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double borderRadius;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = AppTheme.radiusMd,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final card = GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.08,
      borderRadius: borderRadius,
      padding: padding,
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
