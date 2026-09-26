import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';
import '../providers/downloads_provider.dart';
import '../providers/library_provider.dart';

/// Shared action sheet for a media item. Every surface (card long-press,
/// detail "more") uses this so actions stay consistent.
Future<void> showItemMenu(
  BuildContext context,
  WidgetRef ref,
  MediaItem item, {
  void Function(MediaItem item)? onPlay,
  void Function(MediaItem item)? onOpen,
}) {
  // Snapshot state before opening: this runs outside a build pass.
  final downloaded =
      ref.read(downloadsProvider.notifier).isDownloaded(item.id);
  final downloading =
      ref.read(downloadsProvider.notifier).isActive(item.id);
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final actions = ref.read(mediaActionsProvider);
      final downloads = ref.read(downloadsProvider.notifier);

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(item.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            if (item.isPlayable)
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: Text(item.hasProgress
                    ? 'Resume'
                    : 'Play'),
                onTap: () {
                  Navigator.pop(context);
                  onPlay?.call(item);
                },
              ),
            ListTile(
              leading: Icon(item.isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border),
              title: Text(
                  item.isFavorite ? 'Remove from favorites' : 'Favorite'),
              onTap: () {
                Navigator.pop(context);
                actions.toggleFavorite(item);
              },
            ),
            ListTile(
              leading: Icon(item.isPlayed
                  ? Icons.check_circle
                  : Icons.check_circle_outline),
              title:
                  Text(item.isPlayed ? 'Mark unplayed' : 'Mark played'),
              onTap: () {
                Navigator.pop(context);
                actions.togglePlayed(item);
              },
            ),
            if (item.isVideo)
              ListTile(
                leading: Icon(downloaded
                    ? Icons.download_done
                    : Icons.download_outlined),
                title: Text(downloaded
                    ? 'Downloaded'
                    : downloading
                        ? 'Downloading...'
                        : 'Download'),
                onTap: downloaded || downloading
                    ? null
                    : () {
                        Navigator.pop(context);
                        downloads.download(item);
                      },
              ),
            if (onOpen != null)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Details'),
                onTap: () {
                  Navigator.pop(context);
                  onOpen(item);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
