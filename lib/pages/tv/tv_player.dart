import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart' hide NoVideoControls;
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

class TvPlayer extends ConsumerStatefulWidget {
  const TvPlayer({super.key});

  @override
  ConsumerState<TvPlayer> createState() => _TvPlayerState();
}

class _TvPlayerState extends ConsumerState<TvPlayer> {
  final FocusNode _focusNode = FocusNode();
  bool _controlsVisible = true;
  bool _showSettings = false;
  int _selectedControlIndex = 2; // Play/pause by default
  int _selectedSettingIndex = 0;
  DateTime _lastInteraction = DateTime.now();

  final List<_ControlItem> _controls = [
    _ControlItem(Icons.skip_previous, 'Previous'),
    _ControlItem(Icons.replay_10, 'Rewind'),
    _ControlItem(Icons.play_arrow, 'Play'),
    _ControlItem(Icons.forward_10, 'Forward'),
    _ControlItem(Icons.skip_next, 'Next'),
    _ControlItem(Icons.settings, 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _startHideTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted &&
          DateTime.now().difference(_lastInteraction).inSeconds >= 5 &&
          !_showSettings) {
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

    // Update play/pause icon
    _controls[2] = _ControlItem(
      playerState.isPlaying ? Icons.pause : Icons.play_arrow,
      playerState.isPlaying ? 'Pause' : 'Play',
    );

    if (videoController == null) {
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

            // Controls overlay
            AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: AppTheme.durationNormal,
              child: _buildControlsOverlay(playerState),
            ),

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
    );
  }

  Widget _buildControlsOverlay(PlayerState state) {
    return Stack(
      children: [
        // Top gradient
        Container(
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

        // Bottom gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 250,
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

        // Top bar
        _buildTopBar(state),

        // Bottom controls
        _buildBottomControls(state),
      ],
    );
  }

  Widget _buildTopBar(PlayerState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          children: [
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.currentItem?.name ?? 'Now Playing',
                    style: AppTextStyles.headlineMedium,
                  ),
                  if (state.currentItem?.seriesName != null)
                    Text(
                      '${state.currentItem!.seriesName} • S${state.currentItem!.parentIndexNumber}E${state.currentItem!.indexNumber}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Time remaining
            Text(
              '-${_formatDuration(state.duration - state.position)}',
              style: AppTextStyles.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(PlayerState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Progress bar
            _buildProgressBar(state),

            const SizedBox(height: 24),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _controls.asMap().entries.map((entry) {
                final index = entry.key;
                final control = entry.value;
                final isSelected =
                    !_showSettings && _selectedControlIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AnimatedContainer(
                    duration: AppTheme.durationFast,
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.glassBackground,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.glassBorder,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      control.icon,
                      size: index == 2 ? 36 : 28,
                      color: isSelected ? AppColors.black : AppColors.white,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Control label
            Text(
              _controls[_selectedControlIndex].label,
              style: AppTextStyles.labelMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(PlayerState state) {
    final position = state.position;
    final duration = state.duration;

    return Column(
      children: [
        // Time row
        Row(
          children: [
            Text(
              _formatDuration(position),
              style: AppTextStyles.labelMedium,
            ),
            const Spacer(),
            Text(
              _formatDuration(duration),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: AppColors.divider,
          ),
          child: Stack(
            children: [
              // Buffered
              FractionallySizedBox(
                widthFactor: duration.inMilliseconds > 0
                    ? state.bufferedPosition.inMilliseconds /
                        duration.inMilliseconds
                    : 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),

              // Progress
              FractionallySizedBox(
                widthFactor: duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel(PlayerState state) {
    final settings = [
      _SettingItem('Quality', state.currentQuality ?? 'Auto'),
      _SettingItem('Audio', state.currentAudioTrack?.displayTitle ?? 'Default'),
      _SettingItem(
        'Subtitles',
        state.currentSubtitleTrack?.displayTitle ?? 'Off',
      ),
      _SettingItem('Speed', '${state.playbackSpeed}x'),
    ];

    return Positioned(
      right: 32,
      top: 0,
      bottom: 0,
      child: Center(
        child: GlassContainer(
          blur: AppTheme.blurHeavy,
          opacity: 0.15,
          borderRadius: AppTheme.radiusLg,
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: AppTextStyles.titleLarge),
                const SizedBox(height: 24),
                ...settings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final setting = entry.value;
                  final isSelected = _selectedSettingIndex == index;

                  return AnimatedContainer(
                    duration: AppTheme.durationFast,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Text(
                          setting.label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected
                                ? AppColors.black
                                : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          setting.value,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.black
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: isSelected
                              ? AppColors.black
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
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

    setState(() {
      if (_showSettings) {
        _handleSettingsKeyEvent(event);
      } else {
        _handleControlsKeyEvent(event);
      }
    });
  }

  void _handleControlsKeyEvent(KeyEvent event) {
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (_selectedControlIndex > 0) {
          _selectedControlIndex--;
        } else {
          _seek(-10);
        }
        break;

      case LogicalKeyboardKey.arrowRight:
        if (_selectedControlIndex < _controls.length - 1) {
          _selectedControlIndex++;
        } else {
          _seek(10);
        }
        break;

      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _executeControl(_selectedControlIndex);
        break;

      case LogicalKeyboardKey.mediaPlayPause:
        _togglePlayPause();
        break;

      case LogicalKeyboardKey.mediaRewind:
        _seek(-10);
        break;

      case LogicalKeyboardKey.mediaFastForward:
        _seek(10);
        break;

      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.escape:
        _onBack();
        break;
    }
  }

  void _handleSettingsKeyEvent(KeyEvent event) {
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        if (_selectedSettingIndex > 0) {
          _selectedSettingIndex--;
        }
        break;

      case LogicalKeyboardKey.arrowDown:
        if (_selectedSettingIndex < 3) {
          _selectedSettingIndex++;
        }
        break;

      case LogicalKeyboardKey.arrowLeft:
        _cycleSettingValue(_selectedSettingIndex, -1);
        break;

      case LogicalKeyboardKey.arrowRight:
        _cycleSettingValue(_selectedSettingIndex, 1);
        break;

      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _cycleSettingValue(_selectedSettingIndex, 1);
        break;

      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.escape:
        _showSettings = false;
        break;
    }
  }

  void _executeControl(int index) {
    switch (index) {
      case 0: // Previous
        _playPrevious();
        break;
      case 1: // Rewind
        _seek(-10);
        break;
      case 2: // Play/Pause
        _togglePlayPause();
        break;
      case 3: // Forward
        _seek(10);
        break;
      case 4: // Next
        _playNext();
        break;
      case 5: // Settings
        _showSettings = true;
        _selectedSettingIndex = 0;
        break;
    }
  }

  void _cycleSettingValue(int settingIndex, int direction) {
    switch (settingIndex) {
      case 0: // Quality
        // Cycle through available qualities
        final qualities =
            ref.read(playerProvider).availableQualities ?? ['Auto'];
        final current = ref.read(playerProvider).currentQuality ?? 'Auto';
        final currentIndex = qualities.indexOf(current);
        final newIndex =
            (currentIndex + direction).clamp(0, qualities.length - 1);
        ref.read(playerProvider.notifier).setQuality(qualities[newIndex]);
        break;

      case 1: // Audio
        final tracks = ref.read(playerProvider).audioTracks ?? [];
        if (tracks.isEmpty) break;
        final current = ref.read(playerProvider).currentAudioTrack;
        final currentIndex =
            current != null ? tracks.indexOf(current) : 0;
        final newIndex =
            (currentIndex + direction).clamp(0, tracks.length - 1);
        ref.read(playerProvider.notifier).setAudioTrack(tracks[newIndex]);
        break;

      case 2: // Subtitles
        final tracks = ref.read(playerProvider).subtitleTracks ?? [];
        final current = ref.read(playerProvider).currentSubtitleTrack;
        if (current == null && direction < 0) break;
        if (current == null) {
          if (tracks.isNotEmpty) {
            ref.read(playerProvider.notifier).setSubtitleTrack(tracks[0]);
          }
        } else {
          final currentIndex = tracks.indexOf(current);
          if (currentIndex == 0 && direction < 0) {
            ref.read(playerProvider.notifier).setSubtitleTrack(null);
          } else {
            final newIndex =
                (currentIndex + direction).clamp(0, tracks.length - 1);
            ref.read(playerProvider.notifier).setSubtitleTrack(tracks[newIndex]);
          }
        }
        break;

      case 3: // Speed
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
        final current = ref.read(playerProvider).playbackSpeed;
        final currentIndex = speeds.indexOf(current);
        final newIndex =
            (currentIndex + direction).clamp(0, speeds.length - 1);
        ref.read(playerProvider.notifier).setPlaybackSpeed(speeds[newIndex]);
        break;
    }
  }

  void _togglePlayPause() {
    final playerNotifier = ref.read(playerProvider.notifier);
    final isPlaying = ref.read(playerProvider).isPlaying;
    if (isPlaying) {
      playerNotifier.pause();
    } else {
      playerNotifier.resume();
    }
  }

  void _seek(int seconds) {
    final currentPosition = ref.read(playerProvider).position;
    ref
        .read(playerProvider.notifier)
        .seekTo(currentPosition + Duration(seconds: seconds));
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

class _ControlItem {
  final IconData icon;
  final String label;

  _ControlItem(this.icon, this.label);
}

class _SettingItem {
  final String label;
  final String value;

  _SettingItem(this.label, this.value);
}
