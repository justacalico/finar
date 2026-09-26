import 'package:flutter/material.dart';

import '../core/api/format.dart';
import '../core/theme/app_theme.dart';

/// Playback scrubber with buffered track and time labels. The thumb
/// tracks the drag locally and only seeks the player once, on release.
class SeekBar extends StatefulWidget {
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
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = widget.duration.inMilliseconds.toDouble();
    final pos = _drag ?? widget.position.inMilliseconds.toDouble();
    final value = max > 0 ? pos.clamp(0, max) : 0.0;
    final buf = max > 0
        ? widget.buffered.inMilliseconds.clamp(0, max.toInt())
        : 0;

    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: widget.compact ? dim(3) : dim(4),
        thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: widget.compact ? dim(6) : dim(8)),
        secondaryActiveTrackColor:
            scheme.onSurface.withValues(alpha: 0.3),
      ),
      child: Slider(
        value: value / (max > 0 ? max : 1),
        secondaryTrackValue: buf / (max > 0 ? max : 1),
        onChanged: max > 0
            ? (v) => setState(() => _drag = v * max)
            : null,
        onChangeEnd: max > 0
            ? (v) {
                widget.onSeek(
                    Duration(milliseconds: (v * max).round()));
                setState(() => _drag = null);
              }
            : null,
      ),
    );

    if (widget.compact) return slider;

    final shown = _drag != null
        ? Duration(milliseconds: _drag!.round())
        : widget.position;
    final remaining = widget.duration - shown;
    return Row(
      children: [
        Text(formatDuration(shown),
            style: Theme.of(context).textTheme.labelMedium),
        SizedBox(width: dim(8)),
        Expanded(child: slider),
        SizedBox(width: dim(8)),
        Text(
          remaining > Duration.zero
              ? '-${formatDuration(remaining)}'
              : formatDuration(widget.duration),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
