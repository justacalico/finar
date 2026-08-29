import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';

class PlayerMobileLockedOverlay extends StatelessWidget {
  final VoidCallback onTap;

  const PlayerMobileLockedOverlay({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: GlassContainer(
            blur: AppTheme.blurLight,
            opacity: 0.2,
            borderRadius: AppTheme.radiusLg,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 20),
                SizedBox(width: 8),
                Text('Tap to unlock'),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(),
    );
  }
}

class PlayerMobileBrightnessIndicator extends StatelessWidget {
  final double brightness;

  const PlayerMobileBrightnessIndicator({super.key, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 40,
      top: 0,
      bottom: 0,
      child: Center(
        child: GlassContainer(
          blur: AppTheme.blurLight,
          opacity: 0.2,
          borderRadius: AppTheme.radiusMd,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.brightness_6, size: 24),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: LinearProgressIndicator(
                    value: brightness,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(brightness * 100).toInt()}%',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(),
    );
  }
}

class PlayerMobileVolumeIndicator extends ConsumerWidget {
  const PlayerMobileVolumeIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);

    return Positioned(
      right: 40,
      top: 0,
      bottom: 0,
      child: Center(
        child: GlassContainer(
          blur: AppTheme.blurLight,
          opacity: 0.2,
          borderRadius: AppTheme.radiusMd,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.volume == 0
                    ? Icons.volume_off
                    : state.volume < 0.5
                    ? Icons.volume_down
                    : Icons.volume_up,
                size: 24,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: LinearProgressIndicator(
                    value: state.volume,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(state.volume * 100).toInt()}%',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(),
    );
  }
}

class PlayerMobileSeekIndicator extends StatelessWidget {
  final int seekAmount;
  final bool showLeftSeek;
  final bool showRightSeek;

  const PlayerMobileSeekIndicator({
    super.key,
    required this.seekAmount,
    required this.showLeftSeek,
    required this.showRightSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedOpacity(
            opacity: showLeftSeek ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.black.withValues(alpha: 0.4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.replay_10, size: 32),
                    Text('$seekAmount sec', style: AppTextStyles.labelSmall),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedOpacity(
            opacity: showRightSeek ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.black.withValues(alpha: 0.4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.forward_10, size: 32),
                    Text('+$seekAmount sec', style: AppTextStyles.labelSmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
