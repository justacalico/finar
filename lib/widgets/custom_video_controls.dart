import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/api/models/playback_info.dart';
import 'glass_container.dart';

/// Custom video controls with glassmorphism design
class CustomVideoControls extends StatefulWidget {
  final Player player;
  final VideoController controller;
  final String title;
  final String? subtitle;
  final List<MediaStreamData>? audioTracks;
  final List<MediaStreamData>? subtitleTracks;
  final int? currentAudioTrack;
  final int? currentSubtitleTrack;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final Function(int)? onAudioTrackChanged;
  final Function(int?)? onSubtitleTrackChanged;
  final VoidCallback? onPipTap;
  final VoidCallback? onSettingsTap;
  final bool showNextButton;
  final bool showPreviousButton;
  final Duration? introStart;
  final Duration? introEnd;
  final Duration? creditsStart;

  const CustomVideoControls({
    super.key,
    required this.player,
    required this.controller,
    required this.title,
    this.subtitle,
    this.audioTracks,
    this.subtitleTracks,
    this.currentAudioTrack,
    this.currentSubtitleTrack,
    this.onBack,
    this.onNext,
    this.onPrevious,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
    this.onPipTap,
    this.onSettingsTap,
    this.showNextButton = false,
    this.showPreviousButton = false,
    this.introStart,
    this.introEnd,
    this.creditsStart,
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  bool _showControls = true;
  bool _isLocked = false;
  bool _isSeeking = false;
  Timer? _hideTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;
  double _volume = 1.0;
  double _seekPosition = 0;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _startHideTimer();
  }

  void _setupListeners() {
    widget.player.stream.position.listen((position) {
      if (!_isSeeking && mounted) {
        setState(() => _position = position);
      }
    });

    widget.player.stream.duration.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    widget.player.stream.buffer.listen((buffer) {
      if (mounted) {
        setState(() => _bufferedPosition = buffer);
      }
    });

    widget.player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    widget.player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() => _isBuffering = buffering);
      }
    });

    widget.player.stream.volume.listen((volume) {
      if (mounted) {
        setState(() => _volume = volume / 100);
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (_isPlaying && mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startHideTimer();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _togglePlayPause() {
    widget.player.playOrPause();
    _showControlsTemporarily();
  }

  void _seekRelative(Duration offset) {
    final newPosition = _position + offset;
    final clampedPosition = Duration(
      milliseconds: newPosition.inMilliseconds.clamp(0, _duration.inMilliseconds),
    );
    widget.player.seek(clampedPosition);
    _showControlsTemporarily();
  }

  void _seekTo(double value) {
    final position = Duration(milliseconds: (value * _duration.inMilliseconds).round());
    widget.player.seek(position);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get _showSkipIntro {
    if (widget.introStart == null || widget.introEnd == null) return false;
    return _position >= widget.introStart! && _position <= widget.introEnd!;
  }

  bool get _showSkipCredits {
    if (widget.creditsStart == null) return false;
    return _position >= widget.creditsStart!;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      onDoubleTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final tapX = details.globalPosition.dx;
        
        if (tapX < screenWidth / 3) {
          _seekRelative(const Duration(seconds: -10));
        } else if (tapX > screenWidth * 2 / 3) {
          _seekRelative(const Duration(seconds: 10));
        } else {
          _togglePlayPause();
        }
      },
      onHorizontalDragStart: (_) {
        setState(() {
          _isSeeking = true;
          _seekPosition = _position.inMilliseconds / _duration.inMilliseconds;
        });
      },
      onHorizontalDragUpdate: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final delta = details.delta.dx / screenWidth;
        setState(() {
          _seekPosition = (_seekPosition + delta).clamp(0.0, 1.0);
        });
      },
      onHorizontalDragEnd: (_) {
        _seekTo(_seekPosition);
        setState(() => _isSeeking = false);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          Video(
            controller: widget.controller,
            controls: NoVideoControls,
          ),
          
          // Controls overlay
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: AppTheme.durationNormal,
            child: _isLocked ? _buildLockedOverlay() : _buildControlsOverlay(),
          ),
          
          // Buffering indicator
          if (_isBuffering)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          
          // Skip intro button
          if (_showSkipIntro && _showControls)
            Positioned(
              right: 24,
              bottom: 100,
              child: _buildSkipButton('Skip Intro', () {
                widget.player.seek(widget.introEnd!);
              }),
            ),
          
          // Skip credits button
          if (_showSkipCredits && _showControls && widget.showNextButton)
            Positioned(
              right: 24,
              bottom: 100,
              child: _buildSkipButton('Next Episode', widget.onNext),
            ),
          
          // Center play/pause indicator
          if (!_showControls)
            Center(
              child: AnimatedOpacity(
                opacity: _isPlaying ? 0.0 : 1.0,
                duration: AppTheme.durationFast,
                child: GlassIconButton(
                  icon: Icons.play_arrow,
                  size: 72,
                  iconSize: 40,
                  blur: AppTheme.blurMedium,
                  onPressed: _togglePlayPause,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x80000000),
            Colors.transparent,
            Colors.transparent,
            Color(0x80000000),
          ],
          stops: [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),
            
            // Center controls
            Expanded(
              child: _buildCenterControls(),
            ),
            
            // Bottom bar with seek
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (widget.onPipTap != null)
            GlassIconButton(
              icon: Icons.picture_in_picture_alt,
              onPressed: widget.onPipTap,
            ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: _isLocked ? Icons.lock : Icons.lock_open,
            onPressed: () => setState(() => _isLocked = !_isLocked),
          ),
          if (widget.onSettingsTap != null) ...[
            const SizedBox(width: 8),
            GlassIconButton(
              icon: Icons.settings,
              onPressed: widget.onSettingsTap,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.showPreviousButton)
            GlassIconButton(
              icon: Icons.skip_previous,
              size: 56,
              iconSize: 32,
              onPressed: widget.onPrevious,
            ),
          const SizedBox(width: 24),
          GlassIconButton(
            icon: Icons.replay_10,
            size: 56,
            iconSize: 32,
            onPressed: () => _seekRelative(const Duration(seconds: -10)),
          ),
          const SizedBox(width: 24),
          GlassIconButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            size: 72,
            iconSize: 40,
            backgroundColor: AppColors.primary,
            iconColor: AppColors.black,
            onPressed: _togglePlayPause,
          ),
          const SizedBox(width: 24),
          GlassIconButton(
            icon: Icons.forward_10,
            size: 56,
            iconSize: 32,
            onPressed: () => _seekRelative(const Duration(seconds: 10)),
          ),
          const SizedBox(width: 24),
          if (widget.showNextButton)
            GlassIconButton(
              icon: Icons.skip_next,
              size: 56,
              iconSize: 32,
              onPressed: widget.onNext,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final progress = _duration.inMilliseconds > 0
        ? (_isSeeking ? _seekPosition : _position.inMilliseconds / _duration.inMilliseconds)
        : 0.0;
    
    final bufferedProgress = _duration.inMilliseconds > 0
        ? _bufferedPosition.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    final displayPosition = _isSeeking
        ? Duration(milliseconds: (_seekPosition * _duration.inMilliseconds).round())
        : _position;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          GlassContainer(
            blur: 10,
            opacity: 0.1,
            borderRadius: AppTheme.radiusFull,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Seek bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.glassBorder,
                    thumbColor: AppColors.white,
                    overlayColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  child: Stack(
                    children: [
                      // Buffered progress
                      LinearProgressIndicator(
                        value: bufferedProgress.clamp(0.0, 1.0),
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textTertiary.withValues(alpha: 0.3),
                        ),
                        minHeight: 4,
                      ),
                      // Seek slider
                      Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChangeStart: (_) {
                          setState(() => _isSeeking = true);
                        },
                        onChanged: (value) {
                          setState(() => _seekPosition = value);
                        },
                        onChangeEnd: (value) {
                          _seekTo(value);
                          setState(() => _isSeeking = false);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Time display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(displayPosition),
                      style: AppTextStyles.playerTime,
                    ),
                    Text(
                      '-${_formatDuration(_duration - displayPosition)}',
                      style: AppTextStyles.playerTime,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Bottom controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Audio/Subtitle selectors
              Row(
                children: [
                  if (widget.audioTracks != null && widget.audioTracks!.isNotEmpty)
                    _buildTrackButton(
                      icon: Icons.audiotrack,
                      label: 'Audio',
                      onTap: () => _showAudioTrackPicker(),
                    ),
                  const SizedBox(width: 12),
                  if (widget.subtitleTracks != null)
                    _buildTrackButton(
                      icon: Icons.subtitles,
                      label: 'Subtitles',
                      onTap: () => _showSubtitleTrackPicker(),
                    ),
                ],
              ),
              // Volume
              Row(
                children: [
                  GlassIconButton(
                    icon: _volume == 0 ? Icons.volume_off : Icons.volume_up,
                    size: 36,
                    iconSize: 20,
                    onPressed: () {
                      widget.player.setVolume(_volume == 0 ? 100 : 0);
                    },
                  ),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: _volume,
                      onChanged: (value) {
                        widget.player.setVolume(value * 100);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return Center(
      child: GlassIconButton(
        icon: Icons.lock,
        size: 64,
        iconSize: 32,
        onPressed: () => setState(() => _isLocked = false),
      ),
    );
  }

  Widget _buildSkipButton(String label, VoidCallback? onTap) {
    return GlassButton(
      onPressed: onTap,
      backgroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(color: AppColors.black),
      ),
    );
  }

  Widget _buildTrackButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassButton(
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }

  void _showAudioTrackPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TrackPickerSheet(
        title: 'Audio Track',
        tracks: widget.audioTracks!,
        selectedIndex: widget.currentAudioTrack,
        onSelected: (index) {
          if (index != null) {
            widget.onAudioTrackChanged?.call(index);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSubtitleTrackPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TrackPickerSheet(
        title: 'Subtitles',
        tracks: widget.subtitleTracks!,
        selectedIndex: widget.currentSubtitleTrack,
        allowNone: true,
        onSelected: (index) {
          widget.onSubtitleTrackChanged?.call(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _TrackPickerSheet extends StatelessWidget {
  final String title;
  final List<MediaStreamData> tracks;
  final int? selectedIndex;
  final bool allowNone;
  final Function(int?) onSelected;

  const _TrackPickerSheet({
    required this.title,
    required this.tracks,
    this.selectedIndex,
    this.allowNone = false,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: AppColors.surface.withValues(alpha: 0.9),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(title, style: AppTextStyles.titleLarge),
                const SizedBox(height: 16),
                if (allowNone)
                  _buildTrackTile(
                    title: 'Off',
                    isSelected: selectedIndex == null,
                    onTap: () => onSelected(null),
                  ),
                ...tracks.map((track) => _buildTrackTile(
                      title: track.displayName,
                      subtitle: track.codec?.toUpperCase(),
                      isSelected: selectedIndex == track.index,
                      onTap: () => onSelected(track.index),
                    )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackTile({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? AppColors.primary : AppColors.textTertiary,
      ),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTextStyles.caption)
          : null,
    );
  }
}

/// Empty controls for Video widget
Widget noVideoControls(VideoState state) => const SizedBox.shrink();
