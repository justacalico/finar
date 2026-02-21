import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../core/api/models/media_item.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Cross-platform video player. Desktop: keyboard/mouse; Mobile: touch gestures, brightness/volume.
class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveLayout(
      desktopBuilder: () => const _PlayerDesktop(),
      mobileBuilder: () => const _PlayerMobile(),
    );
  }
}

class _PlayerDesktop extends ConsumerStatefulWidget {
  const _PlayerDesktop();

  @override
  ConsumerState<_PlayerDesktop> createState() => _PlayerDesktopState();
}

class _PlayerDesktopState extends ConsumerState<_PlayerDesktop> {
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

  @override
  void dispose() {
    _hideTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final videoController = ref.watch(videoControllerProvider);

    // Loading state
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
                  // Video
                  Center(
                    child: RepaintBoundary(
                      child: Video(
                        controller: videoController,
                        controls: noVideoControls,
                        fit: BoxFit.contain,
                        // Optimize texture filtering for performance
                        filterQuality: FilterQuality.medium,
                        // Keep screen awake during playback
                        wakelock: true,
                      ),
                    ),
                  ),

                  // Top gradient (visual only, no interaction)
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

                  // Bottom gradient (visual only, no interaction)
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

                  // Top bar
                  _buildTopBar(playerState),

                  // Center play/pause
                  _buildCenterControls(playerState),

                  // Bottom controls
                  _buildBottomControls(playerState),

                  // Settings panel
                  if (_showSettings) _buildSettingsPanel(playerState),

                  // Loading indicator
                  if (playerState.isBuffering)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(PlayerState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: AnimatedOpacity(
          opacity: _controlsVisible ? 1.0 : 0.0,
          duration: AppTheme.durationFast,
          child: AnimatedSlide(
            offset: _controlsVisible ? Offset.zero : const Offset(0, -1),
            duration: AppTheme.durationNormal,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Back button
                    GlassIconButton(icon: Icons.arrow_back, onPressed: _onBack),

                    const SizedBox(width: 16),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.currentItem?.name ?? 'Now Playing',
                            style: AppTextStyles.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (state.currentItem?.seriesName != null)
                            Text(
                              '${state.currentItem!.seriesName} • S${state.currentItem!.parentIndexNumber}E${state.currentItem!.indexNumber}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Pip button
                    GlassIconButton(
                      icon: Icons.picture_in_picture_alt,
                      onPressed: _togglePip,
                    ),

                    const SizedBox(width: 8),

                    // Fullscreen button
                    GlassIconButton(
                      icon: _isFullscreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                      onPressed: _toggleFullscreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls(PlayerState state) {
    return IgnorePointer(
      ignoring: !_controlsVisible,
      child: AnimatedOpacity(
        opacity: _controlsVisible ? 1.0 : 0.0,
        duration: AppTheme.durationFast,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind 10s
              _buildCenterButton(
                icon: Icons.replay_10,
                onPressed: () => _seek(-10),
                size: 48,
              ),

              const SizedBox(width: 32),

              // Play/Pause
              _buildCenterButton(
                icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
                onPressed: _togglePlayPause,
                size: 72,
                isPrimary: true,
              ),

              const SizedBox(width: 32),

              // Forward 10s
              _buildCenterButton(
                icon: Icons.forward_10,
                onPressed: () => _seek(10),
                size: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 48,
    bool isPrimary = false,
  }) {
    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPrimary
                    ? AppColors.glassBackground
                    : AppColors.glassBackground.withValues(alpha: 0.3),
                border: Border.all(color: AppColors.glassBorder, width: 1),
              ),
              child: Icon(icon, size: size * 0.5, color: AppColors.white),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(
          delay: 2.seconds,
          duration: 1.seconds,
          color: AppColors.white.withValues(alpha: 0.1),
        );
  }

  Widget _buildBottomControls(PlayerState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: AnimatedOpacity(
          opacity: _controlsVisible ? 1.0 : 0.0,
          duration: AppTheme.durationFast,
          child: AnimatedSlide(
            offset: _controlsVisible ? Offset.zero : const Offset(0, 1),
            duration: AppTheme.durationNormal,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar
                    _buildProgressBar(state),

                    const SizedBox(height: 16),

                    // Control buttons row
                    Row(
                      children: [
                        // Volume
                        _buildVolumeControl(state),

                        const Spacer(),

                        // Skip previous
                        if (state.hasPrevious)
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            onPressed: _playPrevious,
                          ),

                        // Skip next
                        if (state.hasNext)
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            onPressed: _playNext,
                          ),

                        const SizedBox(width: 16),

                        // Subtitles
                        GlassIconButton(
                          icon: Icons.subtitles,
                          iconColor: state.currentSubtitleTrack != null
                              ? AppColors.primary
                              : null,
                          onPressed: () =>
                              setState(() => _showSettings = !_showSettings),
                        ),

                        const SizedBox(width: 8),

                        // Audio tracks
                        GlassIconButton(
                          icon: Icons.audiotrack,
                          onPressed: () =>
                              setState(() => _showSettings = !_showSettings),
                        ),

                        const SizedBox(width: 8),

                        // Quality
                        GlassIconButton(
                          icon: Icons.settings,
                          onPressed: () =>
                              setState(() => _showSettings = !_showSettings),
                        ),

                        // Queue next episode (only for TV episodes)
                        if (state.currentItem?.type == MediaType.episode) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Queue next episode',
                            child: GlassIconButton(
                              icon: Icons.playlist_add,
                              onPressed: () => _queueNextEpisode(state),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(PlayerState state) {
    final position = state.position;
    final duration = state.duration;
    final buffered = state.bufferedPosition;

    return Column(
      children: [
        Row(
          children: [
            Text(_formatDuration(position), style: AppTextStyles.labelMedium),
            const Spacer(),
            Text(
              '-${_formatDuration(duration - position)}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 24,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              secondaryActiveTrackColor: AppColors.primary.withValues(
                alpha: 0.3,
              ),
            ),
            child: Slider(
              value: position.inMilliseconds.toDouble().clamp(
                0,
                duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              ),
              min: 0,
              max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              secondaryTrackValue: buffered.inMilliseconds.toDouble().clamp(
                0,
                duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              ),
              onChanged: (value) {
                ref
                    .read(playerProvider.notifier)
                    .seekTo(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
        ),

        // Chapter markers (if available)
        if (state.chapters?.isNotEmpty == true)
          _buildChapterMarkers(state, duration),
      ],
    );
  }

  Widget _buildChapterMarkers(PlayerState state, Duration duration) {
    return SizedBox(
      height: 20,
      child: Stack(
        children: state.chapters!.map((chapter) {
          final position =
              chapter.startPositionTicks / (duration.inMicroseconds * 10);
          return Positioned(
            left: position * MediaQuery.of(context).size.width * 0.9,
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

  Widget _buildVolumeControl(PlayerState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            state.volume == 0
                ? Icons.volume_off
                : state.volume < 0.5
                ? Icons.volume_down
                : Icons.volume_up,
          ),
          onPressed: _toggleMute,
        ),
        SizedBox(
          width: 100,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              activeTrackColor: AppColors.white,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.white,
              overlayColor: Colors.transparent,
            ),
            child: Slider(
              value: state.volume,
              min: 0,
              max: 1,
              onChanged: (value) {
                ref.read(playerProvider.notifier).setVolume(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel(PlayerState state) {
    return Stack(
      children: [
        // Dismiss barrier - closes panel when tapping outside
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _showSettings = false),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Settings panel
        Positioned(
          right: 24,
          bottom: 120,
          child: GlassContainer(
            blur: AppTheme.blurHeavy,
            opacity: 0.15,
            borderRadius: AppTheme.radiusLg,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Text('Settings', style: AppTextStyles.titleMedium),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() => _showSettings = false),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Quality section
                  _buildSettingsSection(
                    'Quality',
                    state.availableQualities
                        .map(
                          (q) => _buildSettingsOption(
                            q,
                            isSelected: state.currentQuality == q,
                            onTap: () =>
                                ref.read(playerProvider.notifier).setQuality(q),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 16),

                  // Audio section
                  _buildSettingsSection(
                    'Audio',
                    state.audioTracks
                            ?.map(
                              (track) => _buildSettingsOption(
                                track.displayTitle ?? 'Track ${track.index}',
                                isSelected:
                                    state.currentAudioTrack == track.index,
                                onTap: () => ref
                                    .read(playerProvider.notifier)
                                    .setAudioTrack(track.index),
                              ),
                            )
                            .toList() ??
                        [],
                  ),

                  const SizedBox(height: 16),

                  // Subtitles section
                  _buildSettingsSection('Subtitles', [
                    _buildSettingsOption(
                      'Off',
                      isSelected: state.currentSubtitleTrack == null,
                      onTap: () => ref
                          .read(playerProvider.notifier)
                          .setSubtitleTrack(null),
                    ),
                    if (state.subtitleTracks != null)
                      ...state.subtitleTracks!.map(
                        (track) => _buildSettingsOption(
                          track.displayTitle ?? 'Track ${track.index}',
                          isSelected: state.currentSubtitleTrack == track.index,
                          onTap: () => ref
                              .read(playerProvider.notifier)
                              .setSubtitleTrack(track.index),
                        ),
                      ),
                  ]),

                  const SizedBox(height: 16),

                  // Playback speed
                  _buildSettingsSection(
                    'Speed',
                    [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                        .map(
                          (speed) => _buildSettingsOption(
                            '${speed}x',
                            isSelected: state.playbackSpeed == speed,
                            onTap: () => ref
                                .read(playerProvider.notifier)
                                .setPlaybackSpeed(speed),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideX(begin: 0.1),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> options) {
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
        Wrap(spacing: 8, runSpacing: 8, children: options),
      ],
    );
  }

  Widget _buildSettingsOption(
    String label, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? AppColors.black : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    _onInteraction();

    final key = event.logicalKey;

    switch (key) {
      // Play/Pause - keyboard and gamepad
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.keyK:
      case LogicalKeyboardKey.mediaPlayPause:
      case LogicalKeyboardKey.mediaPlay:
      case LogicalKeyboardKey.mediaPause:
      case LogicalKeyboardKey.gameButtonA: // A button / South button
        _togglePlayPause();
        break;

      // Seek backward
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyJ:
      case LogicalKeyboardKey.mediaRewind:
        _seek(-10);
        break;

      // Seek forward
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyL:
      case LogicalKeyboardKey.mediaFastForward:
        _seek(10);
        break;

      // Volume up
      case LogicalKeyboardKey.arrowUp:
        _adjustVolume(0.1);
        break;

      // Volume down
      case LogicalKeyboardKey.arrowDown:
        _adjustVolume(-0.1);
        break;

      // Toggle fullscreen
      case LogicalKeyboardKey.keyF:
      case LogicalKeyboardKey
          .gameButtonY: // Y button / North button for fullscreen
        _toggleFullscreen();
        break;

      // Toggle mute
      case LogicalKeyboardKey.keyM:
        _toggleMute();
        break;

      // Back/Exit
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.gameButtonB: // B button / East button
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.browserBack:
        if (_isFullscreen) {
          _toggleFullscreen();
        } else {
          _onBack();
        }
        break;

      // Shoulder buttons for seeking (larger jumps)
      case LogicalKeyboardKey.gameButtonLeft1: // L1/LB - seek back 30s
      case LogicalKeyboardKey.pageUp:
        _seek(-30);
        break;
      case LogicalKeyboardKey.gameButtonRight1: // R1/RB - seek forward 30s
      case LogicalKeyboardKey.pageDown:
        _seek(30);
        break;

      // Triggers for fine seeking
      case LogicalKeyboardKey.gameButtonLeft2: // L2/LT - seek back 5s
        _seek(-5);
        break;
      case LogicalKeyboardKey.gameButtonRight2: // R2/RT - seek forward 5s
        _seek(5);
        break;

      // Start/Menu button - show controls/settings
      case LogicalKeyboardKey.gameButtonStart:
      case LogicalKeyboardKey.contextMenu:
        setState(() => _showSettings = !_showSettings);
        break;
    }
  }

  void _togglePlayPause() {
    final playerNotifier = ref.read(playerProvider.notifier);
    playerNotifier.playOrPause();
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
    final playerNotifier = ref.read(playerProvider.notifier);
    final currentVolume = ref.read(playerProvider).volume;
    playerNotifier.setVolume(currentVolume > 0 ? 0 : 1);
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _togglePip() {
    // On desktop, "Picture-in-Picture" mode exits the fullscreen player
    // while keeping playback active. The user returns to the main UI where
    // they can continue browsing while the video plays in the background.
    // A mini-player bar at the bottom allows control over playback.
    //
    // Note: True floating PiP windows require native platform support
    // which isn't available cross-platform in Flutter desktop yet.

    // Reset fullscreen mode if active
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    // Navigate back - playback continues via the player provider
    // The home screen will show the mini player bar for video content
    Navigator.of(context).pop();
  }

  void _playPrevious() {
    ref.read(playerProvider.notifier).playPrevious();
  }

  void _playNext() {
    ref.read(playerProvider.notifier).playNext();
  }

  Future<void> _queueNextEpisode(PlayerState state) async {
    final success = await ref.read(playerProvider.notifier).queueNextEpisode();
    if (mounted) {
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

  void _onBack() {
    ref.read(playerProvider.notifier).stop();
    Navigator.of(context).pop();
  }
}

class _PlayerMobile extends ConsumerStatefulWidget {
  const _PlayerMobile();

  @override
  ConsumerState<_PlayerMobile> createState() => _PlayerMobileState();
}

class _PlayerMobileState extends ConsumerState<_PlayerMobile> {
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

  @override
  void initState() {
    super.initState();
    _enterFullscreen();
    _startHideTimer();
    _initBrightness();
  }

  Future<void> _initBrightness() async {
    try {
      final brightness = await ScreenBrightness.instance.application;
      if (mounted) {
        setState(() => _brightness = brightness);
      }
    } catch (e) {
      // Fallback to system brightness or default
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

  @override
  void dispose() {
    _resetBrightness();
    _exitFullscreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final videoController = ref.watch(videoControllerProvider);

    // Loading state
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
            // Video
            Center(
              child: RepaintBoundary(
                child: Video(
                  controller: videoController,
                  controls: noVideoControls,
                  fit: BoxFit.contain,
                  // Optimize texture filtering for performance
                  filterQuality: FilterQuality.medium,
                  // Keep screen awake during playback
                  wakelock: true,
                ),
              ),
            ),

            // Locked indicator
            if (_isLocked)
              _buildLockedOverlay()
            else ...[
              // Top controls
              _buildTopControls(playerState),

              // Center controls
              _buildCenterControls(playerState),

              // Bottom controls
              _buildBottomControls(playerState),

              // Settings panel
              if (_showSettings) _buildSettingsPanel(playerState),
            ],

            // Brightness indicator
            if (_showBrightness) _buildBrightnessIndicator(),

            // Volume indicator
            if (_showVolume) _buildVolumeIndicator(playerState),

            // Loading indicator
            if (playerState.isBuffering)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),

            // Seek indicator (for double tap)
            _buildSeekIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => setState(() => _isLocked = false),
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

  Widget _buildTopControls(PlayerState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: AnimatedOpacity(
          opacity: _controlsVisible ? 1.0 : 0.0,
          duration: AppTheme.durationFast,
          child: AnimatedSlide(
            offset: _controlsVisible ? Offset.zero : const Offset(0, -1),
            duration: AppTheme.durationNormal,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
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
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _onBack,
                  ),

                  const SizedBox(width: 8),

                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.currentItem?.name ?? 'Now Playing',
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (state.currentItem?.seriesName != null)
                          Text(
                            '${state.currentItem!.seriesName} • S${state.currentItem!.parentIndexNumber}E${state.currentItem!.indexNumber}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Lock button
                  IconButton(
                    icon: const Icon(Icons.lock_outline),
                    onPressed: () => setState(() {
                      _isLocked = true;
                      _controlsVisible = false;
                    }),
                  ),

                  // Queue next episode button (only for TV episodes)
                  if (state.currentItem?.type == MediaType.episode)
                    IconButton(
                      icon: const Icon(Icons.playlist_add),
                      tooltip: 'Queue next episode',
                      onPressed: () => _queueNextEpisode(state),
                    ),

                  // Settings button
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () =>
                        setState(() => _showSettings = !_showSettings),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls(PlayerState state) {
    return IgnorePointer(
      ignoring: !_controlsVisible,
      child: AnimatedOpacity(
        opacity: _controlsVisible ? 1.0 : 0.0,
        duration: AppTheme.durationFast,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous
              if (state.hasPrevious)
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 36),
                  onPressed: _playPrevious,
                ),

              const SizedBox(width: 24),

              // Rewind
              _buildCenterButton(
                icon: Icons.replay_10,
                onPressed: () => _seek(-10),
              ),

              const SizedBox(width: 16),

              // Play/Pause
              _buildCenterButton(
                icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
                onPressed: _togglePlayPause,
                size: 64,
                isPrimary: true,
              ),

              const SizedBox(width: 16),

              // Forward
              _buildCenterButton(
                icon: Icons.forward_10,
                onPressed: () => _seek(10),
              ),

              const SizedBox(width: 24),

              // Next
              if (state.hasNext)
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 36),
                  onPressed: _playNext,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 48,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPrimary
                ? AppColors.white.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          child: Icon(icon, size: size * 0.6, color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildBottomControls(PlayerState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: AnimatedOpacity(
          opacity: _controlsVisible ? 1.0 : 0.0,
          duration: AppTheme.durationFast,
          child: AnimatedSlide(
            offset: _controlsVisible ? Offset.zero : const Offset(0, 1),
            duration: AppTheme.durationNormal,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
                left: 16,
                right: 16,
                top: 16,
              ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  _buildProgressBar(state),

                  const SizedBox(height: 8),

                  // Bottom buttons row
                  Row(
                    children: [
                      // Time
                      Text(
                        '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
                        style: AppTextStyles.labelSmall,
                      ),

                      const Spacer(),

                      // Playback speed
                      GestureDetector(
                        onTap: _cyclePlaybackSpeed,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${state.playbackSpeed}x',
                            style: AppTextStyles.labelSmall,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Subtitles
                      IconButton(
                        icon: Icon(
                          Icons.subtitles,
                          color: state.currentSubtitleTrack != null
                              ? AppColors.primary
                              : null,
                        ),
                        onPressed: () =>
                            setState(() => _showSettings = !_showSettings),
                      ),

                      // Rotate
                      IconButton(
                        icon: const Icon(Icons.screen_rotation),
                        onPressed: _rotateScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(PlayerState state) {
    final position = state.position;
    final duration = state.duration;

    return SizedBox(
      height: 32,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.divider,
          thumbColor: AppColors.primary,
          overlayColor: AppColors.primary.withValues(alpha: 0.2),
          secondaryActiveTrackColor: AppColors.primary.withValues(alpha: 0.3),
        ),
        child: Slider(
          value: position.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble().clamp(1, double.infinity)),
          min: 0,
          max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
          secondaryTrackValue: state.bufferedPosition.inMilliseconds.toDouble().clamp(0, duration.inMilliseconds.toDouble().clamp(1, double.infinity)),
          onChanged: (value) {
            ref
                .read(playerProvider.notifier)
                .seekTo(Duration(milliseconds: value.toInt()));
          },
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(PlayerState state) {
    return Stack(
      children: [
        // Dismiss barrier - closes panel when tapping outside
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _showSettings = false),
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Settings panel
        Positioned(
          right: 16,
          bottom: 100,
          child: GlassContainer(
            blur: AppTheme.blurHeavy,
            opacity: 0.15,
            borderRadius: AppTheme.radiusMd,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 250,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quality
                  Text(
                    'Quality',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.availableQualities
                        .map(
                          (q) => _buildSettingOption(
                            q,
                            isSelected: state.currentQuality == q,
                            onTap: () =>
                                ref.read(playerProvider.notifier).setQuality(q),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 16),

                  // Audio
                  Text(
                    'Audio',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        state.audioTracks
                            ?.map(
                              (track) => _buildSettingOption(
                                track.displayTitle ?? 'Track ${track.index}',
                                isSelected:
                                    state.currentAudioTrack == track.index,
                                onTap: () => ref
                                    .read(playerProvider.notifier)
                                    .setAudioTrack(track.index),
                              ),
                            )
                            .toList() ??
                        [],
                  ),

                  const SizedBox(height: 16),

                  // Subtitles
                  Text(
                    'Subtitles',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSettingOption(
                        'Off',
                        isSelected: state.currentSubtitleTrack == null,
                        onTap: () => ref
                            .read(playerProvider.notifier)
                            .setSubtitleTrack(null),
                      ),
                      if (state.subtitleTracks != null)
                        ...state.subtitleTracks!.map(
                          (track) => _buildSettingOption(
                            track.displayTitle ?? 'Track ${track.index}',
                            isSelected:
                                state.currentSubtitleTrack == track.index,
                            onTap: () => ref
                                .read(playerProvider.notifier)
                                .setSubtitleTrack(track.index),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideX(begin: 0.1),
        ),
      ],
    );
  }

  Widget _buildSettingOption(
    String label, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? AppColors.black : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBrightnessIndicator() {
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
                    value: _brightness,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_brightness * 100).toInt()}%',
                style: AppTextStyles.labelSmall,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(),
    );
  }

  Widget _buildVolumeIndicator(PlayerState state) {
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

  // Double tap seek indicator state
  int _seekAmount = 0;
  bool _showLeftSeek = false;
  bool _showRightSeek = false;

  Widget _buildSeekIndicator() {
    return Row(
      children: [
        // Left seek indicator
        Expanded(
          child: AnimatedOpacity(
            opacity: _showLeftSeek ? 1.0 : 0.0,
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
                    Text('$_seekAmount sec', style: AppTextStyles.labelSmall),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right seek indicator
        Expanded(
          child: AnimatedOpacity(
            opacity: _showRightSeek ? 1.0 : 0.0,
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
                    Text('+$_seekAmount sec', style: AppTextStyles.labelSmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleDoubleTap(TapDownDetails details, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    if (tapX < screenWidth / 3) {
      // Double tap left - seek backward
      _seek(-10);
      setState(() {
        _seekAmount = 10;
        _showLeftSeek = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showLeftSeek = false);
      });
    } else if (tapX > screenWidth * 2 / 3) {
      // Double tap right - seek forward
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

  void _handleHorizontalDragEnd(DragEndDetails details) {
    // Seek is already applied during drag
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _togglePlayPause() {
    final playerNotifier = ref.read(playerProvider.notifier);
    playerNotifier.playOrPause();
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

  void _playPrevious() {
    ref.read(playerProvider.notifier).playPrevious();
  }

  void _playNext() {
    ref.read(playerProvider.notifier).playNext();
  }

  Future<void> _queueNextEpisode(PlayerState state) async {
    final success = await ref.read(playerProvider.notifier).queueNextEpisode();
    if (mounted) {
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

  void _onBack() {
    ref.read(playerProvider.notifier).stop();
    Navigator.of(context).pop();
  }
}
