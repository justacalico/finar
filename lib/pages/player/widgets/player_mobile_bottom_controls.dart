import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'player_controls.dart';
import 'player_progress_bar.dart';

class PlayerMobileBottomControls extends ConsumerWidget {
  final bool controlsVisible;
  final VoidCallback onCyclePlaybackSpeed;
  final VoidCallback onToggleSettings;
  final VoidCallback onRotateScreen;

  const PlayerMobileBottomControls({
    super.key,
    required this.controlsVisible,
    required this.onCyclePlaybackSpeed,
    required this.onToggleSettings,
    required this.onRotateScreen,
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
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
                left: 16,
                right: 16,
                top: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.black.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PlayerProgressBar(
                    trackHeight: 3,
                    height: 32,
                    overlayRadius: 12,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${formatDuration(state.position)} / ${formatDuration(state.duration)}',
                        style: AppTextStyles.labelSmall,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onCyclePlaybackSpeed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${state.playbackSpeed}x',
                            style: AppTextStyles.labelSmall,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          Icons.subtitles,
                          color: state.currentSubtitleTrack != null
                              ? AppColors.primary
                              : null,
                        ),
                        onPressed: onToggleSettings,
                      ),
                      IconButton(
                        icon: const Icon(Icons.screen_rotation),
                        onPressed: onRotateScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
