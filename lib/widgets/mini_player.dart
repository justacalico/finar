import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/format.dart';
import '../core/api/jellyfin_client.dart';
import '../core/api/models.dart';
import '../core/theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/providers.dart';
import 'app_image.dart';
import 'seek_bar.dart';

/// Docked playback bar. Sits in the layout like the sidebar rather
/// than floating over content. Art, title, controls and a seek strip.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioPlayerProvider);
    final track = audio.current;
    if (track == null) return const SizedBox.shrink();
    final client = ref.read(jellyfinClientProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.sm,
        vertical: Insets.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _controls(context, ref, audio, track, client),
          Row(
            children: [
              Text(
                formatDuration(audio.position),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Expanded(
                child: SeekBar(
                  position: audio.position,
                  duration: audio.duration,
                  compact: true,
                  onSeek: (p) => ref.read(audioPlayerProvider.notifier).seek(p),
                ),
              ),
              Text(
                formatDuration(audio.duration),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controls(
    BuildContext context,
    WidgetRef ref,
    AudioState audio,
    MediaItem track,
    JellyfinClient client,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: AppImage(
            client.posterUrl(track, maxWidth: 120),
            shape: ArtShape.square,
            borderRadius: 8,
          ),
        ),
        const SizedBox(width: Insets.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(
                track.artists.isNotEmpty
                    ? track.artists.join(', ')
                    : (track.album ?? ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous),
          onPressed: audio.queue.hasPrevious
              ? () => ref.read(audioPlayerProvider.notifier).previous()
              : null,
        ),
        IconButton(
          icon: audio.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(audio.playing ? Icons.pause : Icons.play_arrow),
          onPressed: () => ref.read(audioPlayerProvider.notifier).toggle(),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: audio.queue.hasNext
              ? () => ref.read(audioPlayerProvider.notifier).next()
              : null,
        ),
      ],
    );
  }
}
