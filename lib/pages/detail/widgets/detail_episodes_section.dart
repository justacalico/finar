import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'package:finar/core/utils/media_actions.dart';
import 'detail_loading_shimmer.dart';

class DetailEpisodesSection extends ConsumerStatefulWidget {
  final MediaItem item;
  final String serverUrl;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const DetailEpisodesSection({
    super.key,
    required this.item,
    required this.serverUrl,
    this.initialSeasonId,
    this.initialEpisodeId,
  });

  @override
  ConsumerState<DetailEpisodesSection> createState() =>
      _DetailEpisodesSectionState();
}

class _DetailEpisodesSectionState extends ConsumerState<DetailEpisodesSection> {
  final ScrollController _episodesScrollController = ScrollController();
  final GlobalKey _episodesSectionKey = GlobalKey();
  int _selectedSeasonIndex = 0;
  bool _hasAppliedInitialSeasonSelection = false;
  bool _hasScrolledToEpisodesSection = false;
  bool _hasScrolledToInitialEpisode = false;

  @override
  void dispose() {
    _episodesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seasonsAsync = ref.watch(seasonsProvider(widget.item.id));

    return Padding(
      key: _episodesSectionKey,
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seasons section
          seasonsAsync.when(
            data: (seasons) => seasons.length > 1
                ? _buildSeasonsRow(seasons, widget.serverUrl)
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Section header
          Text('Episodes', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),

          // Episodes list
          seasonsAsync.when(
            data: (seasons) {
              if (seasons.isEmpty) return const SizedBox.shrink();
              _maybeApplyInitialEpisodeContext(seasons);

              final selectedIndex = _selectedSeasonIndex.clamp(
                0,
                seasons.length - 1,
              );
              final seasonId = seasons[selectedIndex].id;
              return _buildEpisodesList(seasonId, widget.serverUrl);
            },
            loading: () => const DetailLoadingShimmer(height: 150),
            error: (error, _) => Text('Error loading seasons: $error'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildSeasonsRow(List<MediaItem> seasons, String serverUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seasons', style: AppTextStyles.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            addRepaintBoundaries: true,
            addAutomaticKeepAlives: false,
            scrollCacheExtent: ScrollCacheExtent.pixels(500),
            itemCount: seasons.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final season = seasons[index];
              final isSelected = _selectedSeasonIndex == index;
              return _buildSeasonCard(season, serverUrl, isSelected, index);
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSeasonCard(
    MediaItem season,
    String serverUrl,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedSeasonIndex = index),
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Season poster
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd - 2),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: season.getPrimaryImageUrl(serverUrl, width: 200),
                    memCacheWidth: 248,
                    memCacheHeight: 248,
                    fadeInDuration: const Duration(milliseconds: 150),
                    width: 124,

                    height: 124,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.surface),
                    errorWidget: (_, _, _) => Container(
                      width: 124,
                      height: 124,
                      color: AppColors.surface,
                      child: Icon(Icons.tv, size: 32),
                    ),
                  ),
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        child: Center(
                          child: Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Season name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                season.name,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodesList(String seasonId, String serverUrl) {
    final episodesAsync = ref.watch(episodesProvider(seasonId));

    return episodesAsync.when(
      data: (episodes) {
        _maybeScrollToInitialEpisode(episodes);

        return SizedBox(
          height: 236,
          child: ListView.separated(
            controller: _episodesScrollController,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            addRepaintBoundaries: true,
            addAutomaticKeepAlives: false,
            scrollCacheExtent: ScrollCacheExtent.pixels(500),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            itemCount: episodes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return _buildEpisodeCard(episode, serverUrl, seasonId);
            },
          ),
        );
      },
      loading: () => const DetailLoadingShimmer(height: 220),
      error: (error, _) => Text('Error loading episodes: $error'),
    );
  }

  void _maybeApplyInitialEpisodeContext(List<MediaItem> seasons) {
    if (!_hasScrolledToEpisodesSection &&
        (widget.initialSeasonId != null || widget.initialEpisodeId != null)) {
      _hasScrolledToEpisodesSection = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final context = _episodesSectionKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: 0.1,
          );
        }
      });
    }

    if (_hasAppliedInitialSeasonSelection || widget.initialSeasonId == null) {
      return;
    }
    _hasAppliedInitialSeasonSelection = true;

    final targetIndex = seasons.indexWhere(
      (s) => s.id == widget.initialSeasonId,
    );
    if (targetIndex >= 0 && targetIndex != _selectedSeasonIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedSeasonIndex = targetIndex);
      });
    }
  }

  void _maybeScrollToInitialEpisode(List<MediaItem> episodes) {
    if (_hasScrolledToInitialEpisode || widget.initialEpisodeId == null) return;

    final targetIndex = episodes.indexWhere(
      (e) => e.id == widget.initialEpisodeId,
    );
    if (targetIndex < 0) return;

    _hasScrolledToInitialEpisode = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_episodesScrollController.hasClients) return;

      const itemExtentWithSpacing = 336.0; // card width (320) + spacing (16)
      final offset = (targetIndex * itemExtentWithSpacing).clamp(
        0.0,
        _episodesScrollController.position.maxScrollExtent,
      );
      _episodesScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Widget _buildEpisodeCard(
    MediaItem episode,
    String serverUrl,
    String seasonId,
  ) {
    final isWatched = episode.isPlayed == true;

    return GlassCard(
      width: 320,
      onTap: () => playDetailItem(ref, context, episode),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMd),
                ),
                child: ColorFiltered(
                  colorFilter: isWatched
                      ? ColorFilter.mode(
                          AppColors.black.withValues(alpha: 0.3),
                          BlendMode.darken,
                        )
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        ),
                  child: CachedNetworkImage(
                    imageUrl: episode.getPrimaryImageUrl(serverUrl, width: 500),
                    memCacheWidth: 640,
                    memCacheHeight: 240,
                    fadeInDuration: const Duration(milliseconds: 150),
                    width: 320,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.surface),
                    errorWidget: (_, _, _) =>
                        Container(color: AppColors.surface),
                  ),
                ),
              ),
              // Watched indicator
              if (isWatched)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.check, size: 16, color: AppColors.white),
                  ),
                ),
              // Progress bar
              if (episode.hasProgress && !isWatched)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: episode.progressPercent,
                    backgroundColor: AppColors.black.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                    minHeight: 3,
                  ),
                ),
              // Play icon overlay
              Positioned.fill(
                child: Center(
                  child: Icon(
                    isWatched ? Icons.replay : Icons.play_circle_outline,
                    size: 48,
                    color: AppColors.white,
                  ),
                ),
              ),
              // Mark watched button
              Positioned(
                top: 8,
                left: 8,
                child: GlassIconButton(
                  icon: isWatched ? Icons.visibility_off : Icons.visibility,
                  size: 32,
                  onPressed: () => toggleEpisodeWatched(ref, episode, seasonId),
                ),
              ),
            ],
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'E${episode.indexNumber} - ${episode.name}',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isWatched
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isWatched)
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  episode.overview ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
