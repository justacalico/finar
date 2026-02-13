import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../core/services/download_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'mobile_player.dart';

class MobileDetail extends ConsumerStatefulWidget {
  final String itemId;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const MobileDetail({
    super.key,
    required this.itemId,
    this.initialSeasonId,
    this.initialEpisodeId,
  });

  @override
  ConsumerState<MobileDetail> createState() => _MobileDetailState();
}

class _MobileDetailState extends ConsumerState<MobileDetail>
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
                  builder: (_) => MobileDetail(itemId: item.albumId!),
                ),
              );
            });
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // If this is an episode, redirect to the parent series detail.
          if (item.type == MediaType.episode && item.seriesId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => MobileDetail(
                    itemId: item.seriesId!,
                    initialSeasonId: item.seasonId,
                    initialEpisodeId: item.id,
                  ),
                ),
              );
            });
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return _buildContent(item, serverUrl);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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

        // Episodes section for TV shows
        if (item.type == MediaType.series) ...[
          SliverToBoxAdapter(child: _buildEpisodesSection(item, serverUrl)),
        ],

        // Album tracks section for music albums
        if (item.type == MediaType.album) ...[
          SliverToBoxAdapter(child: _buildAlbumTracksSection(item, serverUrl)),
        ],

        // Cast section
        if (item.people?.isNotEmpty == true)
          SliverToBoxAdapter(child: _buildCastSection(item, serverUrl)),

        // Similar items
        SliverToBoxAdapter(child: _buildSimilarSection(item.id, serverUrl)),

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
                width: 115,
                height: 172,
                fit: BoxFit.cover,
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
                          const Icon(
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
                            const Icon(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildActionButtons(MediaItem item) {
    return Row(
      children: [
        // Primary play button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _playItem(item),
              icon: const Icon(Icons.play_arrow, size: 24),
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
      builder: (context) => _LiquidGlassMenu(
        item: item,
        downloadTask: downloadTask,
        isInWatchlist: isInWatchlist.valueOrNull ?? false,
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

  Widget _buildEpisodesSection(MediaItem item, String serverUrl) {
    final seasonsAsync = ref.watch(seasonsProvider(item.id));

    return Column(
      key: _episodesSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Episodes', style: AppTextStyles.titleMedium),
        ),
        const SizedBox(height: 12),

        // Season selector
        seasonsAsync.when(
          data: (seasons) => _buildSeasonTabs(seasons),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 12),

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
            return _buildEpisodesList(seasonId, serverUrl);
          },
          loading: () => const ShimmerLoading(height: 120),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading seasons: $error'),
          ),
        ),

        const SizedBox(height: 24),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSeasonTabs(List<MediaItem> seasons) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
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
                color: isSelected ? AppColors.primary : AppColors.surface,
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

  Widget _buildEpisodesList(String seasonId, String serverUrl) {
    final episodesAsync = ref.watch(episodesProvider(seasonId));

    return episodesAsync.when(
      data: (episodes) {
        _maybeScrollToInitialEpisode(episodes);

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: episodes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final episode = episodes[index];
            final card = _buildEpisodeCard(episode, serverUrl, seasonId);
            if (widget.initialEpisodeId != null &&
                episode.id == widget.initialEpisodeId) {
              return KeyedSubtree(key: _initialEpisodeKey, child: card);
            }
            return card;
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerLoading(height: 100),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $error'),
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
                    width: 130,
                    height: 75,
                    fit: BoxFit.cover,
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
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
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
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
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
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.primary,
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
              color: isWatched ? AppColors.primary : AppColors.textSecondary,
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
                ? const Icon(Icons.person, size: 22)
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

  Widget _buildAlbumTracksSection(MediaItem album, String serverUrl) {
    final tracksAsync = ref.watch(albumTracksProvider(album.id));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Text('Tracks', style: AppTextStyles.titleMedium),
              const Spacer(),
              tracksAsync
                      .whenData(
                        (tracks) => Text(
                          '${tracks.length} songs',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                      .value ??
                  const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),

          // Tracks list
          tracksAsync.when(
            data: (tracks) => _buildTracksList(tracks, album, serverUrl),
            loading: () => const ShimmerLoading(height: 200),
            error: (error, _) => Text('Error loading tracks: $error'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTracksList(
    List<MediaItem> tracks,
    MediaItem album,
    String serverUrl,
  ) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      borderRadius: AppTheme.radiusMd,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return _buildTrackTile(track, index + 1, album, serverUrl);
        },
      ),
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
              // Track number
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

              // Track info
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

              // Duration
              Text(
                track.formattedRuntime,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(width: 8),

              // Play icon
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

  Widget _buildSimilarSection(String itemId, String serverUrl) {
    final similarAsync = ref.watch(similarItemsProvider(itemId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('More Like This', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: similarAsync.when(
              data: (items) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return AnimatedCard(
                    width: 120,
                    imageUrl: item.getDisplayImageUrl(serverUrl, width: 200),
                    title: item.name,
                    subtitle: item.productionYear?.toString(),
                    animationIndex: index,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => MobileDetail(itemId: item.id),
                        ),
                      );
                    },
                  );
                },
              ),
              loading: () => const ShimmerLoading(height: 200),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
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
        ).push(MaterialPageRoute(builder: (_) => const MobilePlayer()));
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
          ).push(MaterialPageRoute(builder: (_) => const MobilePlayer()));
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
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MobilePlayer()));
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
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MobilePlayer()));
          }
          return;
        }
      }

      // Fall back to remote trailers (YouTube, etc.)
      if (item.remoteTrailers != null && item.remoteTrailers!.isNotEmpty) {
        final trailer = item.remoteTrailers!.first;
        if (trailer.url != null) {
          // For remote trailers (usually YouTube), open in browser or show message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening trailer: ${trailer.name ?? "Trailer"}'),
                action: SnackBarAction(
                  label: 'Open',
                  onPressed: () {
                    // Launch URL - you may want to use url_launcher package
                  },
                ),
              ),
            );
          }
          return;
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
        ).push(MaterialPageRoute(builder: (_) => const MobilePlayer()));
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
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
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
                leading: const Icon(Icons.pause),
                title: const Text('Pause Download'),
                onTap: () {
                  ref.read(downloadProvider.notifier).pauseDownload(task.id);
                  Navigator.pop(context);
                },
              ),
            if (task.canResume)
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Resume Download'),
                onTap: () {
                  ref.read(downloadProvider.notifier).resumeDownload(task.id);
                  Navigator.pop(context);
                },
              ),
            if (task.status == DownloadStatus.completed)
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Play Downloaded'),
                onTap: () {
                  Navigator.pop(context);
                  _playDownloadedItem(task);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
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
    ).push(MaterialPageRoute(builder: (_) => const _DownloadsPage()));
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

/// Downloads page
class _DownloadsPage extends ConsumerWidget {
  const _DownloadsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (downloadState.downloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showDeleteAllDialog(context, ref),
            ),
        ],
      ),
      body: downloadState.downloads.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text('No Downloads', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Downloaded content will appear here',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: downloadState.downloads.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = downloadState.downloads[index];
                return _DownloadTile(task: task, serverUrl: serverUrl);
              },
            ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Downloads'),
        content: const Text(
          'Are you sure you want to delete all downloads? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(downloadProvider.notifier).deleteAllDownloads();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  final DownloadTask task;
  final String serverUrl;

  const _DownloadTile({required this.task, required this.serverUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              task.getImageUrl(serverUrl),
              width: 60,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 60,
                height: 90,
                color: AppColors.surface,
                child: const Icon(Icons.movie),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.itemName,
                  style: AppTextStyles.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(task.status),
                  style: AppTextStyles.caption.copyWith(
                    color: _getStatusColor(task.status),
                  ),
                ),
                if (task.status == DownloadStatus.downloading) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.formattedDownloadedSize} / ${task.formattedSize}',
                    style: AppTextStyles.caption,
                  ),
                ],
                if (task.status == DownloadStatus.completed)
                  Text(task.formattedSize, style: AppTextStyles.caption),
              ],
            ),
          ),
          // Action button
          _buildActionButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.pause),
          onPressed: () =>
              ref.read(downloadProvider.notifier).pauseDownload(task.id),
        );
      case DownloadStatus.paused:
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () =>
              ref.read(downloadProvider.notifier).resumeDownload(task.id),
        );
      case DownloadStatus.completed:
        return PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: ListTile(
                leading: Icon(Icons.play_circle_outline),
                title: Text('Play'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Delete', style: TextStyle(color: AppColors.error)),
                dense: true,
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              ref.read(downloadProvider.notifier).deleteDownload(task.id);
            } else if (value == 'play') {
              _playDownloadedTask(context, ref, task);
            }
          },
        );
      default:
        return IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              ref.read(downloadProvider.notifier).deleteDownload(task.id),
        );
    }
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

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return AppColors.primary;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.error;
      case DownloadStatus.paused:
        return AppColors.accentYellow;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Play a downloaded item from local file
  Future<void> _playDownloadedTask(
    BuildContext context,
    WidgetRef ref,
    DownloadTask task,
  ) async {
    if (task.localPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download file not found')));
      return;
    }

    // Capture references before async gap
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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

      if (!isMusic) {
        navigator.push(MaterialPageRoute(builder: (_) => const MobilePlayer()));
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to play: $e')),
      );
    }
  }
}

/// iOS 23 style liquid glass menu
class _LiquidGlassMenu extends StatelessWidget {
  final MediaItem item;
  final DownloadTask? downloadTask;
  final bool isInWatchlist;
  final VoidCallback onFavorite;
  final VoidCallback onWatched;
  final VoidCallback onWatchlist;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  const _LiquidGlassMenu({
    required this.item,
    required this.downloadTask,
    required this.isInWatchlist,
    required this.onFavorite,
    required this.onWatched,
    required this.onWatchlist,
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main menu container
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.white.withValues(alpha: 0.25),
                      AppColors.white.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Watchlist
                    _LiquidGlassMenuItem(
                      icon: isInWatchlist
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      iconColor: isInWatchlist
                          ? AppColors.accentYellow
                          : AppColors.white,
                      label: isInWatchlist
                          ? 'Remove from Watchlist'
                          : 'Add to Watchlist',
                      onTap: () {
                        Navigator.pop(context);
                        onWatchlist();
                      },
                    ),
                    _buildDivider(),
                    // Favorite
                    _LiquidGlassMenuItem(
                      icon: (item.isFavorite == true)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      iconColor: (item.isFavorite == true)
                          ? AppColors.accentRed
                          : AppColors.white,
                      label: (item.isFavorite == true)
                          ? 'Remove from Favorites'
                          : 'Add to Favorites',
                      onTap: () {
                        Navigator.pop(context);
                        onFavorite();
                      },
                    ),
                    _buildDivider(),
                    // Mark as watched
                    _LiquidGlassMenuItem(
                      icon: (item.isPlayed == true)
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      iconColor: (item.isPlayed == true)
                          ? AppColors.primary
                          : AppColors.white,
                      label: (item.isPlayed == true)
                          ? 'Mark as Unwatched'
                          : 'Mark as Watched',
                      onTap: () {
                        Navigator.pop(context);
                        onWatched();
                      },
                    ),
                    _buildDivider(),
                    // Download (hide on web)
                    if (!kIsWeb) ...[
                      _LiquidGlassMenuItem(
                        icon: _getDownloadIcon(),
                        iconColor: _getDownloadIconColor(),
                        label: _getDownloadText(),
                        onTap: () {
                          Navigator.pop(context);
                          onDownload();
                        },
                      ),
                      _buildDivider(),
                    ],
                    // Share
                    _LiquidGlassMenuItem(
                      icon: Icons.share_outlined,
                      iconColor: AppColors.white,
                      label: 'Share',
                      onTap: () {
                        Navigator.pop(context);
                        onShare();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cancel button
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.white.withValues(alpha: 0.3),
                      AppColors.white.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.white.withValues(alpha: 0),
            AppColors.white.withValues(alpha: 0.2),
            AppColors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  IconData _getDownloadIcon() {
    if (downloadTask == null) return Icons.download_outlined;
    switch (downloadTask!.status) {
      case DownloadStatus.downloading:
        return Icons.downloading;
      case DownloadStatus.paused:
        return Icons.pause_circle_outline;
      case DownloadStatus.completed:
        return Icons.download_done;
      case DownloadStatus.failed:
        return Icons.refresh;
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getDownloadIconColor() {
    if (downloadTask == null) return AppColors.white;
    switch (downloadTask!.status) {
      case DownloadStatus.downloading:
        return AppColors.primary;
      case DownloadStatus.paused:
        return AppColors.accentYellow;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.error;
      default:
        return AppColors.white;
    }
  }

  String _getDownloadText() {
    if (downloadTask == null) return 'Download';
    switch (downloadTask!.status) {
      case DownloadStatus.downloading:
        return 'Downloading (${(downloadTask!.progress * 100).toInt()}%)';
      case DownloadStatus.paused:
        return 'Resume Download';
      case DownloadStatus.completed:
        return 'Downloaded';
      case DownloadStatus.failed:
        return 'Retry Download';
      default:
        return 'Download Pending';
    }
  }
}

class _LiquidGlassMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _LiquidGlassMenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
