import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart' hide VideoState;

import '../core/theme/app_theme.dart';
import '../core/api/models.dart';
import '../providers/playback_provider.dart';
import '../widgets/seek_bar.dart';

/// Fullscreen video player: media_kit surface, auto-hiding controls,
/// keyboard/gamepad shortcuts.
class PlayerPage extends ConsumerStatefulWidget {
  final MediaItem item;
  final Duration? startPosition;

  const PlayerPage({super.key, required this.item, this.startPosition});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _started = false;
  late final VideoPlayerNotifier _player;

  @override
  void initState() {
    super.initState();
    _showControls();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    _player = ref.read(videoPlayerProvider.notifier);
    final ticks = widget.startPosition != null
        ? widget.startPosition!.inMicroseconds * 10
        : (widget.item.resumeTicks);
    await _player.play(widget.item, startTimeTicks: ticks);
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && ref.read(videoPlayerProvider)?.playing == true) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _showControls();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _player.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoPlayerProvider);
    final player = state?.player;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          return _handleKey(event.logicalKey);
        },
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: player != null
                    ? Video(controller: VideoController(player))
                    : SizedBox.shrink(),
              ),
              if (state?.buffering != false)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              AnimatedOpacity(
                opacity: _controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: _Controls(
                    state: state,
                    onBack: () => Navigator.of(context).maybePop(),
                    onAction: _showControls,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKey(LogicalKeyboardKey key) {
    final notifier = ref.read(videoPlayerProvider.notifier);
    _showControls();
    switch (key) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.mediaPlayPause:
      case LogicalKeyboardKey.select:
        notifier.toggle();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.gameButtonB:
        notifier.seekBy(const Duration(seconds: -10));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        notifier.seekBy(const Duration(seconds: 10));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        notifier.seekBy(const Duration(seconds: 30));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        notifier.seekBy(const Duration(seconds: -30));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.backspace:
        Navigator.of(context).maybePop();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyF:
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class _Controls extends ConsumerWidget {
  final VideoState? state;
  final VoidCallback onBack;
  final VoidCallback onAction;

  const _Controls({
    required this.state,
    required this.onBack,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(videoPlayerProvider.notifier);
    final s = state;
    return Column(
      children: [
        // Top bar
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBack,
                ),
                Expanded(
                  child: Text(
                    s?.item.displayTitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _TrackMenu(state: s),
              ],
            ),
          ),
        ),
        Spacer(),
        // Center controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 40,
              color: Colors.white,
              icon: const Icon(Icons.replay_10),
              onPressed: () {
                notifier.seekBy(const Duration(seconds: -10));
                onAction();
              },
            ),
            SizedBox(width: dim(32)),
            IconButton(
              iconSize: 64,
              color: Colors.white,
              icon: Icon(
                s?.playing == true ? Icons.pause_circle : Icons.play_circle,
              ),
              onPressed: () {
                notifier.toggle();
                onAction();
              },
            ),
            SizedBox(width: dim(32)),
            IconButton(
              iconSize: 40,
              color: Colors.white,
              icon: const Icon(Icons.forward_30),
              onPressed: () {
                notifier.seekBy(const Duration(seconds: 30));
                onAction();
              },
            ),
          ],
        ),
        Spacer(),
        // Bottom bar
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SeekBar(
                    position: s?.position ?? Duration.zero,
                    duration: s?.duration ?? Duration.zero,
                    buffered: s?.buffered ?? Duration.zero,
                    onSeek: (d) {
                      notifier.seek(d);
                      onAction();
                    },
                  ),
                  Row(
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: Icon(
                          s?.playing == true ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () {
                          notifier.toggle();
                          onAction();
                        },
                      ),
                      _SpeedMenu(speed: s?.speed ?? 1),
                      Spacer(),
                      if (s != null && s.subtitleStreams.isNotEmpty)
                        _SubtitleMenu(state: s),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackMenu extends ConsumerWidget {
  final VideoState? state;
  const _TrackMenu({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = state;
    if (s == null || s.audioStreams.length <= 1) {
      return SizedBox.shrink();
    }
    return PopupMenuButton<int>(
      icon: const Icon(Icons.audiotrack, color: Colors.white),
      tooltip: 'Audio track',
      onSelected: (i) => ref.read(videoPlayerProvider.notifier).selectAudio(i),
      itemBuilder: (_) => [
        for (final stream in s.audioStreams)
          CheckedPopupMenuItem(
            value: stream.index,
            checked: stream.index == s.audioIndex,
            child: Text(stream.label),
          ),
      ],
    );
  }
}

class _SubtitleMenu extends ConsumerWidget {
  final VideoState state;
  const _SubtitleMenu({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.subtitles_outlined, color: Colors.white),
      tooltip: 'Subtitles',
      onSelected: (i) =>
          ref.read(videoPlayerProvider.notifier).selectSubtitle(i),
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: -1,
          checked: state.subtitleIndex == -1 || state.subtitleIndex == null,
          child: const Text('Off'),
        ),
        for (final stream in state.subtitleStreams)
          CheckedPopupMenuItem(
            value: stream.index,
            checked: stream.index == state.subtitleIndex,
            child: Text(stream.label),
          ),
      ],
    );
  }
}

class _SpeedMenu extends ConsumerWidget {
  final double speed;
  const _SpeedMenu({required this.speed});

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<double>(
      tooltip: 'Playback speed',
      onSelected: (v) => ref.read(videoPlayerProvider.notifier).setSpeed(v),
      itemBuilder: (_) => [
        for (final v in _speeds)
          CheckedPopupMenuItem(
            value: v,
            checked: v == speed,
            child: Text('${v}x'),
          ),
      ],
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          '${speed}x',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
