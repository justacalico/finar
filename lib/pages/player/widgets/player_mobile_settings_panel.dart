import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'player_controls.dart';

class PlayerMobileSettingsPanel extends ConsumerWidget {
  final bool visible;
  final VoidCallback onClose;

  const PlayerMobileSettingsPanel({
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
          right: 16,
          bottom: 100,
          child: GlassContainer(
            blur: AppTheme.blurHeavy,
            opacity: 0.15,
            borderRadius: AppTheme.radiusMd,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 250,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlayerSettingsSection(
                    title: 'Quality',
                    children: state.availableQualities
                        .map(
                          (q) => PlayerSettingsOption(
                            q,
                            isSelected: state.currentQuality == q,
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
                            onTap: () => ref
                                .read(playerProvider.notifier)
                                .setSubtitleTrack(track.index),
                          ),
                        ),
                    ],
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
