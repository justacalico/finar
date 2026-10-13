import 'package:flutter/material.dart';

import '../core/models/models.dart';
import 'media_image.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.item,
    this.imageUrl,
    this.subtitle,
    this.width = 160,
    this.onTap,
  });

  final BaseItem item;
  final Uri? imageUrl;
  final String? subtitle;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final fraction =
        item.userData.playbackPositionTicks > 0 ? item.resumeFraction : 0.0;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MediaImage(
                      url: imageUrl,
                      icon: iconForType(item.type),
                    ),
                    if (item.userData.isFavorite)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Icon(Icons.favorite,
                            size: 16, color: scheme.primary),
                      ),
                    if (item.userData.played)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Icon(Icons.check_circle,
                            size: 18, color: scheme.primary),
                      ),
                    if (fraction > 0)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 4,
                            backgroundColor: Colors.black45,
                            valueColor:
                                AlwaysStoppedAnimation(scheme.primary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                subtitle ?? item.productionYear?.toString() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData iconForType(String type) => switch (type) {
        'Movie' => Icons.movie_outlined,
        'Series' => Icons.tv_outlined,
        'Episode' => Icons.play_circle_outline,
        'Audio' => Icons.music_note_outlined,
        'MusicAlbum' => Icons.album_outlined,
        'MusicArtist' => Icons.person_outline,
        'CollectionFolder' => Icons.video_library_outlined,
        'Genre' => Icons.category_outlined,
        _ => Icons.folder_outlined,
      };
}
