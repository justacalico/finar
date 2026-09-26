import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Frosted bar used for the mini player, overlay controls and floating
/// headers. Translucent fill + blur, consistent across the app.
class GlassBar extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;

  const GlassBar({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(dim(borderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding:
              padding ??
              EdgeInsets.symmetric(horizontal: dim(16), vertical: dim(10)),
          decoration: BoxDecoration(
            color: (dark ? Colors.black : Colors.white).withValues(
              alpha: dark ? 0.55 : 0.7,
            ),
            borderRadius: BorderRadius.circular(dim(borderRadius)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: dim(0.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
