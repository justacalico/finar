import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'player_controls.dart';

class PlayerMobileCenterControls extends ConsumerWidget {
  final bool controlsVisible;
  final VoidCallback onRewind;
  final VoidCallback onPlayPause;
  final VoidCallback onForward;

  const PlayerMobileCenterControls({
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
              if (state.hasPrevious)
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 36),
                  onPressed: () =>
                      ref.read(playerProvider.notifier).playPrevious(),
                ),
              const SizedBox(width: 24),
              PlayerCenterButton(
                icon: Icons.replay_10,
                onPressed: onRewind,
                backgroundColor: Colors.transparent,
                borderColor: Colors.transparent,
                iconScale: 0.6,
              ),
              const SizedBox(width: 16),
              PlayerCenterButton(
                icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
                onPressed: onPlayPause,
                size: 64,
                isPrimary: true,
                backgroundColor: AppColors.white.withValues(alpha: 0.15),
                borderColor: Colors.transparent,
                iconScale: 0.6,
              ),
              const SizedBox(width: 16),
              PlayerCenterButton(
                icon: Icons.forward_10,
                onPressed: onForward,
                backgroundColor: Colors.transparent,
                borderColor: Colors.transparent,
                iconScale: 0.6,
              ),
              const SizedBox(width: 24),
              if (state.hasNext)
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 36),
                  onPressed: () => ref.read(playerProvider.notifier).playNext(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
