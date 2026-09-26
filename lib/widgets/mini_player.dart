import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/providers.dart';
import 'app_image.dart';
import 'glass.dart';

/// Floating bar shown whenever music is loaded. Art, title, play/pause
/// and next. Tapping the art area could expand a full player later.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioPlayerProvider);
    final track = audio.current;
    if (track == null) return const SizedBox.shrink();
    final client = ref.read(jellyfinClientProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Insets.sm, 0, Insets.sm, Insets.sm),
      child: GlassBar(
        padding: const EdgeInsets.symmetric(
            horizontal: Insets.sm, vertical: Insets.xs),
        child: Row(
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
                  Text(track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge),
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
                  ? () =>
                      ref.read(audioPlayerProvider.notifier).previous()
                  : null,
            ),
            IconButton(
              icon: audio.loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(audio.playing
                      ? Icons.pause
                      : Icons.play_arrow),
              onPressed: () =>
                  ref.read(audioPlayerProvider.notifier).toggle(),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: audio.queue.hasNext
                  ? () => ref.read(audioPlayerProvider.notifier).next()
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
