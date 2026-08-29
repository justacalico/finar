import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/no_video_controls.dart';
import 'player_controls.dart';
import 'player_mobile_top_controls.dart';
import 'player_mobile_center_controls.dart';
import 'player_mobile_bottom_controls.dart';
import 'player_mobile_settings_panel.dart';
import 'player_mobile_indicators.dart';
import 'player_sleep_timer_overlay.dart';

class PlayerMobile extends ConsumerStatefulWidget {
  const PlayerMobile({super.key});

  @override
  ConsumerState<PlayerMobile> createState() => _PlayerMobileState();
}

class _PlayerMobileState extends ConsumerState<PlayerMobile> {
  bool _controlsVisible = true;
  bool _isLocked = false;
  bool _showSettings = false;
  bool _showBrightness = false;
  bool _showVolume = false;
  double _brightness = 0.5;
  double _dragStartX = 0;
  double _dragStartY = 0;
  DateTime _lastInteraction = DateTime.now();
  Orientation _orientation = Orientation.landscape;

  int _seekAmount = 0;
  bool _showLeftSeek = false;
  bool _showRightSeek = false;

  @override
  void initState() {
    super.initState();
    _enterFullscreen();
    _startHideTimer();
    _initBrightness();
  }

  @override
  void dispose() {
    _resetBrightness();
    _exitFullscreen();
    super.dispose();
  }

  Future<void> _initBrightness() async {
    try {
      final brightness = await ScreenBrightness.instance.application;
      if (mounted) {
        setState(() => _brightness = brightness);
      }
    } catch (e) {
      debugPrint('Failed to get brightness: $e');
    }
  }

  Future<void> _setBrightness(double value) async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(value);
      if (mounted) {
        setState(() => _brightness = value);
      }
    } catch (e) {
      debugPrint('Failed to set brightness: $e');
    }
  }

  Future<void> _resetBrightness() async {
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint('Failed to reset brightness: $e');
    }
  }

  void _enterFullscreen() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _startHideTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted &&
          DateTime.now().difference(_lastInteraction).inSeconds >= 4) {
        final isPlaying = ref.read(playerProvider).isPlaying;
        if (isPlaying) {
          setState(() => _controlsVisible = false);
        }
      }
    });
  }

  void _toggleControls() {
    if (_isLocked) return;
    _lastInteraction = DateTime.now();
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _startHideTimer();
    }
  }

  void _handleDoubleTap(TapDownDetails details, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    if (tapX < screenWidth / 3) {
      _seek(-10);
      setState(() {
        _seekAmount = 10;
        _showLeftSeek = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showLeftSeek = false);
      });
    } else if (tapX > screenWidth * 2 / 3) {
      _seek(10);
      setState(() {
        _seekAmount = 10;
        _showRightSeek = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showRightSeek = false);
      });
    }
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
    final screenWidth = MediaQuery.of(context).size.width;
    final x = details.globalPosition.dx;

    if (x < screenWidth / 2) {
      setState(() => _showBrightness = true);
    } else {
      setState(() => _showVolume = true);
    }
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final delta = (_dragStartY - details.globalPosition.dy) / screenHeight;

    if (_showBrightness) {
      final newBrightness = (_brightness + delta * 0.5).clamp(0.0, 1.0);
      _setBrightness(newBrightness);
    } else if (_showVolume) {
      final currentVolume = ref.read(playerProvider).volume;
      ref
          .read(playerProvider.notifier)
          .setVolume((currentVolume + delta * 0.5).clamp(0.0, 1.0));
    }

    _dragStartY = details.globalPosition.dy;
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showBrightness = false;
          _showVolume = false;
        });
      }
    });
  }

  double _seekStartPosition = 0;

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _seekStartPosition = ref.read(playerProvider).position.inSeconds.toDouble();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final delta = (details.globalPosition.dx - _dragStartX) / screenWidth;
    final duration = ref.read(playerProvider).duration.inSeconds;
    final seekDelta = (delta * duration * 0.3).clamp(
      -duration.toDouble(),
      duration.toDouble(),
    );

    ref
        .read(playerProvider.notifier)
        .seekTo(Duration(seconds: (_seekStartPosition + seekDelta).toInt()));
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {}

  void _togglePlayPause() {
    ref.read(playerProvider.notifier).playOrPause();
  }

  void _seek(int seconds) {
    final currentPosition = ref.read(playerProvider).position;
    ref
        .read(playerProvider.notifier)
        .seekTo(currentPosition + Duration(seconds: seconds));
  }

  void _cyclePlaybackSpeed() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentSpeed = ref.read(playerProvider).playbackSpeed;
    final currentIndex = speeds.indexOf(currentSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    ref.read(playerProvider.notifier).setPlaybackSpeed(speeds[nextIndex]);
  }

  void _rotateScreen() {
    if (_orientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      _orientation = Orientation.portrait;
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _orientation = Orientation.landscape;
    }
  }

  void _onBack() {
    ref.read(playerProvider.notifier).stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final videoController = ref.watch(videoControllerProvider);

    if (playerState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        onDoubleTapDown: (details) => _handleDoubleTap(details, context),
        onVerticalDragStart: _handleVerticalDragStart,
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        onHorizontalDragStart: _handleHorizontalDragStart,
        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: RepaintBoundary(
                child: Video(
                  controller: videoController,
                  controls: noVideoControls,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  wakelock: true,
                ),
              ),
            ),
            if (_isLocked)
              PlayerMobileLockedOverlay(
                onTap: () => setState(() => _isLocked = false),
              )
            else ...[
              PlayerMobileTopControls(
                controlsVisible: _controlsVisible,
                onBack: _onBack,
                onLock: () => setState(() {
                  _isLocked = true;
                  _controlsVisible = false;
                }),
                onQueueNextEpisode: () => queueNextEpisode(ref, context),
                onToggleSettings: () =>
                    setState(() => _showSettings = !_showSettings),
              ),
              PlayerMobileCenterControls(
                controlsVisible: _controlsVisible,
                onRewind: () => _seek(-10),
                onPlayPause: _togglePlayPause,
                onForward: () => _seek(10),
              ),
              PlayerMobileBottomControls(
                controlsVisible: _controlsVisible,
                onCyclePlaybackSpeed: _cyclePlaybackSpeed,
                onToggleSettings: () =>
                    setState(() => _showSettings = !_showSettings),
                onRotateScreen: _rotateScreen,
              ),
              PlayerMobileSettingsPanel(
                visible: _showSettings,
                onClose: () => setState(() => _showSettings = false),
              ),
              const SleepTimerOverlay(),
            ],
            if (_showBrightness)
              PlayerMobileBrightnessIndicator(brightness: _brightness),
            if (_showVolume) const PlayerMobileVolumeIndicator(),
            if (playerState.isBuffering)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            PlayerMobileSeekIndicator(
              seekAmount: _seekAmount,
              showLeftSeek: _showLeftSeek,
              showRightSeek: _showRightSeek,
            ),
          ],
        ),
      ),
    );
  }
}
