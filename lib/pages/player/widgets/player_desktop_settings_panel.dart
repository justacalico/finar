import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'player_controls.dart';

class PlayerDesktopSettingsPanel extends ConsumerWidget {
  final bool visible;
  final VoidCallback onClose;

  const PlayerDesktopSettingsPanel({
    super.key,
    required this.visible,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visible) return const SizedBox.shrink();

    final state = ref.watch(playerProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          right: 24,
          bottom: 120,
          child: GlassContainer(
            blur: AppTheme.blurHeavy,
            opacity: 0.15,
            borderRadius: AppTheme.radiusLg,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Settings', style: AppTextStyles.titleMedium),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  PlayerSettingsSection(
                    title: 'Quality',
                    children: state.availableQualities
                        .map(
                          (q) => PlayerSettingsOption(
                            q,
                            isSelected: state.currentQuality == q,
                            animated: true,
                            onTap: () =>
                                ref.read(playerProvider.notifier).setQuality(q),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  PlayerSettingsSection(
                    title: 'Audio',
                    children:
                        state.audioTracks
                            ?.map(
                              (track) => PlayerSettingsOption(
                                track.displayTitle ?? 'Track ${track.index}',
                                isSelected:
                                    state.currentAudioTrack == track.index,
                                animated: true,
                                onTap: () => ref
                                    .read(playerProvider.notifier)
                                    .setAudioTrack(track.index),
                              ),
                            )
                            .toList() ??
                        [],
                  ),
                  const SizedBox(height: 16),
                  PlayerSettingsSection(
                    title: 'Subtitles',
                    children: [
                      PlayerSettingsOption(
                        'Off',
                        isSelected: state.currentSubtitleTrack == null,
                        animated: true,
                        onTap: () => ref
                            .read(playerProvider.notifier)
                            .setSubtitleTrack(null),
                      ),
                      if (state.subtitleTracks != null)
                        ...state.subtitleTracks!.map(
                          (track) => PlayerSettingsOption(
                            track.displayTitle ?? 'Track ${track.index}',
                            isSelected:
                                state.currentSubtitleTrack == track.index,
                            animated: true,
                            onTap: () => ref
                                .read(playerProvider.notifier)
                                .setSubtitleTrack(track.index),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PlayerSettingsSection(
                    title: 'Speed',
                    children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                        .map(
                          (speed) => PlayerSettingsOption(
                            '${speed}x',
                            isSelected: state.playbackSpeed == speed,
                            animated: true,
                            onTap: () => ref
                                .read(playerProvider.notifier)
                                .setPlaybackSpeed(speed),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideX(begin: 0.1),
        ),
      ],
    );
  }
}
