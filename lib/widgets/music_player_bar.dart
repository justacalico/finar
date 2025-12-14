import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/api/models/media_item.dart';
import '../providers/providers.dart';
import '../providers/library_provider.dart';
import 'glass_container.dart';
import 'queue_view.dart';

/// Mini music player bar for mobile - shows at bottom with expandable controls
class MobileMiniPlayer extends ConsumerWidget {
  final VoidCallback? onTap;
  final VoidCallback? onExpand;

  const MobileMiniPlayer({
    super.key,
    this.onTap,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    if (playerState.currentItem == null) {
      return const SizedBox.shrink();
    }

    final item = playerState.currentItem!;
    final isMusic = item.type.name == 'audio' || item.type.name == 'album';

    // Only show for music content
    if (!isMusic) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onExpand,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
          onExpand?.call();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: GlassContainer(
          blur: AppTheme.blurMedium,
          opacity: 0.15,
          borderRadius: AppTheme.radiusMd,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar at top
              LinearProgressIndicator(
                value: playerState.progress,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 2,
              ),
              
              // Player content
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.network(
                          item.getPrimaryImageUrl(serverUrl, width: 100),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.surface,
                            child: const Icon(
                              Icons.music_note,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Track info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.name,
                            style: AppTextStyles.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.artists?.isNotEmpty == true ||
                              item.albumArtist != null)
                            Text(
                              item.albumArtist ?? item.artists?.first ?? '',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    
                    // Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Favorite
                        _FavoriteButton(
                          item: item,
                          size: 20,
                        ),
                        
                        // Previous
                        if (playerState.hasPrevious)
                          IconButton(
                            icon: const Icon(Icons.skip_previous, size: 24),
                            color: AppColors.textPrimary,
                            onPressed: () {
                              ref.read(playerProvider.notifier).playPrevious();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        
                        // Play/Pause
                        IconButton(
                          icon: Icon(
                            playerState.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 40,
                          ),
                          color: AppColors.primary,
                          onPressed: () {
                            ref.read(playerProvider.notifier).playOrPause();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                        
                        // Next
                        if (playerState.hasNext)
                          IconButton(
                            icon: const Icon(Icons.skip_next, size: 24),
                            color: AppColors.textPrimary,
                            onPressed: () {
                              ref.read(playerProvider.notifier).playNext();
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        
                        // Queue button
                        IconButton(
                          icon: const Icon(Icons.queue_music, size: 20),
                          color: AppColors.textSecondary,
                          onPressed: () {
                            showQueueBottomSheet(context);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        
                        // Close
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: AppColors.textSecondary,
                          onPressed: () {
                            ref.read(playerProvider.notifier).stop();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

/// Desktop/TV music player bar - shows at bottom of screen
class DesktopMusicPlayerBar extends ConsumerWidget {
  final bool isTV;

  const DesktopMusicPlayerBar({
    super.key,
    this.isTV = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    if (playerState.currentItem == null) {
      return const SizedBox.shrink();
    }

    final item = playerState.currentItem!;
    final isMusic = item.type.name == 'audio' || item.type.name == 'album';

    // Only show for music content
    if (!isMusic) {
      return const SizedBox.shrink();
    }

    final duration = playerState.duration;
    final position = playerState.position;

    return GlassContainer(
      blur: AppTheme.blurMedium,
      opacity: 0.1,
      borderRadius: 0,
      showBorder: false,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surface,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: playerState.progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (duration.inMilliseconds * value).round(),
                );
                ref.read(playerProvider.notifier).seek(newPosition);
              },
            ),
          ),

          // Player content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTV ? 48 : 24,
              vertical: isTV ? 16 : 12,
            ),
            child: Row(
              children: [
                // Album art
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: SizedBox(
                    width: isTV ? 64 : 56,
                    height: isTV ? 64 : 56,
                    child: Image.network(
                      item.getPrimaryImageUrl(serverUrl, width: 150),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surface,
                        child: Icon(
                          Icons.music_note,
                          color: AppColors.textSecondary,
                          size: isTV ? 32 : 28,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isTV ? 20 : 16),

                // Track info
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              style: isTV
                                  ? AppTextStyles.titleMedium
                                  : AppTextStyles.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (item.artists?.isNotEmpty == true ||
                                    item.albumArtist != null)
                                  item.albumArtist ?? item.artists?.first ?? '',
                                if (item.album != null) item.album,
                              ].join(' • '),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: isTV ? 14 : 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isTV ? 16 : 8),
                      // Favorite button
                      _FavoriteButton(
                        item: item,
                        size: isTV ? 24 : 20,
                      ),
                    ],
                  ),
                ),

                // Center controls
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Shuffle (placeholder)
                      IconButton(
                        icon: const Icon(Icons.shuffle),
                        iconSize: isTV ? 24 : 20,
                        color: AppColors.textSecondary,
                        onPressed: () {},
                        tooltip: 'Shuffle',
                      ),

                      SizedBox(width: isTV ? 16 : 8),

                      // Previous
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: isTV ? 36 : 28,
                        color: playerState.hasPrevious
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        onPressed: playerState.hasPrevious
                            ? () {
                                ref.read(playerProvider.notifier).playPrevious();
                              }
                            : null,
                        tooltip: 'Previous',
                      ),

                      SizedBox(width: isTV ? 12 : 4),

                      // Play/Pause
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: AppTheme.shadowGlow(AppColors.primary),
                        ),
                        child: IconButton(
                          icon: Icon(
                            playerState.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          iconSize: isTV ? 36 : 28,
                          color: Colors.white,
                          onPressed: () {
                            ref.read(playerProvider.notifier).playOrPause();
                          },
                          tooltip: playerState.isPlaying ? 'Pause' : 'Play',
                        ),
                      ),

                      SizedBox(width: isTV ? 12 : 4),

                      // Next
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: isTV ? 36 : 28,
                        color: playerState.hasNext
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        onPressed: playerState.hasNext
                            ? () {
                                ref.read(playerProvider.notifier).playNext();
                              }
                            : null,
                        tooltip: 'Next',
                      ),

                      SizedBox(width: isTV ? 16 : 8),

                      // Repeat (placeholder)
                      IconButton(
                        icon: const Icon(Icons.repeat),
                        iconSize: isTV ? 24 : 20,
                        color: AppColors.textSecondary,
                        onPressed: () {},
                        tooltip: 'Repeat',
                      ),
                    ],
                  ),
                ),

                // Right side - time and volume
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Time
                      Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: isTV ? 14 : 12,
                        ),
                      ),

                      SizedBox(width: isTV ? 24 : 16),

                      // Volume
                      if (!isTV) ...[
                        Icon(
                          playerState.volume > 0.5
                              ? Icons.volume_up
                              : playerState.volume > 0
                                  ? Icons.volume_down
                                  : Icons.volume_mute,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(
                          width: 100,
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12,
                              ),
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: AppColors.surface,
                              thumbColor: AppColors.primary,
                            ),
                            child: Slider(
                              value: playerState.volume,
                              onChanged: (value) {
                                ref.read(playerProvider.notifier).setVolume(value);
                              },
                            ),
                          ),
                        ),
                      ],

                      SizedBox(width: isTV ? 16 : 8),

                      // Queue button
                      IconButton(
                        icon: const Icon(Icons.queue_music),
                        iconSize: isTV ? 24 : 20,
                        color: AppColors.textSecondary,
                        onPressed: () {
                          showQueueBottomSheet(context);
                        },
                        tooltip: 'Queue',
                      ),

                      SizedBox(width: isTV ? 8 : 4),

                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: isTV ? 24 : 20,
                        color: AppColors.textSecondary,
                        onPressed: () {
                          ref.read(playerProvider.notifier).stop();
                        },
                        tooltip: 'Close player',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Expanded music player sheet for mobile
class ExpandedMusicPlayer extends ConsumerWidget {
  final VoidCallback onCollapse;

  const ExpandedMusicPlayer({
    super.key,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    if (playerState.currentItem == null) {
      return const SizedBox.shrink();
    }

    final item = playerState.currentItem!;
    final duration = playerState.duration;
    final position = playerState.position;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassContainer(
        blur: AppTheme.blurHeavy,
        opacity: 0.2,
        borderRadius: 0,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxHeight < 600;
              final artPadding = isCompact ? 32.0 : 48.0;
              final spacing = isCompact ? 16.0 : 32.0;
              final controlPadding = isCompact ? 16.0 : 32.0;
              final bottomPadding = isCompact ? 16.0 : 48.0;
              
              return Column(
                children: [
                  // Header with collapse button
                  Padding(
                    padding: EdgeInsets.all(isCompact ? 8 : 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down),
                          iconSize: 32,
                          color: AppColors.textPrimary,
                          onPressed: onCollapse,
                        ),
                        const Spacer(),
                        Text(
                          'NOW PLAYING',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.queue_music),
                          iconSize: 24,
                          color: AppColors.textPrimary,
                          onPressed: () {
                            showQueueBottomSheet(context);
                          },
                          tooltip: 'Queue',
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          iconSize: 24,
                          color: AppColors.textPrimary,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  // Album art - flexible to take available space
                  Flexible(
                    flex: 4,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: artPadding),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            child: Image.network(
                              item.getPrimaryImageUrl(serverUrl, width: 600),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surface,
                                child: const Icon(
                                  Icons.music_note,
                                  size: 100,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.02, 1.02),
                            duration: 3.seconds,
                            curve: Curves.easeInOut,
                          ),
                    ),
                  ),

                  SizedBox(height: spacing),

                  // Track info
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: controlPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                style: isCompact 
                                    ? AppTextStyles.titleLarge 
                                    : AppTextStyles.headlineSmall,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _FavoriteButton(
                              item: item,
                              size: isCompact ? 24 : 28,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (item.artists?.isNotEmpty == true ||
                                item.albumArtist != null)
                              item.albumArtist ?? item.artists?.first ?? '',
                            if (item.album != null) item.album,
                          ].join(' • '),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: spacing * 0.5),

                  // Progress slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.surface,
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: playerState.progress.clamp(0.0, 1.0),
                            onChanged: (value) {
                              final newPosition = Duration(
                                milliseconds:
                                    (duration.inMilliseconds * value).round(),
                              );
                              ref.read(playerProvider.notifier).seek(newPosition);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isCompact ? 8 : 24),

                  // Controls
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: controlPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Shuffle
                        IconButton(
                          icon: const Icon(Icons.shuffle),
                          iconSize: isCompact ? 24 : 28,
                          color: AppColors.textSecondary,
                          onPressed: () {},
                        ),

                        // Previous
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          iconSize: isCompact ? 32 : 40,
                          color: playerState.hasPrevious
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          onPressed: playerState.hasPrevious
                              ? () {
                                  ref.read(playerProvider.notifier).playPrevious();
                                }
                              : null,
                        ),

                        // Play/Pause
                        Container(
                          width: isCompact ? 56 : 72,
                          height: isCompact ? 56 : 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            boxShadow: AppTheme.shadowGlow(AppColors.primary),
                          ),
                          child: IconButton(
                            icon: Icon(
                              playerState.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            iconSize: isCompact ? 32 : 40,
                            color: Colors.white,
                            onPressed: () {
                              ref.read(playerProvider.notifier).playOrPause();
                            },
                          ),
                        ),

                        // Next
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          iconSize: isCompact ? 32 : 40,
                          color: playerState.hasNext
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          onPressed: playerState.hasNext
                              ? () {
                                  ref.read(playerProvider.notifier).playNext();
                                }
                              : null,
                        ),

                        // Repeat
                        IconButton(
                          icon: const Icon(Icons.repeat),
                          iconSize: isCompact ? 24 : 28,
                          color: AppColors.textSecondary,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: bottomPadding),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Favorite button widget with toggle functionality
class _FavoriteButton extends ConsumerStatefulWidget {
  final MediaItem item;
  final double size;

  const _FavoriteButton({
    required this.item,
    this.size = 24,
  });

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton> {
  late bool _isFavorite;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite ?? false;
  }

  @override
  void didUpdateWidget(_FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _isFavorite = widget.item.isFavorite ?? false;
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isFavorite = !_isFavorite; // Optimistic update
    });

    try {
      final mediaService = ref.read(mediaServiceProvider);
      await mediaService.toggleFavorite(widget.item.id, _isFavorite);
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: child,
        ),
        child: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(_isFavorite),
          size: widget.size,
          color: _isFavorite ? Colors.redAccent : AppColors.textSecondary,
        ),
      ),
      onPressed: _isLoading ? null : _toggleFavorite,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: widget.size + 8,
        minHeight: widget.size + 8,
      ),
      tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
    );
  }
}
