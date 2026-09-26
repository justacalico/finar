import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';
import '../providers/providers.dart';

/// Backdrop art with a bottom scrim for legible overlay text.
/// Used on the detail page and home feature slot.
class BackdropHero extends ConsumerWidget {
  final MediaItem item;
  final double height;
  final Widget? overlay;
  final Alignment overlayAlignment;

  const BackdropHero({
    super.key,
    required this.item,
    this.height = 320,
    this.overlay,
    this.overlayAlignment = Alignment.bottomLeft,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(jellyfinClientProvider);
    var url = client.backdropUrl(item, maxWidth: 1600);
    // Albums and most audio items have no backdrop; their cover is
    // the only art worth showing up here.
    if (url.isEmpty) {
      url = client.posterUrl(item, maxWidth: 1600);
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url.isNotEmpty)
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.35),
              errorWidget: (_, __, ___) => _fallback(context),
            )
          else
            _fallback(context),
          // Legibility scrim. Functional, not decorative.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.45, 1.0],
                colors: [
                  Color(0x33000000),
                  Colors.transparent,
                  Color(0xE6000000),
                ],
              ),
            ),
          ),
          if (overlay != null)
            Positioned.fill(
              child: Align(
                alignment: overlayAlignment,
                child: overlay,
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );
}
