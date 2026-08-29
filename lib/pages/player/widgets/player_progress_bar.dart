import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';

import 'package:finar/providers/providers.dart';
import 'player_controls.dart';

class PlayerProgressBar extends ConsumerWidget {
  final bool showTimeLabels;
  final bool showChapters;
  final double trackHeight;
  final double height;
  final double enabledThumbRadius;
  final double overlayRadius;

  const PlayerProgressBar({
    super.key,
    this.showTimeLabels = false,
    this.showChapters = false,
    this.trackHeight = 3,
    this.height = 32,
    this.enabledThumbRadius = 6,
    this.overlayRadius = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final position = state.position;
    final duration = state.duration;
    final buffered = state.bufferedPosition;
    final max = duration.inMilliseconds
        .toDouble()
        .clamp(1, double.infinity)
        .toDouble();

    final slider = SizedBox(
      height: height,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: trackHeight,
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: enabledThumbRadius,
          ),
          overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.divider,
          thumbColor: AppColors.primary,
          overlayColor: AppColors.primary.withValues(alpha: 0.2),
          secondaryActiveTrackColor: AppColors.primary.withValues(alpha: 0.3),
        ),
        child: Slider(
          value: position.inMilliseconds.toDouble().clamp(0, max).toDouble(),
          min: 0,
          max: max,
          secondaryTrackValue: buffered.inMilliseconds
              .toDouble()
              .clamp(0, max)
              .toDouble(),
          onChanged: (value) {
            ref
                .read(playerProvider.notifier)
                .seekTo(Duration(milliseconds: value.toInt()));
          },
        ),
      ),
    );

    if (!showTimeLabels && !showChapters) return slider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTimeLabels)
          Row(
            children: [
              Text(formatDuration(position), style: AppTextStyles.labelMedium),
              const Spacer(),
              Text(
                '-${formatDuration(duration - position)}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        if (showTimeLabels) const SizedBox(height: 8),
        slider,
        if (showChapters && state.chapters?.isNotEmpty == true)
          _PlayerChapterMarkers(),
      ],
    );
  }
}

class _PlayerChapterMarkers extends ConsumerWidget {
  const _PlayerChapterMarkers();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final duration = state.duration;
    final width = MediaQuery.of(context).size.width * 0.9;

    return SizedBox(
      height: 20,
      child: Stack(
        children: state.chapters!.map((chapter) {
          final position =
              chapter.startPositionTicks / (duration.inMicroseconds * 10);
          return Positioned(
            left: position * width,
            child: Tooltip(
              message: chapter.name,
              child: Container(
                width: 2,
                height: 8,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
