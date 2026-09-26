import 'package:flutter/material.dart';

import '../core/api/models.dart';
import '../core/theme/app_theme.dart';
import 'app_image.dart';
import 'media_card.dart';

/// Horizontal rail of cards with a title row and optional "See all".
/// One rail implementation for every home row and detail section.
class MediaRail extends StatelessWidget {
  final String title;
  final List<MediaItem> items;
  final ArtShape shape;
  final double cardWidth;
  final VoidCallback? onSeeAll;
  final void Function(MediaItem item)? onTap;
  final void Function(MediaItem item)? onLongPress;

  const MediaRail({
    super.key,
    required this.title,
    required this.items,
    this.shape = ArtShape.poster,
    this.cardWidth = 150,
    this.onSeeAll,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return SizedBox.shrink();
    final cardHeight = dim(cardWidth / shape.ratio + 52);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Insets.md,
            Insets.lg,
            Insets.md,
            Insets.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: Insets.md),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(width: Insets.sm),
            itemBuilder: (context, i) => MediaCard(
              item: items[i],
              shape: shape,
              width: cardWidth,
              onTap: () => onTap?.call(items[i]),
              onLongPress: () => onLongPress?.call(items[i]),
            ),
          ),
        ),
      ],
    );
  }
}
