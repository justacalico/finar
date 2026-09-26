import 'dart:math';

import 'package:flutter/material.dart';

/// Equalizer bars for the currently loaded track. Bars bounce while
/// [playing]; on pause they ease down to a flat rest height so the
/// tile still reads as the current track.
class PlayingIndicator extends StatefulWidget {
  final bool playing;

  const PlayingIndicator({super.key, this.playing = true});

  @override
  State<PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<PlayingIndicator>
    with TickerProviderStateMixin {
  static const _rest = 0.15;

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // 1 = fully oscillating, 0 = resting. Reverses on pause so the
  // bars settle rather than snap.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: widget.playing ? 1 : 0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _bounce.repeat();
  }

  @override
  void didUpdateWidget(PlayingIndicator old) {
    super.didUpdateWidget(old);
    if (widget.playing) {
      _settle.forward();
      _bounce.repeat();
    } else {
      _bounce.stop();
      _settle.reverse();
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: Listenable.merge([_bounce, _settle]),
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 3,
              height: 4 + 10 * _level(i),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ),
    );
  }

  double _level(int i) {
    // Each bar is a third of a cycle behind the previous one.
    final live =
        (sin(2 * pi * (_bounce.value + i / 3)) + 1) / 2;
    return _rest + (live - _rest) * _settle.value;
  }
}
