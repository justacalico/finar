import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'player_controls.dart';

class PlayerDesktopCenterControls extends ConsumerWidget {
  final bool controlsVisible;
  final VoidCallback onRewind;
  final VoidCallback onPlayPause;
  final VoidCallback onForward;

  const PlayerDesktopCenterControls({
    super.key,
    required this.controlsVisible,
    required this.onRewind,
    required this.onPlayPause,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);

    return IgnorePointer(
      ignoring: !controlsVisible,
      child: AnimatedOpacity(
        opacity: controlsVisible ? 1.0 : 0.0,
        duration: AppTheme.durationFast,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlayerCenterButton(
                icon: Icons.replay_10,
                onPressed: onRewind,
                size: 48,
                backgroundColor: AppColors.glassBackground.withValues(
                  alpha: 0.3,
                ),
                borderColor: AppColors.glassBorder,
              ),
              const SizedBox(width: 32),
              PlayerCenterButton(
                icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
                onPressed: onPlayPause,
                size: 72,
                isPrimary: true,
                backgroundColor: AppColors.glassBackground,
                borderColor: AppColors.glassBorder,
                shimmer: true,
              ),
              const SizedBox(width: 32),
              PlayerCenterButton(
                icon: Icons.forward_10,
                onPressed: onForward,
                size: 48,
                backgroundColor: AppColors.glassBackground.withValues(
                  alpha: 0.3,
                ),
                borderColor: AppColors.glassBorder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
