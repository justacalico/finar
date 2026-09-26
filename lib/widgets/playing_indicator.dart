import 'dart:math';

import 'package:flutter/material.dart';

/// Equalizer bars for the currently loaded track. Bars bounce while
/// [playing]; when paused they rest at minimum height so the tile
/// still reads as the current track.
class PlayingIndicator extends StatefulWidget {
  final bool playing;

  const PlayingIndicator({super.key, this.playing = true});

  @override
  State<PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _controller.repeat();
  }

  @override
  void didUpdateWidget(PlayingIndicator old) {
    super.didUpdateWidget(old);
    if (widget.playing) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
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
    if (!widget.playing) return 0.15;
    // Each bar is a third of a cycle behind the previous one.
    return (sin(2 * pi * (_controller.value + i / 3)) + 1) / 2;
  }
}
