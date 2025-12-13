import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart' hide NoVideoControls;
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class DesktopPlayer extends ConsumerStatefulWidget {
  const DesktopPlayer({super.key});

  @override
  ConsumerState<DesktopPlayer> createState() => _DesktopPlayerState();
}

class _DesktopPlayerState extends ConsumerState<DesktopPlayer> {
  bool _controlsVisible = true;
  bool _isFullscreen = false;
  bool _showSettings = false;
  DateTime _lastInteraction = DateTime.now();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    _focusNode.requestFocus();
  }

  void _startHideTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted &&
          DateTime.now().difference(_lastInteraction).inSeconds >= 3) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _onInteraction() {
    _lastInteraction = DateTime.now();
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _startHideTimer();
  }

  @override
  void dispose() {
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
          onHover: (_) => _onInteraction(),
          cursor: _controlsVisible
              ? SystemMouseCursors.basic
              : SystemMouseCursors.none,
          child: GestureDetector(
            onTap: _onInteraction,
            onDoubleTap: _toggleFullscreen,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video
                Center(
                  child: Video(
                    controller: videoController,
                    controls: NoVideoControls,
                    fit: BoxFit.contain,
                  ),
                ),

                // Top gradient
                AnimatedOpacity(
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

                // Bottom gradient
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
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
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
              ],
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
      child: AnimatedSlide(
        offset: _controlsVisible ? Offset.zero : const Offset(0, -1),
        duration: AppTheme.durationNormal,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Back button
                GlassIconButton(
                  icon: Icons.arrow_back,
                  onPressed: _onBack,
                ),

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
                  icon:
                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls(PlayerState state) {
    return AnimatedOpacity(
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
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: size * 0.5,
            color: AppColors.white,
          ),
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
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
                  ],
                ),
              ],
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
            Text(
              _formatDuration(position),
              style: AppTextStyles.labelMedium,
            ),
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
              secondaryActiveTrackColor:
                  AppColors.primary.withValues(alpha: 0.3),
            ),
            child: Slider(
              value: position.inMilliseconds.toDouble(),
              min: 0,
              max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              secondaryTrackValue: buffered.inMilliseconds.toDouble(),
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
    return Positioned(
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
                    .map((q) => _buildSettingsOption(
                          q,
                          isSelected: state.currentQuality == q,
                          onTap: () =>
                              ref.read(playerProvider.notifier).setQuality(q),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Audio section
              _buildSettingsSection(
                'Audio',
                state.audioTracks
                        ?.map((track) => _buildSettingsOption(
                              track.displayTitle ?? 'Track ${track.index}',
                              isSelected: state.currentAudioTrack == track,
                              onTap: () => ref
                                  .read(playerProvider.notifier)
                                  .setAudioTrack(track),
                            ))
                        .toList() ??
                    [],
              ),

              const SizedBox(height: 16),

              // Subtitles section
              _buildSettingsSection(
                'Subtitles',
                [
                  _buildSettingsOption(
                    'Off',
                    isSelected: state.currentSubtitleTrack == null,
                    onTap: () =>
                        ref.read(playerProvider.notifier).setSubtitleTrack(null),
                  ),
                  ...?state.subtitleTracks
                      ?.map((track) => _buildSettingsOption(
                            track.displayTitle ?? 'Track ${track.index}',
                            isSelected: state.currentSubtitleTrack == track,
                            onTap: () => ref
                                .read(playerProvider.notifier)
                                .setSubtitleTrack(track),
                          ))
                      .toList(),
                ],
              ),

              const SizedBox(height: 16),

              // Playback speed
              _buildSettingsSection(
                'Speed',
                [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                    .map((speed) => _buildSettingsOption(
                          '${speed}x',
                          isSelected: state.playbackSpeed == speed,
                          onTap: () => ref
                              .read(playerProvider.notifier)
                              .setPlaybackSpeed(speed),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideX(begin: 0.1),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options,
        ),
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

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.keyK:
        _togglePlayPause();
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyJ:
        _seek(-10);
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyL:
        _seek(10);
        break;
      case LogicalKeyboardKey.arrowUp:
        _adjustVolume(0.1);
        break;
      case LogicalKeyboardKey.arrowDown:
        _adjustVolume(-0.1);
        break;
      case LogicalKeyboardKey.keyF:
        _toggleFullscreen();
        break;
      case LogicalKeyboardKey.keyM:
        _toggleMute();
        break;
      case LogicalKeyboardKey.escape:
        if (_isFullscreen) {
          _toggleFullscreen();
        } else {
          _onBack();
        }
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
    // TODO: Implement Picture-in-Picture
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
