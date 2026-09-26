import 'package:flutter/material.dart';

import '../core/api/format.dart';

/// Playback scrubber with buffered track and time labels.
class SeekBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final ValueChanged<Duration> onSeek;
  final bool compact;

  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    this.buffered = Duration.zero,
    required this.onSeek,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = duration.inMilliseconds.toDouble();
    final value =
        max > 0 ? position.inMilliseconds.clamp(0, max.toInt()) : 0;
    final buf =
        max > 0 ? buffered.inMilliseconds.clamp(0, max.toInt()) : 0;

    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: compact ? 3 : 4,
        thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: compact ? 6 : 8),
        secondaryActiveTrackColor:
            scheme.onSurface.withValues(alpha: 0.3),
      ),
      child: Slider(
        value: value / (max > 0 ? max : 1),
        secondaryTrackValue: buf / (max > 0 ? max : 1),
        onChanged: max > 0
            ? (v) => onSeek(Duration(milliseconds: (v * max).round()))
            : null,
      ),
    );

    if (compact) return slider;

    final remaining = duration - position;
    return Row(
      children: [
        Text(formatDuration(position),
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 8),
        Expanded(child: slider),
        const SizedBox(width: 8),
        Text(
          remaining > Duration.zero
              ? '-${formatDuration(remaining)}'
              : formatDuration(duration),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
