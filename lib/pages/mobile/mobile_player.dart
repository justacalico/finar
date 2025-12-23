import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class MobilePlayer extends ConsumerStatefulWidget {
  const MobilePlayer({super.key});

  @override
  ConsumerState<MobilePlayer> createState() => _MobilePlayerState();
}

class _MobilePlayerState extends ConsumerState<MobilePlayer> {
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
          value: position.inMilliseconds.toDouble(),
          min: 0,
          max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
          secondaryTrackValue: state.bufferedPosition.inMilliseconds.toDouble(),
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
    return Positioned(
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
                            isSelected: state.currentAudioTrack == track.index,
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
                        isSelected: state.currentSubtitleTrack == track.index,
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

  void _onBack() {
    ref.read(playerProvider.notifier).stop();
    Navigator.of(context).pop();
  }
}
