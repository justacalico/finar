import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/services/download_service.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/pages/adaptive_pages.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'detail_artist_albums_section.dart';
import 'detail_liquid_glass_menu.dart';
import 'detail_similar_section.dart';
import 'detail_tiles.dart';

class DetailMobile extends ConsumerStatefulWidget {
  final String itemId;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const DetailMobile({
    super.key,
    required this.itemId,
    this.initialSeasonId,
    this.initialEpisodeId,
  });

  @override
  ConsumerState<DetailMobile> createState() => _DetailMobileState();
}

class _DetailMobileState extends ConsumerState<DetailMobile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _episodesSectionKey = GlobalKey();
  final GlobalKey _initialEpisodeKey = GlobalKey();
  int _selectedSeasonIndex = 0;
  bool _hasAppliedInitialSeasonSelection = false;
  bool _hasScrolledToEpisodesSection = false;
  bool _hasScheduledInitialEpisodeScroll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(mediaItemDetailProvider(widget.itemId));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Scaffold(
      body: itemAsync.when(
        data: (item) {
          // If this is a track, redirect to the album instead
          if (item.type == MediaType.audio && item.albumId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => AdaptiveDetailPage(itemId: item.albumId!),
                ),
              );
            });
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          // If this is an episode, redirect to the parent series detail.
          if (item.type == MediaType.episode && item.seriesId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => AdaptiveDetailPage(
                    itemId: item.seriesId!,
                    initialSeasonId: item.seasonId,
                    initialEpisodeId: item.id,
                  ),
                ),
              );
            });
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          return _buildContent(item, serverUrl);
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load', style: AppTextStyles.titleMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(mediaItemDetailProvider(widget.itemId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MediaItem item, String serverUrl) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Collapsing header with backdrop
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.background,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Backdrop image
                CachedNetworkImage(
                  imageUrl: item.getBackdropImageUrl(serverUrl, width: 800),
                  memCacheWidth: 800,
                  memCacheHeight: 600,
                  fadeInDuration: const Duration(milliseconds: 150),
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.surface),
                  errorWidget: (_, _, _) => Container(color: AppColors.surface),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.7),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with poster and info
                _buildHeaderRow(item, serverUrl),

                const SizedBox(height: 24),

                // Action buttons
                _buildActionButtons(item),

                const SizedBox(height: 24),

                // Overview
                if (item.overview != null) ...[
                  Text('Overview', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    item.overview!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),

        // Episodes section for TV shows — virtualized
        if (item.type == MediaType.series)
          ..._buildEpisodesSlivers(item, serverUrl),

        // Album tracks section for music albums — virtualized
        if (item.type == MediaType.album)
          ..._buildAlbumTracksSlivers(item, serverUrl),

        // Artist albums section
        if (item.type == MediaType.artist)
          SliverToBoxAdapter(
            child: DetailArtistAlbumsSection(
              artistId: item.id,
              serverUrl: serverUrl,
              isDesktop: false,
            ),
          ),

        // Cast section
        if (item.people?.isNotEmpty == true)
          SliverToBoxAdapter(child: _buildCastSection(item, serverUrl)),

        // Similar items
        SliverToBoxAdapter(
          child: DetailSimilarSection(
            itemId: item.id,
            serverUrl: serverUrl,
            isDesktop: false,
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeaderRow(MediaItem item, String serverUrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poster with refined styling
        Hero(
          tag: 'poster_${item.id}',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: item.getDisplayImageUrl(serverUrl, width: 300),
                memCacheWidth: 230,
                memCacheHeight: 344,
                fadeInDuration: const Duration(milliseconds: 150),
                width: 115,
                height: 172,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppColors.surface),
                errorWidget: (_, _, _) => Container(color: AppColors.surface),
              ),
            ),
          ),
        ),

        const SizedBox(width: 18),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              // Metadata with refined chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (item.productionYear != null)
                    _buildMetadataChip(item.productionYear.toString()),
                  if (item.officialRating != null)
                    _buildMetadataChip(item.officialRating!),
                  if (item.formattedRuntime.isNotEmpty)
                    _buildMetadataChip(item.formattedRuntime),
                ],
              ),
              const SizedBox(height: 12),
              // Rating with refined styling
              if (item.communityRating != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.accentYellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.communityRating!.toStringAsFixed(1),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.accentYellow,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.criticRating != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.reviews_rounded,
                              size: 14,
                              color: AppColors.accentRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.criticRating}%',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.accentRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              // Genres with refined styling
              if (item.genres?.isNotEmpty == true)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.genres!.take(3).map((genre) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        genre,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildMetadataChip(String text) {
    return DetailMetadataChip(text: text);
  }

  Widget _buildActionButtons(MediaItem item) {
    return Row(
      children: [
        // Primary play button
        if (item.type != MediaType.artist)
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _playItem(item),
                icon: Icon(Icons.play_arrow, size: 24),
                label: Text(
                  item.hasProgress ? 'Resume' : 'Play',
                  style: AppTextStyles.buttonLarge,
                ),
              ),
            ),
          ),

        // Trailer button
        if (item.hasTrailer) ...[
          const SizedBox(width: 12),
          GlassButton(
            onPressed: () => _playTrailer(item),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_outlined, size: 18),
                SizedBox(width: 8),
                Text('Trailer'),
              ],
            ),
          ),
        ],

        const SizedBox(width: 12),

        // More options menu
        _buildMoreOptionsMenu(item),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildMoreOptionsMenu(MediaItem item) {
    return GlassIconButton(
      icon: Icons.more_vert,
      onPressed: () => _showLiquidGlassMenu(item),
    );
  }

  void _showLiquidGlassMenu(MediaItem item) {
    final downloadTask = ref.read(downloadTaskProvider(item.id));
    final isInWatchlist = ref.read(isInWatchlistProvider(item.id));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DetailLiquidGlassMenu(
        item: item,
        downloadTask: downloadTask,
        isInWatchlist:
            isInWatchlist.when(
              data: (d) => d,
              loading: () => null,
              error: (_, stackTrace) => null,
            ) ??
            false,
        onFavorite: () => _toggleFavorite(item),
        onWatched: () => _toggleWatched(item),
        onWatchlist: () => _toggleWatchlist(item),
        onDownload: () => _handleDownloadAction(item, downloadTask),
        onShare: () => _shareItem(item),
      ),
    );
  }

  void _handleDownloadAction(MediaItem item, DownloadTask? task) {
    if (task == null) {
      _downloadItem(item);
      return;
    }
    switch (task.status) {
      case DownloadStatus.downloading:
        ref.read(downloadProvider.notifier).pauseDownload(task.id);
        break;
      case DownloadStatus.paused:
      case DownloadStatus.failed:
        ref.read(downloadProvider.notifier).resumeDownload(task.id);
        break;
      case DownloadStatus.completed:
        // Already downloaded, could show options
        break;
      default:
        _downloadItem(item);
    }
  }

  List<Widget> _buildEpisodesSlivers(MediaItem item, String serverUrl) {
    final seasonsAsync = ref.watch(seasonsProvider(item.id));
    return seasonsAsync.when(
      loading: () => [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ShimmerLoading(height: 120),
          ),
        ),
      ],
      error: (error, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading seasons: $error'),
          ),
        ),
      ],
      data: (seasons) {
        if (seasons.isEmpty) return <Widget>[];
        _maybeApplyInitialEpisodeContext(seasons);
        final selectedIndex = _selectedSeasonIndex.clamp(0, seasons.length - 1);
        final seasonId = seasons[selectedIndex].id;
        final episodesAsync = ref.watch(episodesProvider(seasonId));
        return [
          SliverToBoxAdapter(
            key: _episodesSectionKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Episodes', style: AppTextStyles.titleMedium),
                ),
                const SizedBox(height: 12),
                _buildSeasonTabs(seasons),
                const SizedBox(height: 12),
              ],
            ),
          ),
          ...episodesAsync.when(
            loading: () => <Widget>[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerLoading(height: 100),
                ),
              ),
            ],
            error: (error, _) => <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $error'),
                ),
              ),
            ],
            data: (episodes) {
              _maybeScrollToInitialEpisode(episodes);
              final totalCount = episodes.isEmpty ? 0 : episodes.length * 2 - 1;
              return <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      if (index.isOdd) {
                        return const SizedBox(height: 12);
                      }
                      final i = index ~/ 2;
                      final episode = episodes[i];
                      final card = _buildEpisodeCard(
                        episode,
                        serverUrl,
                        seasonId,
                      );
                      if (widget.initialEpisodeId != null &&
                          episode.id == widget.initialEpisodeId) {
                        return KeyedSubtree(
                          key: _initialEpisodeKey,
                          child: card,
                        );
                      }
                      return card;
                    },
                  ),
                ),
              ];
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ];
      },
    );
  }

  Widget _buildSeasonTabs(List<MediaItem> seasons) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
        cacheExtent: 500,
        itemCount: seasons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedSeasonIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedSeasonIndex = index),
            child: AnimatedContainer(
              duration: AppTheme.durationFast,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              alignment: Alignment.center,
              child: Text(
                seasons[index].name,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.black : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
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
            duration: const Duration(milliseconds: 300),
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
    if (_hasScheduledInitialEpisodeScroll || widget.initialEpisodeId == null) {
      return;
    }

    final hasTargetEpisode = episodes.any(
      (e) => e.id == widget.initialEpisodeId,
    );
    if (!hasTargetEpisode) return;

    _hasScheduledInitialEpisodeScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _initialEpisodeKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.2,
        );
      }
    });
  }

  Widget _buildEpisodeCard(
    MediaItem episode,
    String serverUrl,
    String seasonId,
  ) {
    final isWatched = episode.isPlayed == true;

    return GlassCard(
      onTap: () => _playItem(episode),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Stack(
              children: [
                ColorFiltered(
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
                    imageUrl: episode.getPrimaryImageUrl(serverUrl, width: 250),
                    memCacheWidth: 260,
                    memCacheHeight: 150,
                    fadeInDuration: const Duration(milliseconds: 150),
                    width: 130,
                    height: 75,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.surface),
                    errorWidget: (_, _, _) =>
                        Container(color: AppColors.surface),
                  ),
                ),
                // Watched indicator
                if (isWatched)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: AppColors.white,
                      ),
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
                // Play icon
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      isWatched ? Icons.replay : Icons.play_circle_outline,
                      size: 32,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
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
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (episode.overview != null)
                  Text(
                    episode.overview!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                if (episode.formattedRuntime.isNotEmpty)
                  Text(
                    episode.formattedRuntime,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),

          // Mark watched button
          IconButton(
            icon: Icon(
              isWatched ? Icons.visibility_off : Icons.visibility,
              color: isWatched
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.textSecondary,
            ),
            onPressed: () => _toggleEpisodeWatched(episode, seasonId),
          ),
        ],
      ),
    );
  }

  void _toggleEpisodeWatched(MediaItem episode, String seasonId) {
    ref
        .read(mediaActionsProvider)
        .markEpisodeWatched(episode.id, seasonId, !(episode.isPlayed == true));
  }

  Widget _buildCastSection(MediaItem item, String serverUrl) {
    final people = item.people ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cast & Crew', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: false,
              cacheExtent: 500,
              itemCount: people.length.clamp(0, 10),
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final person = people[index];
                return _buildPersonCard(person, serverUrl);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildPersonCard(PersonInfo person, String serverUrl) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.surface,
            backgroundImage: person.primaryImageTag != null
                ? CachedNetworkImageProvider(
                    '$serverUrl/Items/${person.id}/Images/Primary?maxWidth=150&tag=${person.primaryImageTag}',
                  )
                : null,
            child: person.primaryImageTag == null
                ? Icon(Icons.person, size: 22)
                : null,
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              person.name,
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (person.role != null)
            Flexible(
              child: Text(
                person.role!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  /// Returns slivers for album tracks (virtualized list).
  List<Widget> _buildAlbumTracksSlivers(MediaItem album, String serverUrl) {
    final tracksAsync = ref.watch(albumTracksProvider(album.id));
    return tracksAsync.when(
      data: (tracks) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Tracks', style: AppTextStyles.titleMedium),
                const Spacer(),
                Text(
                  '${tracks.length} songs',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.builder(
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return _buildTrackTile(track, index + 1, album, serverUrl);
            },
          ),
        ),
      ],
      loading: () => [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ShimmerLoading(height: 200),
          ),
        ),
      ],
      error: (error, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading tracks: $error'),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTile(
    MediaItem track,
    int trackNumber,
    MediaItem album,
    String serverUrl,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _playItem(track),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  track.indexNumber?.toString() ?? trackNumber.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (track.albumArtist != null ||
                        track.artists?.isNotEmpty == true)
                      Text(
                        track.albumArtist ?? track.artists?.join(', ') ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                track.formattedRuntime,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.play_circle_outline,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playItem(MediaItem item) {
    // Check if this is music content
    final isMusic =
        item.type == MediaType.audio ||
        item.type == MediaType.album ||
        item.type == MediaType.musicVideo;

    if (item.type == MediaType.album) {
      // For albums, fetch tracks and play as playlist
      _playAlbum(item);
    } else if (item.type == MediaType.series) {
      // For series, play the next up episode (continue watching)
      _playSeries(item);
    } else {
      // Get the resume position if item has progress
      final startPosition = item.hasProgress
          ? (item.userData?.playbackPositionTicks ?? item.playbackPositionTicks)
          : null;

      ref
          .read(playerProvider.notifier)
          .play(item, startPositionTicks: startPosition);

      // Only navigate to video player for non-music content
      if (!isMusic) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AdaptivePlayerPage()));
      }
    }
  }

  Future<void> _playSeries(MediaItem series) async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final nextUp = await mediaService.getNextUpForSeries(series.id);

      if (nextUp != null) {
        // Play the next up episode with resume position
        final startPosition = nextUp.hasProgress
            ? (nextUp.userData?.playbackPositionTicks ??
                  nextUp.playbackPositionTicks)
            : null;
        ref
            .read(playerProvider.notifier)
            .play(nextUp, startPositionTicks: startPosition);
        if (mounted) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AdaptivePlayerPage()));
        }
      } else {
        // No next up episode, get the first episode of the first season
        final seasons = await mediaService.getSeasons(series.id);
        if (seasons.isNotEmpty) {
          final episodes = await mediaService.getSeasonEpisodes(
            series.id,
            seasons.first.id,
          );
          if (episodes.isNotEmpty) {
            ref.read(playerProvider.notifier).play(episodes.first);
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdaptivePlayerPage()),
              );
            }
          } else {
            _showNoEpisodesError();
          }
        } else {
          _showNoEpisodesError();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play series: $e')));
      }
    }
  }

  void _showNoEpisodesError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No episodes available to play')),
      );
    }
  }

  Future<void> _playAlbum(MediaItem album) async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final tracks = await mediaService.getAlbumTracks(album.id);
      if (tracks.isNotEmpty) {
        ref.read(playerProvider.notifier).playPlaylist(tracks, 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play album: $e')));
      }
    }
  }

  void _playTrailer(MediaItem item) async {
    try {
      // First try to get local trailers
      if (item.localTrailerCount != null && item.localTrailerCount! > 0) {
        final mediaService = ref.read(mediaServiceProvider);
        final trailers = await mediaService.getLocalTrailers(item.id);
        if (trailers.isNotEmpty) {
          ref.read(playerProvider.notifier).play(trailers.first);
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdaptivePlayerPage()),
            );
          }
          return;
        }
      }

      // Fall back to remote trailers (YouTube, etc.)
      if (item.remoteTrailers != null && item.remoteTrailers!.isNotEmpty) {
        for (final trailer in item.remoteTrailers!) {
          final trailerUrl = trailer.url?.trim();
          if (trailerUrl == null || trailerUrl.isEmpty) {
            continue;
          }

          final opened = await _openRemoteTrailerUrl(trailerUrl);
          if (opened) {
            return;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No trailer available')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play trailer: $e')));
      }
    }
  }

  Future<bool> _openRemoteTrailerUrl(String rawUrl) async {
    final uri = _normalizeTrailerUri(rawUrl);
    if (uri == null) {
      return false;
    }

    final launchMode = kIsWeb
        ? LaunchMode.platformDefault
        : LaunchMode.externalApplication;

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: launchMode);
    }

    return launchUrl(uri, mode: launchMode);
  }

  Uri? _normalizeTrailerUri(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }

    if (value.startsWith('//')) {
      return Uri.tryParse('https:$value');
    }

    // Jellyfin providers sometimes return bare YouTube IDs.
    final isYouTubeId = RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(value);
    if (isYouTubeId) {
      return Uri.parse('https://www.youtube.com/watch?v=$value');
    }

    if (parsed != null && parsed.host.isNotEmpty) {
      return parsed.replace(scheme: 'https');
    }

    if (!value.contains(' ')) {
      return Uri.tryParse('https://$value');
    }

    return null;
  }

  void _toggleFavorite(MediaItem item) {
    ref
        .read(mediaActionsProvider)
        .toggleFavorite(item.id, !(item.isFavorite == true));
  }

  void _toggleWatched(MediaItem item) {
    ref
        .read(mediaActionsProvider)
        .toggleWatched(item.id, !(item.isPlayed == true));
  }

  void _toggleWatchlist(MediaItem item) async {
    final actions = ref.read(mediaActionsProvider);
    final isNowInWatchlist = await actions.toggleWatchlist(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowInWatchlist
                ? 'Added "${item.name}" to Watchlist'
                : 'Removed "${item.name}" from Watchlist',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _downloadItem(MediaItem item) {
    final downloadState = ref.read(downloadProvider);
    final existingTask = downloadState.getTaskForItem(item.id);

    if (existingTask != null) {
      // Show options for existing download
      _showDownloadOptions(existingTask);
    } else {
      // Start new download
      ref.read(downloadProvider.notifier).downloadItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading "${item.name}"'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _showDownloadsSheet(),
          ),
        ),
      );
    }
  }

  /// Play a downloaded item from local file
  Future<void> _playDownloadedItem(DownloadTask task) async {
    if (task.localPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download file not found')),
        );
      }
      return;
    }

    try {
      // Fetch the MediaItem details
      final mediaService = ref.read(mediaServiceProvider);
      final item = await mediaService.getItemDetails(task.itemId);

      // Play from local file
      ref.read(playerProvider.notifier).playLocalFile(item, task.localPath!);

      // Navigate to player for video content
      final isMusic =
          item.type == MediaType.audio ||
          item.type == MediaType.album ||
          item.type == MediaType.musicVideo;

      if (!isMusic && mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AdaptivePlayerPage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play: $e')));
      }
    }
  }

  void _showDownloadOptions(DownloadTask task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.itemName, style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Status: ${_getStatusText(task.status)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (task.status == DownloadStatus.downloading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${task.formattedDownloadedSize} / ${task.formattedSize}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (task.status == DownloadStatus.downloading)
              ListTile(
                leading: Icon(Icons.pause),
                title: const Text('Pause Download'),
                onTap: () {
                  ref.read(downloadProvider.notifier).pauseDownload(task.id);
                  Navigator.pop(context);
                },
              ),
            if (task.canResume)
              ListTile(
                leading: Icon(Icons.play_arrow),
                title: const Text('Resume Download'),
                onTap: () {
                  ref.read(downloadProvider.notifier).resumeDownload(task.id);
                  Navigator.pop(context);
                },
              ),
            if (task.status == DownloadStatus.completed)
              ListTile(
                leading: Icon(Icons.play_circle_outline),
                title: const Text('Play Downloaded'),
                onTap: () {
                  Navigator.pop(context);
                  _playDownloadedItem(task);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Delete Download',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                ref.read(downloadProvider.notifier).deleteDownload(task.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return 'Waiting...';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Downloaded';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _showDownloadsSheet() {
    // Navigate to downloads page
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdaptiveDownloadsPage()));
  }

  void _shareItem(MediaItem item) {
    // Build share text
    final StringBuffer shareText = StringBuffer();
    shareText.write(item.name);

    if (item.productionYear != null) {
      shareText.write(' (${item.productionYear})');
    }

    if (item.overview != null && item.overview!.isNotEmpty) {
      // Truncate overview if too long
      final overview = item.overview!.length > 200
          ? '${item.overview!.substring(0, 200)}...'
          : item.overview!;
      shareText.write('\n\n$overview');
    }

    if (item.communityRating != null) {
      shareText.write('\n\n⭐ ${item.communityRating!.toStringAsFixed(1)}');
    }

    if (item.genres?.isNotEmpty == true) {
      shareText.write('\n🎬 ${item.genres!.take(3).join(', ')}');
    }

    // Add a note about Finar
    shareText.write('\n\nShared via Finar');

    Share.share(shareText.toString(), subject: item.name);
  }
}
