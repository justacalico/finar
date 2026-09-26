import 'package:flutter/material.dart';

/// Browser-style zoom for the whole app. The child lays out in a
/// viewport scaled by 1/scale, then the result is scaled back to
/// fill the real window, so every element (text, spacing, images)
/// grows or shrinks together. MediaQuery is rewritten so pages see
/// the logical size they actually laid out in.
class UiScaler extends StatelessWidget {
  final double scale;
  final Widget child;

  const UiScaler({super.key, required this.scale, required this.child});

  @override
  Widget build(BuildContext context) {
    if (scale == 1.0) return child;
    final media = MediaQuery.of(context);
    final size = media.size / scale;
    return MediaQuery(
      data: media.copyWith(
        size: size,
        padding: media.padding / scale,
        viewPadding: media.viewPadding / scale,
        viewInsets: media.viewInsets / scale,
      ),
      child: ClipRect(
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }
}
