import 'package:flutter/material.dart';

import '../core/api/models.dart';
import '../core/theme/app_theme.dart';
import '../providers/library_provider.dart';
import 'app_image.dart';
import 'media_card.dart';

/// Responsive poster grid backed by a [PagedItems] list. Loads the next
/// page when the user scrolls near the bottom. One grid for every
/// library page, see-all page, favorites and search results.
class MediaGrid extends StatelessWidget {
  final PagedItems page;
  final ArtShape shape;
  final void Function(MediaItem item)? onTap;
  final void Function(MediaItem item)? onLongPress;
  final VoidCallback? onLoadMore;
  final double minCardWidth;
  final EdgeInsets padding;

  const MediaGrid({
    super.key,
    required this.page,
    this.shape = ArtShape.poster,
    this.onTap,
    this.onLongPress,
    this.onLoadMore,
    this.minCardWidth = 140,
    this.padding = const EdgeInsets.all(Insets.md),
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 600 &&
            page.hasMore &&
            !page.loadingMore) {
          onLoadMore?.call();
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols =
              (constraints.maxWidth / (minCardWidth + Insets.sm))
                  .floor()
                  .clamp(2, 12);
          return GridView.builder(
            padding: padding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: Insets.md,
              crossAxisSpacing: Insets.sm,
              childAspectRatio:
                  shape.ratio * 0.72, // room for title + subtitle
            ),
            itemCount: page.items.length + (page.hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= page.items.length) {
                return const Center(
                    child: CircularProgressIndicator.adaptive());
              }
              final item = page.items[i];
              return MediaCard(
                item: item,
                shape: shape,
                width: double.infinity,
                onTap: () => onTap?.call(item),
                onLongPress: () => onLongPress?.call(item),
              );
            },
          );
        },
      ),
    );
  }
}
