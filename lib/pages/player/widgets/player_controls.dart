import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

Future<void> queueNextEpisode(WidgetRef ref, BuildContext context) async {
  final success = await ref.read(playerProvider.notifier).queueNextEpisode();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Next episode queued' : 'No next episode available',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class PlayerCenterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final bool isPrimary;
  final double iconScale;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool shimmer;

  const PlayerCenterButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.isPrimary = false,
    this.iconScale = 0.5,
    this.backgroundColor,
    this.borderColor = AppColors.glassBorder,
    this.shimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                backgroundColor ??
                (isPrimary
                    ? AppColors.glassBackground
                    : AppColors.glassBackground.withValues(alpha: 0.3)),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1)
                : null,
          ),
          child: Icon(icon, size: size * iconScale, color: AppColors.white),
        ),
      ),
    );

    if (shimmer) {
      return child
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(
            delay: 2.seconds,
            duration: 1.seconds,
            color: AppColors.white.withValues(alpha: 0.1),
          );
    }

    return child;
  }
}

class PlayerSettingsOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool animated;

  const PlayerSettingsOption(
    this.label, {
    super.key,
    this.isSelected = false,
    this.onTap,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      border: Border.all(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
    );

    final child = Text(
      label,
      style: AppTextStyles.labelSmall.copyWith(
        color: isSelected ? AppColors.black : AppColors.textPrimary,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: animated
          ? AnimatedContainer(
              duration: AppTheme.durationFast,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: decoration,
              child: child,
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: decoration,
              child: child,
            ),
    );
  }
}

class PlayerSettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const PlayerSettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}
