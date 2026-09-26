import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Scales the UI itself rather than magnifying the frame. Text grows
/// through textScaler and every dimension token (Insets, Radii, dim)
/// multiplies by the factor, so the layout stays the same while the
/// interface gets denser or roomier.
class UiScaler extends StatelessWidget {
  final double scale;
  final Widget child;

  const UiScaler({super.key, required this.scale, required this.child});

  @override
  Widget build(BuildContext context) {
    // Set before children build so the dimension getters below pick
    // up the factor.
    uiScaleFactor = scale;
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );
  }
}
