import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/jellyfin_client.dart';
import '../core/api/models.dart';
import '../providers/providers.dart';
import 'app_image.dart';
import 'focusable.dart';

/// One card for a media item: art, progress bar, watched badge, title.
/// Used by rails, grids and search results so every list looks the same.
class MediaCard extends ConsumerWidget {
  final MediaItem item;
  final ArtShape shape;
  final double width;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showTitle;

  const MediaCard({
    super.key,
    required this.item,
    this.shape = ArtShape.poster,
    this.width = 150,
    this.onTap,
    this.onLongPress,
    this.showTitle = true,
  });

  /// Landscape variant used by Continue Watching / episode rows.
  const MediaCard.landscape({
    super.key,
    required this.item,
    this.width = 260,
    this.onTap,
    this.onLongPress,
    this.showTitle = true,
  }) : shape = ArtShape.backdrop;

  /// Square variant for albums and artists.
  const MediaCard.square({
    super.key,
    required this.item,
    this.width = 170,
    this.onTap,
    this.onLongPress,
    this.showTitle = true,
  }) : shape = ArtShape.square;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(jellyfinClientProvider);
    final imageUrl = switch (shape) {
      ArtShape.poster => client.posterUrl(item, maxWidth: 400),
      ArtShape.square => client.posterUrl(item, maxWidth: 400),
      ArtShape.backdrop => _thumb(client),
      ArtShape.avatar => '',
    };

    return SizedBox(
      width: width,
      child: Focusable(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppImage(imageUrl, shape: shape),
                if (item.hasProgress) _progress(),
                if (item.isPlayed) _watchedBadge(context),
              ],
            ),
            if (showTitle) ...[
              const SizedBox(height: 8),
              Text(
                _title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (_subtitle != null)
                Text(
                  _subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _thumb(JellyfinClient client) =>
      client.thumbUrl(item, maxWidth: 640);

  String get _title => switch (item.kind) {
        MediaKind.episode => item.seriesName ?? item.name,
        MediaKind.audio => item.name,
        _ => item.name,
      };

  String? get _subtitle {
    if (item.kind == MediaKind.episode) {
      final label = item.episodeLabel;
      return label.isEmpty ? item.name : '$label  •  ${item.name}';
    }
    if (item.kind == MediaKind.audio) {
      return item.artists.isNotEmpty ? item.artists.join(', ') : item.album;
    }
    if (item.kind == MediaKind.album) return item.albumArtist;
    if (item.productionYear != null) return '${item.productionYear}';
    return null;
  }

  Widget _progress() => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(12)),
          child: LinearProgressIndicator(
            value: item.progress,
            minHeight: 4,
            backgroundColor: Colors.black45,
          ),
        ),
      );

  Widget _watchedBadge(BuildContext context) => Positioned(
        top: 6,
        right: 6,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 14, color: Colors.white),
        ),
      );
}
