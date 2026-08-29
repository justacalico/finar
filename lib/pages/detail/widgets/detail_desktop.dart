import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/services/controller_service.dart';
import 'package:finar/core/services/download_service.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/pages/adaptive_pages.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'detail_artist_albums_section.dart';
import 'detail_desktop_background.dart';
import 'detail_error_view.dart';
import 'detail_focusable_action_button.dart';
import 'detail_focusable_download_progress.dart';
import 'detail_loading_shimmer.dart';
import 'detail_loading_view.dart';
import 'detail_more_options_sheet.dart';
import 'detail_similar_section.dart';
import 'detail_tiles.dart';

class DetailDesktop extends ConsumerStatefulWidget {
  final String itemId;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const DetailDesktop({
    super.key,
    required this.itemId,
    this.initialSeasonId,
    this.initialEpisodeId,
  });

  @override
  ConsumerState<DetailDesktop> createState() => _DetailDesktopState();
}

class _DetailDesktopState extends ConsumerState<DetailDesktop> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _episodesScrollController = ScrollController();
  final GlobalKey _episodesSectionKey = GlobalKey();
  final FocusNode _mainFocusNode = FocusNode();
  int _selectedSeasonIndex = 0;
  bool _showAllCast = false;
  bool _hasAppliedInitialSeasonSelection = false;
  bool _hasScrolledToEpisodesSection = false;
  bool _hasScrolledToInitialEpisode = false;

  @override
  void initState() {
    super.initState();
    // Request focus when the page is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _episodesScrollController.dispose();
    _mainFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!ControllerService.isKeyDown(event)) {
      return KeyEventResult.ignored;
    }

    final action = ControllerService.getAction(event);

    // Handle back button
    if (action == ControllerAction.back) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    // Handle scrolling with up/down when no focusable element has focus
    // This allows scrolling the page content with the controller
    if (action == ControllerAction.up) {
      _scrollController.animateTo(
        (_scrollController.offset - 100).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
      // Don't return handled - let focus system also try to move focus
    }

    if (action == ControllerAction.down) {
      _scrollController.animateTo(
        (_scrollController.offset + 100).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
      // Don't return handled - let focus system also try to move focus
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(mediaItemDetailProvider(widget.itemId));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return itemAsync.when(
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
          return const DetailLoadingView();
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
          return const DetailLoadingView();
        }

        return _buildContent(item, serverUrl);
      },
      loading: () => const DetailLoadingView(),
      error: (error, stack) => DetailErrorView(
        error: error.toString(),
        onRetry: () => ref.refresh(mediaItemDetailProvider(widget.itemId)),
      ),
    );
  }

  Widget _buildContent(MediaItem item, String serverUrl) {
    return Focus(
      focusNode: _mainFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Stack(
          children: [
            // Background
            _buildBackground(item, serverUrl),

            // Content
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Hero section with backdrop
                SliverToBoxAdapter(child: _buildHeroSection(item, serverUrl)),

                // Info section
                if (item.overview != null ||
                    item.studios?.isNotEmpty == true ||
                    item.productionYear != null ||
                    item.container != null ||
                    item.mediaStreams?.isNotEmpty == true)
                  SliverToBoxAdapter(child: _buildInfoSection(item, serverUrl)),

                // Episodes (for TV Shows)
                if (item.type == MediaType.series)
                  SliverToBoxAdapter(
                    child: _buildEpisodesSection(item, serverUrl),
                  ),

                // Album Tracks (for Music Albums) — virtualized
                if (item.type == MediaType.album)
                  ..._buildAlbumTracksSlivers(item, serverUrl),

                // Artist Albums (for Music Artists)
                if (item.type == MediaType.artist)
                  SliverToBoxAdapter(
                    child: DetailArtistAlbumsSection(
                      artistId: item.id,
                      serverUrl: serverUrl,
                      isDesktop: true,
                    ),
                  ),

                // Cast & Crew
                if (item.people?.isNotEmpty == true)
                  SliverToBoxAdapter(child: _buildCastSection(item, serverUrl)),

                // Similar Items — section widget so only this rebuilds when similar loads
                SliverToBoxAdapter(
                  child: DetailSimilarSection(
                    itemId: item.id,
                    serverUrl: serverUrl,
                    isDesktop: true,
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // Back button
            Positioned(
              top: 20,
              left: 20,
              child: SafeArea(
                child: GlassIconButton(
                  icon: Icons.arrow_back,
                  autofocus: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(MediaItem item, String serverUrl) {
    return DetailDesktopBackground(item: item, serverUrl: serverUrl);
  }

  Widget _buildHeroSection(MediaItem item, String serverUrl) {
    return SizedBox(
      height: 500,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(64, 120, 64, 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Poster
            Hero(
              tag: 'poster_${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: CachedNetworkImage(
                  imageUrl: item.getDisplayImageUrl(serverUrl, width: 400),
                  memCacheWidth: 500,
                  memCacheHeight: 750,
                  fadeInDuration: const Duration(milliseconds: 150),
                  width: 250,
                  height: 375,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.surface),
                  errorWidget: (_, _, _) => Container(color: AppColors.surface),
                ),
              ),
            ).animate().fadeIn().scale(
              begin: const Offset(0.9, 0.9),
              duration: AppTheme.durationNormal,
            ),

            const SizedBox(width: 40),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo or title
                  if (item.logoImageTag != null)
                    CachedNetworkImage(
                      imageUrl:
                          '$serverUrl/Items/${item.id}/Images/Logo?maxWidth=500&tag=${item.logoImageTag}',
                      memCacheWidth: 1000,
                      fadeInDuration: const Duration(milliseconds: 150),
                      height: 80,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      placeholder: (_, _) =>
                          Container(color: AppColors.surface),
                      errorWidget: (_, _, _) =>
                          Text(item.name, style: AppTextStyles.displayMedium),
                    )
                  else
                    Text(item.name, style: AppTextStyles.displayMedium),

                  const SizedBox(height: 16),

                  // Metadata row
                  _buildMetadataRow(item),

                  const SizedBox(height: 16),

                  // Genres
                  if (item.genres?.isNotEmpty == true)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.genres!.take(5).map((genre) {
                        return GlassChip(label: genre);
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActionButtons(item),
                ],
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(MediaItem item) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (item.productionYear != null)
          Text(item.productionYear.toString(), style: AppTextStyles.bodyLarge),
        if (item.officialRating != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(item.officialRating!, style: AppTextStyles.labelSmall),
          ),
        if (item.formattedRuntime.isNotEmpty)
          Text(item.formattedRuntime, style: AppTextStyles.bodyLarge),
        if (item.communityRating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 18, color: AppColors.accentYellow),
              const SizedBox(width: 4),
              Text(
                item.communityRating!.toStringAsFixed(1),
                style: AppTextStyles.rating,
              ),
            ],
          ),
        if (item.criticRating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.reviews, size: 16, color: AppColors.accentRed),
              const SizedBox(width: 4),
              Text('${item.criticRating}%', style: AppTextStyles.bodyMedium),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButtons(MediaItem item) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play button with controller focus support
            if (item.type != MediaType.artist)
              FocusTraversalOrder(
                order: const NumericFocusOrder(0),
                child: DetailFocusableActionButton(
                  width: 200,
                  height: 54,
                  autofocus: true,
                  onPressed: () => _playItem(item),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 26,
                        color: AppColors.textOnPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.hasProgress ? 'Resume' : 'Play',
                        style: AppTextStyles.buttonLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Trailer button
            if (item.hasTrailer) ...[
              const SizedBox(width: 14),
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: DetailFocusableActionButton(
                  height: 54,
                  onPressed: () => _playTrailer(item),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.movie_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text('Trailer', style: AppTextStyles.labelMedium),
                    ],
                  ),
                ),
              ),
            ],

            // Favorite button
            const SizedBox(width: 10),
            FocusTraversalOrder(
              order: NumericFocusOrder(item.hasTrailer ? 2 : 1),
              child: Consumer(
                builder: (context, ref, _) {
                  final isFavorite = item.isFavorite == true;
                  return GlassIconButton(
                    icon: isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    iconColor: isFavorite
                        ? AppColors.accentRed
                        : AppColors.textSecondary,
                    size: 54,
                    onPressed: () => _toggleFavorite(item),
                  );
                },
              ),
            ),

            // Mark watched button
            const SizedBox(width: 10),
            FocusTraversalOrder(
              order: NumericFocusOrder(item.hasTrailer ? 3 : 2),
              child: GlassIconButton(
                icon: (item.isPlayed == true)
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                iconColor: (item.isPlayed == true)
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.textSecondary,
                size: 54,
                onPressed: () => _toggleWatched(item),
              ),
            ),

            // Download button (hide on web)
            if (!kIsWeb) ...[
              const SizedBox(width: 10),
              FocusTraversalOrder(
                order: NumericFocusOrder(item.hasTrailer ? 4 : 3),
                child: _buildDownloadButton(item),
              ),
            ],

            // More options
            const SizedBox(width: 10),
            FocusTraversalOrder(
              order: NumericFocusOrder(
                item.hasTrailer ? (kIsWeb ? 4 : 5) : (kIsWeb ? 3 : 4),
              ),
              child: GlassIconButton(
                icon: Icons.more_horiz_rounded,
                size: 54,
                onPressed: () => _showMoreOptions(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(MediaItem item, String serverUrl) {
    final hasOverview = item.overview != null;
    final hasDetails =
        item.studios?.isNotEmpty == true ||
        item.productionYear != null ||
        item.container != null ||
        (item.mediaStreams?.isNotEmpty == true);

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasOverview) ...[
            // Overview
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.overview!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      height: 1.7,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  if (item.taglines?.isNotEmpty == true) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '"${item.taglines!.first}"',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (hasOverview && hasDetails) const SizedBox(width: 64),

          // Additional info
          if (hasDetails) Expanded(child: _buildAdditionalInfo(item)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildAdditionalInfo(MediaItem item) {
    return GlassContainer(
      blur: AppTheme.blurHeavy,
      opacity: 0.09,
      borderRadius: AppTheme.radiusLg,
      borderColor: AppColors.white.withValues(alpha: 0.22),
      shadows: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.2),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.white.withValues(alpha: 0.16),
          AppColors.white.withValues(alpha: 0.05),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (item.studios?.isNotEmpty == true)
            _buildInfoRow('Studio', item.studios!.first),
          if (item.productionYear != null)
            _buildInfoRow('Year', item.productionYear.toString()),
          if (item.container != null)
            _buildInfoRow('Format', item.container!.toUpperCase()),
          if (item.mediaStreams?.isNotEmpty == true) ...[
            _buildInfoRow(
              'Video',
              item.mediaStreams!
                      .where((s) => s.type == 'Video')
                      .map(
                        (s) => '${s.codec?.toUpperCase()} ${s.videoResolution}',
                      )
                      .firstOrNull ??
                  'Unknown',
            ),
            _buildInfoRow(
              'Audio',
              item.mediaStreams!
                      .where((s) => s.type == 'Audio')
                      .map(
                        (s) =>
                            '${s.codec?.toUpperCase()} ${s.channelLayout ?? ''}',
                      )
                      .firstOrNull ??
                  'Unknown',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return DetailInfoRow(label: label, value: value);
  }

  Widget _buildEpisodesSection(MediaItem item, String serverUrl) {
    final seasonsAsync = ref.watch(seasonsProvider(item.id));

    return Padding(
      key: _episodesSectionKey,
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seasons section
          seasonsAsync.when(
            data: (seasons) => seasons.length > 1
                ? _buildSeasonsRow(seasons, serverUrl)
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
              return _buildEpisodesList(seasonId, serverUrl);
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
            cacheExtent: 500,
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
            cacheExtent: 500,
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
      onTap: () => _playItem(episode),
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
                  onPressed: () => _toggleEpisodeWatched(episode, seasonId),
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

  void _toggleEpisodeWatched(MediaItem episode, String seasonId) {
    ref
        .read(mediaActionsProvider)
        .markEpisodeWatched(episode.id, seasonId, !(episode.isPlayed == true));
  }

  /// Returns slivers for album tracks (virtualized list).
  List<Widget> _buildAlbumTracksSlivers(MediaItem album, String serverUrl) {
    final tracksAsync = ref.watch(albumTracksProvider(album.id));
    return tracksAsync.when(
      data: (tracks) => [
        SliverToBoxAdapter(
          child: RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(64, 0, 64, 16),
              child: Row(
                children: [
                  Text('Tracks', style: AppTextStyles.titleLarge),
                  const Spacer(),
                  Text(
                    '${tracks.length} songs',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
            child: const DetailLoadingShimmer(height: 300),
          ),
        ),
      ],
      error: (error, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
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
    final duration = track.formattedRuntime;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _playItem(track),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Track number
              SizedBox(
                width: 40,
                child: Text(
                  track.indexNumber?.toString() ?? trackNumber.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: 16),

              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: AppTextStyles.bodyLarge,
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

              const SizedBox(width: 16),

              // Duration
              Text(
                duration,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(width: 16),

              // Play button
              GlassIconButton(
                icon: Icons.play_arrow,
                size: 36,
                onPressed: () => _playItem(track),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCastSection(MediaItem item, String serverUrl) {
    final people = item.people ?? [];
    final displayPeople = _showAllCast ? people : people.take(10).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Cast & Crew', style: AppTextStyles.titleLarge),
              const Spacer(),
              if (people.length > 10)
                TextButton(
                  onPressed: () => setState(() => _showAllCast = !_showAllCast),
                  child: Text(_showAllCast ? 'Show Less' : 'See All'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: false,
              cacheExtent: 500,
              itemCount: displayPeople.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return _buildPersonCard(displayPeople[index], serverUrl);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildPersonCard(PersonInfo person, String serverUrl) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.surface,
            backgroundImage: person.primaryImageTag != null
                ? NetworkImage(
                    '$serverUrl/Items/${person.id}/Images/Primary?maxWidth=150&tag=${person.primaryImageTag}',
                  )
                : null,
            child: person.primaryImageTag == null
                ? Icon(Icons.person, size: 32)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            person.name,
            style: AppTextStyles.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (person.role != null)
            Text(
              person.role!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(MediaItem item) {
    final downloadState = ref.watch(downloadProvider);
    final existingDownload = downloadState.getTaskForItem(item.id);

    if (existingDownload != null) {
      switch (existingDownload.status) {
        case DownloadStatus.downloading:
          return DetailFocusableDownloadProgress(
            progress: existingDownload.progress,
            onPressed: () => _pauseDownload(existingDownload.id),
          );
        case DownloadStatus.paused:
          return GlassIconButton(
            icon: Icons.play_arrow_rounded,
            iconColor: AppColors.warning,
            size: 54,
            onPressed: () => _resumeDownload(existingDownload.id),
          );
        case DownloadStatus.completed:
          return GlassIconButton(
            icon: Icons.download_done_rounded,
            iconColor: AppColors.success,
            size: 54,
            onPressed: () => _showDownloadOptions(existingDownload.id),
          );
        case DownloadStatus.failed:
          return GlassIconButton(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.error,
            size: 54,
            onPressed: () => _downloadItem(item),
          );
        case DownloadStatus.pending:
          return GlassIconButton(
            icon: Icons.hourglass_empty_rounded,
            size: 54,
            onPressed: () => _cancelDownload(existingDownload.id),
          );
        case DownloadStatus.cancelled:
          return GlassIconButton(
            icon: Icons.download_outlined,
            size: 54,
            onPressed: () => _downloadItem(item),
          );
      }
    }

    return GlassIconButton(
      icon: Icons.download_outlined,
      size: 54,
      onPressed: () => _downloadItem(item),
    );
  }

  Future<void> _downloadItem(MediaItem item) async {
    try {
      await ref.read(downloadProvider.notifier).downloadItem(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting download: ${item.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start download: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _pauseDownload(String taskId) {
    ref.read(downloadProvider.notifier).pauseDownload(taskId);
  }

  void _resumeDownload(String taskId) {
    ref.read(downloadProvider.notifier).resumeDownload(taskId);
  }

  void _cancelDownload(String taskId) {
    ref.read(downloadProvider.notifier).cancelDownload(taskId);
  }

  void _showDownloadOptions(String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Download Options'),
        content: const Text(
          'This item has been downloaded. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadProvider.notifier).deleteDownload(taskId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download removed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Remove Download',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
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
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AdaptivePlayerPage()),
        );
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
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AdaptivePlayerPage()),
          );
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
                MaterialPageRoute(
                  builder: (context) => const AdaptivePlayerPage(),
                ),
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
              MaterialPageRoute(
                builder: (context) => const AdaptivePlayerPage(),
              ),
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

  void _showMoreOptions(MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DetailMoreOptionsSheet(
        item: item,
        onDownload: () => _downloadItem(item),
        onShare: () => _shareItem(item),
        onMediaInfo: () => _showMediaInfoDialog(item),
        onAddToPlaylist: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add to playlist coming soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onReportIssue: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report issue coming soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _shareItem(MediaItem item) {
    final StringBuffer shareText = StringBuffer();
    shareText.write(item.name);
    if (item.productionYear != null) {
      shareText.write(' (${item.productionYear})');
    }
    if (item.overview != null && item.overview!.isNotEmpty) {
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
    shareText.write('\n\nShared via Finar');
    Share.share(shareText.toString(), subject: item.name);
  }

  void _showMediaInfoDialog(MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(item.name, style: AppTextStyles.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.productionYear != null)
                Text(
                  'Year: ${item.productionYear}',
                  style: AppTextStyles.bodyMedium,
                ),
              ...[
                const SizedBox(height: 8),
                Text(
                  'Runtime: ${item.formattedRuntime}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
              if (item.overview?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(item.overview!, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
