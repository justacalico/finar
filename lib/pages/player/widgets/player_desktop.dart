import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/no_video_controls.dart';
import 'player_desktop_top_bar.dart';
import 'player_desktop_center_controls.dart';
import 'player_desktop_bottom_controls.dart';
import 'player_desktop_settings_panel.dart';
import 'player_sleep_timer_overlay.dart';

class PlayerDesktop extends ConsumerStatefulWidget {
  const PlayerDesktop({super.key});

  @override
  ConsumerState<PlayerDesktop> createState() => _PlayerDesktopState();
}

class _PlayerDesktopState extends ConsumerState<PlayerDesktop> {
  static const Duration _controlsHideDelay = Duration(seconds: 3);

  bool _controlsVisible = true;
  bool _isFullscreen = false;
  bool _showSettings = false;
  Timer? _hideTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scheduleControlsHide();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleControlsHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_controlsHideDelay, () {
      if (!mounted || !_controlsVisible) return;
      setState(() {
        _controlsVisible = false;
        _showSettings = false;
      });
    });
  }

  void _onInteraction({bool forceShow = false}) {
    if (forceShow || !_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _scheduleControlsHide();
  }

  void _toggleControls() {
    final willShow = !_controlsVisible;
    setState(() {
      _controlsVisible = willShow;
      if (!willShow) {
        _showSettings = false;
      }
    });

    if (willShow) {
      _scheduleControlsHide();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    _onInteraction();

    final key = event.logicalKey;

    switch (key) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.keyK:
      case LogicalKeyboardKey.mediaPlayPause:
      case LogicalKeyboardKey.mediaPlay:
      case LogicalKeyboardKey.mediaPause:
      case LogicalKeyboardKey.gameButtonA:
        _togglePlayPause();
        break;

      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyJ:
      case LogicalKeyboardKey.mediaRewind:
        _seek(-10);
        break;

      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyL:
      case LogicalKeyboardKey.mediaFastForward:
        _seek(10);
        break;

      case LogicalKeyboardKey.arrowUp:
        _adjustVolume(0.1);
        break;

      case LogicalKeyboardKey.arrowDown:
        _adjustVolume(-0.1);
        break;

      case LogicalKeyboardKey.keyF:
      case LogicalKeyboardKey.gameButtonY:
        _toggleFullscreen();
        break;

      case LogicalKeyboardKey.keyM:
        _toggleMute();
        break;

      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.gameButtonB:
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.browserBack:
        if (_isFullscreen) {
          _toggleFullscreen();
        } else {
          _onBack();
        }
        break;

      case LogicalKeyboardKey.gameButtonLeft1:
      case LogicalKeyboardKey.pageUp:
        _seek(-30);
        break;

      case LogicalKeyboardKey.gameButtonRight1:
      case LogicalKeyboardKey.pageDown:
        _seek(30);
        break;

      case LogicalKeyboardKey.gameButtonLeft2:
        _seek(-5);
        break;

      case LogicalKeyboardKey.gameButtonRight2:
        _seek(5);
        break;

      case LogicalKeyboardKey.gameButtonStart:
      case LogicalKeyboardKey.contextMenu:
        setState(() => _showSettings = !_showSettings);
        break;
    }
  }

  void _togglePlayPause() {
    ref.read(playerProvider.notifier).playOrPause();
  }

  void _seek(int seconds) {
    final currentPosition = ref.read(playerProvider).position;
    ref
        .read(playerProvider.notifier)
        .seekTo(currentPosition + Duration(seconds: seconds));
  }

  void _adjustVolume(double delta) {
    final currentVolume = ref.read(playerProvider).volume;
    ref
        .read(playerProvider.notifier)
        .setVolume((currentVolume + delta).clamp(0.0, 1.0));
  }

  void _toggleMute() {
    final currentVolume = ref.read(playerProvider).volume;
    ref.read(playerProvider.notifier).setVolume(currentVolume > 0 ? 0 : 1);
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          onEnter: (_) => _onInteraction(forceShow: true),
          onHover: (_) {
            if (!_controlsVisible) {
              _onInteraction(forceShow: true);
            }
          },
          cursor: _controlsVisible
              ? SystemMouseCursors.basic
              : SystemMouseCursors.none,
          child: Listener(
            onPointerDown: (_) => _onInteraction(forceShow: true),
            onPointerSignal: (_) => _onInteraction(forceShow: true),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              onDoubleTap: _toggleFullscreen,
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
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _controlsVisible ? 1.0 : 0.0,
                        duration: AppTheme.durationFast,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.black.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _controlsVisible ? 1.0 : 0.0,
                        duration: AppTheme.durationFast,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.black.withValues(alpha: 0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  PlayerDesktopTopBar(
                    controlsVisible: _controlsVisible,
                    isFullscreen: _isFullscreen,
                    onBack: _onBack,
                    onToggleFullscreen: _toggleFullscreen,
                  ),
                  PlayerDesktopCenterControls(
                    controlsVisible: _controlsVisible,
                    onRewind: () => _seek(-10),
                    onPlayPause: _togglePlayPause,
                    onForward: () => _seek(10),
                  ),
                  PlayerDesktopBottomControls(
                    controlsVisible: _controlsVisible,
                    onToggleSettings: () =>
                        setState(() => _showSettings = !_showSettings),
                  ),
                  PlayerDesktopSettingsPanel(
                    visible: _showSettings,
                    onClose: () => setState(() => _showSettings = false),
                  ),
                  if (playerState.isBuffering)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  const SleepTimerOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
