import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';
import '../core/api/jellyfin_api.dart';
import 'glass_container.dart';

class QueueView extends ConsumerWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playlist = playerState.playlist ?? [];
    final currentIndex = playerState.playlistIndex ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Queue',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    Text(
                      '${playlist.length} tracks',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (playlist.length > 1)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(playerProvider.notifier).clearQueue();
                        },
                        icon: const Icon(Icons.clear_all, color: Colors.white70),
                        label: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          // Now Playing section
          if (currentIndex < playlist.length) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_filled,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Now Playing',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _QueueItem(
              item: playlist[currentIndex],
              index: currentIndex,
              isPlaying: true,
              onTap: () {},
              onRemove: null, // Can't remove currently playing
            ),
            if (currentIndex < playlist.length - 1) ...[
              const Divider(color: Colors.white24, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.queue_music,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Up Next',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          // Queue list
          Expanded(
            child: playlist.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_music,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Queue is empty',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add songs to start playing',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: playlist.length - currentIndex - 1,
                    onReorder: (oldIndex, newIndex) {
                      // Adjust indices to account for the "Now Playing" section
                      final actualOldIndex = oldIndex + currentIndex + 1;
                      var actualNewIndex = newIndex + currentIndex + 1;
                      if (newIndex > oldIndex) {
                        actualNewIndex--;
                      }
                      ref
                          .read(playerProvider.notifier)
                          .reorderQueue(actualOldIndex, actualNewIndex);
                    },
                    itemBuilder: (context, index) {
                      final actualIndex = index + currentIndex + 1;
                      if (actualIndex >= playlist.length) return const SizedBox.shrink();
                      final item = playlist[actualIndex];
                      return _QueueItem(
                        key: ValueKey('${item.id}_$actualIndex'),
                        item: item,
                        index: actualIndex,
                        isPlaying: false,
                        onTap: () {
                          ref.read(playerProvider.notifier).playAtIndex(actualIndex);
                        },
                        onRemove: () {
                          ref.read(playerProvider.notifier).removeFromQueue(actualIndex);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueItem extends ConsumerWidget {
  final MediaItem item;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _QueueItem({
    super.key,
    required this.item,
    required this.index,
    required this.isPlaying,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(jellyfinApiProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isPlaying
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                )
              : null,
          child: Row(
            children: [
              // Drag handle (only for non-playing items)
              if (!isPlaying)
                ReorderableDragStartListener(
                  index: index - (ref.read(playerProvider).playlistIndex ?? 0) - 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.drag_handle,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                )
              else
                const SizedBox(width: 32),
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: api != null && item.imageTag != null
                    ? Image.network(
                        api.getImageUrl(item.id, item.imageTag!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              // Title and artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: isPlaying
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.artist != null)
                      Text(
                        item.artist!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Duration
              if (item.duration != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _formatDuration(item.duration!),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              // Playing indicator or remove button
              if (isPlaying)
                Icon(
                  Icons.equalizer,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                )
              else if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                  splashRadius: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.white.withOpacity(0.1),
      child: Icon(
        Icons.music_note,
        color: Colors.white.withOpacity(0.3),
        size: 24,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Shows the queue as a bottom sheet
void showQueueBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => const QueueView(),
    ),
  );
}
