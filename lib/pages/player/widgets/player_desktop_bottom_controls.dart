import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'player_controls.dart';
import 'player_progress_bar.dart';

class PlayerDesktopBottomControls extends ConsumerWidget {
  final bool controlsVisible;
  final VoidCallback onToggleSettings;

  const PlayerDesktopBottomControls({
    super.key,
    required this.controlsVisible,
    required this.onToggleSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !controlsVisible,
        child: AnimatedOpacity(
          opacity: controlsVisible ? 1.0 : 0.0,
          duration: AppTheme.durationFast,
          child: AnimatedSlide(
            offset: controlsVisible ? Offset.zero : const Offset(0, 1),
            duration: AppTheme.durationNormal,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PlayerProgressBar(
                      showTimeLabels: true,
                      showChapters: true,
                      trackHeight: 4,
                      height: 24,
                      overlayRadius: 14,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const _PlayerDesktopVolumeControl(),
                        const Spacer(),
                        if (state.hasPrevious)
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            onPressed: () => ref
                                .read(playerProvider.notifier)
                                .playPrevious(),
                          ),
                        if (state.hasNext)
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            onPressed: () =>
                                ref.read(playerProvider.notifier).playNext(),
                          ),
                        const SizedBox(width: 16),
                        GlassIconButton(
                          icon: Icons.subtitles,
                          iconColor: state.currentSubtitleTrack != null
                              ? AppColors.primary
                              : null,
                          onPressed: onToggleSettings,
                        ),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: Icons.audiotrack,
                          onPressed: onToggleSettings,
                        ),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: Icons.settings,
                          onPressed: onToggleSettings,
                        ),
                        if (state.currentItem?.type == MediaType.episode) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Queue next episode',
                            child: GlassIconButton(
                              icon: Icons.playlist_add,
                              onPressed: () => queueNextEpisode(ref, context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerDesktopVolumeControl extends ConsumerWidget {
  const _PlayerDesktopVolumeControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            state.volume == 0
                ? Icons.volume_off
                : state.volume < 0.5
                ? Icons.volume_down
                : Icons.volume_up,
          ),
          onPressed: () {
            ref
                .read(playerProvider.notifier)
                .setVolume(state.volume > 0 ? 0 : 1);
          },
        ),
        SizedBox(
          width: 100,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
              activeTrackColor: AppColors.white,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.white,
              overlayColor: Colors.transparent,
            ),
            child: Slider(
              value: state.volume,
              min: 0,
              max: 1,
              onChanged: (value) {
                ref.read(playerProvider.notifier).setVolume(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}
