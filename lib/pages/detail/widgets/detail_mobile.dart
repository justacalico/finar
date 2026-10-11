import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/pages/adaptive_pages.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'package:finar/core/utils/media_actions.dart';
import 'detail_artist_albums_section.dart';
import 'detail_liquid_glass_menu.dart';
import 'detail_mobile_album_tracks.dart';
import 'detail_mobile_cast.dart';
import 'detail_mobile_downloads.dart';
import 'detail_mobile_episode_card.dart';
import 'detail_mobile_header.dart';
import 'detail_similar_section.dart';

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

class _DetailMobileState extends ConsumerState<DetailMobile> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _episodesSectionKey = GlobalKey();
  final GlobalKey _initialEpisodeKey = GlobalKey();
  int _selectedSeasonIndex = 0;
  bool _hasAppliedInitialSeasonSelection = false;
  bool _hasScrolledToEpisodesSection = false;
  bool _hasScheduledInitialEpisodeScroll = false;

  @override
  void dispose() {
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
                // Header row with poster, info, and actions
                DetailMobileHeader(
                  item: item,
                  serverUrl: serverUrl,
                  onMoreOptions: _showLiquidGlassMenu,
                ),

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
          ...mobileAlbumTracksSlivers(ref, item, serverUrl),

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
          SliverToBoxAdapter(
            child: DetailMobileCastSection(item: item, serverUrl: serverUrl),
          ),

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
        onFavorite: () => toggleFavoriteItem(ref, item),
        onWatched: () => toggleWatchedItem(ref, item),
        onWatchlist: () => _toggleWatchlist(item),
        onDownload: () =>
            handleMobileDownloadAction(ref, context, item, downloadTask),
        onShare: () => shareMediaItem(item),
      ),
    );
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
                      final card = DetailMobileEpisodeCard(
                        episode: episode,
                        serverUrl: serverUrl,
                        seasonId: seasonId,
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
        scrollCacheExtent: ScrollCacheExtent.pixels(500),
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
}
