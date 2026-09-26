import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Aspect ratio helpers for the app's art shapes.
enum ArtShape { poster, backdrop, square, avatar }

extension ArtShapeRatio on ArtShape {
  double get ratio => switch (this) {
        ArtShape.poster => 2 / 3,
        ArtShape.backdrop => 16 / 9,
        ArtShape.square => 1,
        ArtShape.avatar => 1,
      };
}

/// Cached Jellyfin image with a consistent placeholder and error state.
class AppImage extends StatelessWidget {
  final String url;
  final ArtShape shape;
  final double borderRadius;
  final BoxFit fit;

  /// When true the image fills its parent instead of sizing by ratio.
  final bool fill;

  const AppImage(
    this.url, {
    super.key,
    this.shape = ArtShape.poster,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clipped = ClipRRect(
      borderRadius: shape == ArtShape.avatar
          ? BorderRadius.circular(999)
          : BorderRadius.circular(borderRadius),
      child: SizedBox.expand(
        child: url.isEmpty
            ? _placeholder(scheme)
            : CachedNetworkImage(
                imageUrl: url,
                fit: fit,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, __) => _placeholder(scheme),
                errorWidget: (_, __, ___) => _placeholder(scheme),
              ),
      ),
    );
    if (fill) return clipped;
    return AspectRatio(aspectRatio: shape.ratio, child: clipped);
  }

  Widget _placeholder(ColorScheme scheme) => Container(
        color: scheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            switch (shape) {
              ArtShape.poster => Icons.movie_outlined,
              ArtShape.backdrop => Icons.image_outlined,
              ArtShape.square => Icons.music_note_outlined,
              ArtShape.avatar => Icons.person_outline,
            },
            color: scheme.onSurface.withValues(alpha: 0.25),
          ),
        ),
      );
}
