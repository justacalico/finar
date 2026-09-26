import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/format.dart';
import '../core/api/models.dart';
import '../core/theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/downloads_provider.dart';
import '../providers/library_provider.dart';

/// The detail page's action row: play/resume plus favorite, watched
/// and download state buttons. Everything the item menu offers is
/// already visible here, so there is no overflow entry.
class DetailActions extends ConsumerWidget {
  final MediaItem item;
  final VoidCallback? onPlay;
  final VoidCallback? onPlayFromStart;

  const DetailActions({
    super.key,
    required this.item,
    this.onPlay,
    this.onPlayFromStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(mediaActionsProvider);
    final downloads = ref.watch(downloadsProvider);
    final entry = downloads
        .where((e) => e.item.id == item.id)
        .firstOrNull;
    final downloaded = entry?.status == DownloadStatus.done;
    final downloading = entry != null &&
        (entry.status == DownloadStatus.downloading ||
            entry.status == DownloadStatus.queued);

    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      children: [
        if (item.isVideo)
          FilledButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow),
            label: Text(item.hasProgress
                ? 'Resume ${formatDuration(Duration(microseconds: item.resumeTicks ~/ 10))}'
                : 'Play'),
          ),
        if (item.hasProgress && item.isVideo)
          OutlinedButton(
            onPressed: onPlayFromStart ?? onPlay,
            child: const Text('Play from start'),
          ),
        if (item.kind == MediaKind.audio)
          FilledButton.icon(
            onPressed: () => ref
                .read(audioPlayerProvider.notifier)
                .playTracks([item], 0),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
        ActionIconButton(
          tooltip: item.isFavorite
              ? 'Remove from favorites'
              : 'Add to favorites',
          icon: item.isFavorite
              ? Icons.favorite
              : Icons.favorite_border,
          active: item.isFavorite,
          onPressed: () => actions.toggleFavorite(item),
        ),
        ActionIconButton(
          tooltip:
              item.isPlayed ? 'Mark unplayed' : 'Mark played',
          icon: item.isPlayed
              ? Icons.check_circle
              : Icons.check_circle_outline,
          active: item.isPlayed,
          onPressed: () => actions.togglePlayed(item),
        ),
        if (item.isVideo)
          ActionIconButton(
            tooltip: downloaded
                ? 'Downloaded'
                : downloading
                    ? 'Downloading'
                    : 'Download',
            icon: downloaded
                ? Icons.download_done
                : downloading
                    ? Icons.downloading
                    : Icons.download_outlined,
            active: downloaded,
            onPressed: downloaded || downloading
                ? null
                : () => ref
                    .read(downloadsProvider.notifier)
                    .download(item),
          ),
      ],
    );
  }
}

/// Circular action button. Quiet tonal fill; the icon picks up the
/// accent when [active].
class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  const ActionIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: active
            ? scheme.primary.withValues(alpha: 0.18)
            : scheme.secondaryContainer,
        foregroundColor: active
            ? scheme.primary
            : scheme.onSecondaryContainer,
        disabledBackgroundColor:
            scheme.secondaryContainer.withValues(alpha: 0.5),
      ),
    );
  }
}
