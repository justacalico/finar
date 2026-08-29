import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import '../../player.dart';
import 'home_widgets.dart';

class HomeVideoMiniPlayer extends ConsumerWidget {
  const HomeVideoMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';
    final item = playerState.currentItem;

    if (item == null) return const SizedBox.shrink();

    final duration = playerState.duration;
    final position = playerState.position;

    void openFullPlayer() {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const PlayerPage()));
    }

    return GlassContainer(
      blur: AppTheme.blurMedium,
      opacity: 0.1,
      borderRadius: 0,
      showBorder: false,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: AppColors.surface,
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: playerState.progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (duration.inMilliseconds * value).round(),
                );
                ref.read(playerProvider.notifier).seek(newPosition);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: openFullPlayer,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: SizedBox(
                      width: 80,
                      height: 45,
                      child: CachedNetworkImage(
                        imageUrl: item.getDisplayImageUrl(
                          serverUrl,
                          width: 200,
                        ),
                        memCacheWidth: 160,
                        memCacheHeight: 90,
                        fadeInDuration: const Duration(milliseconds: 150),
                        placeholder: (_, _) =>
                            Container(color: AppColors.surface),
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.movie,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: openFullPlayer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          getVideoSubtitle(item),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 28,
                        color: playerState.hasPrevious
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        onPressed: playerState.hasPrevious
                            ? () => ref
                                  .read(playerProvider.notifier)
                                  .playPrevious()
                            : null,
                        tooltip: 'Previous',
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                          boxShadow: AppTheme.shadowGlow(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            playerState.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          iconSize: 28,
                          color: Colors.white,
                          onPressed: () {
                            ref.read(playerProvider.notifier).playOrPause();
                          },
                          tooltip: playerState.isPlaying ? 'Pause' : 'Play',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 28,
                        color: playerState.hasNext
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        onPressed: playerState.hasNext
                            ? () => ref.read(playerProvider.notifier).playNext()
                            : null,
                        tooltip: 'Next',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${formatDuration(position)} / ${formatDuration(duration)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.open_in_full),
                        iconSize: 20,
                        color: AppColors.textSecondary,
                        onPressed: openFullPlayer,
                        tooltip: 'Open player',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        color: AppColors.textSecondary,
                        onPressed: () {
                          ref.read(playerProvider.notifier).stop();
                        },
                        tooltip: 'Close player',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
