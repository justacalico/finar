import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MediaImage extends StatelessWidget {
  const MediaImage({
    super.key,
    this.url,
    this.icon = Icons.movie_outlined,
    this.fit = BoxFit.cover,
    this.borderRadius = 10,
  });

  final Uri? url;
  final IconData icon;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(icon, size: 32, color: scheme.outline),
      ),
    );
    final imageUrl = url?.toString();
    if (imageUrl == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}
