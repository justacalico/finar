import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../core/services/download_service.dart';
import '../../core/services/controller_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'adaptive_pages.dart';

class DetailPage extends ConsumerWidget {
  final String itemId;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const DetailPage({
    super.key,
    required this.itemId,
    this.initialSeasonId,
    this.initialEpisodeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveLayout(
      desktopBuilder: () => _DetailDesktop(
        itemId: itemId,
        initialSeasonId: initialSeasonId,
        initialEpisodeId: initialEpisodeId,
      ),
      mobileBuilder: () => _DetailMobile(
        itemId: itemId,
        initialSeasonId: initialSeasonId,
        initialEpisodeId: initialEpisodeId,
      ),
    );
  }
}

class _DetailDesktop extends ConsumerStatefulWidget {
  final String itemId;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const _DetailDesktop({
    required this.itemId,
    this.initialSeasonId,
    this.initialEpisodeId,
  });

  @override
  ConsumerState<_DetailDesktop> createState() => _DetailDesktopState();
}

class _DetailDesktopState extends ConsumerState<_DetailDesktop> {
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
          return const _DetailLoadingView();
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
          return const _DetailLoadingView();
        }

        return _buildContent(item, serverUrl);
      },
      loading: () => const _DetailLoadingView(),
      error: (error, stack) => _DetailErrorView(
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
                SliverToBoxAdapter(child: _buildInfoSection(item, serverUrl)),

                // Episodes (for TV Shows)
                if (item.type == MediaType.series)
                  SliverToBoxAdapter(
                    child: _buildEpisodesSection(item, serverUrl),
                  ),

                // Album Tracks (for Music Albums)
                if (item.type == MediaType.album)
                  SliverToBoxAdapter(
                    child: _buildAlbumTracksSection(item, serverUrl),
                  ),

                // Cast & Crew
                if (item.people?.isNotEmpty == true)
                  SliverToBoxAdapter(child: _buildCastSection(item, serverUrl)),

                // Similar Items
                SliverToBoxAdapter(
                  child: _buildSimilarSection(item.id, serverUrl),
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
    final imageUrl = item.type == MediaType.album
        ? item.getPrimaryImageUrl(serverUrl, width: 1920)
        : item.getBackdropImageUrl(serverUrl, width: 1920);
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop image (album art for albums)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppColors.background),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.3),
                  AppColors.background.withValues(alpha: 0.7),
                  AppColors.background,
                ],
                stops: const [0.0, 0.4, 0.7],
              ),
            ),
          ),

          // Left gradient for content readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.background.withValues(alpha: 0.9),
                  AppColors.background.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5],
              ),
            ),
          ),
        ],
      ),
    );
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
                child: Image.network(
                  item.getDisplayImageUrl(serverUrl, width: 400),
                  width: 250,
                  height: 375,
                  fit: BoxFit.cover,
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
                children: [
                  // Logo or title
                  if (item.logoImageTag != null)
                    Image.network(
                      '$serverUrl/Items/${item.id}/Images/Logo?maxWidth=500&tag=${item.logoImageTag}',
                      height: 80,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, _, _) =>
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
              const Icon(Icons.star, size: 18, color: AppColors.accentYellow),
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
              const Icon(Icons.reviews, size: 16, color: AppColors.accentRed),
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
        clipBehavior: Clip.none,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play button with controller focus support
            FocusTraversalOrder(
              order: const NumericFocusOrder(0),
              child: _FocusableActionButton(
                width: 200,
                height: 54,
                autofocus: true,
                onPressed: () => _playItem(item),
                backgroundColor: AppColors.primary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
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
            const SizedBox(width: 14),

            // Trailer button
            if (item.hasTrailer)
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: _FocusableActionButton(
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
            if (item.hasTrailer) const SizedBox(width: 14),

            // Favorite button
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
            const SizedBox(width: 10),

            // Mark watched button
            FocusTraversalOrder(
              order: NumericFocusOrder(item.hasTrailer ? 3 : 2),
              child: GlassIconButton(
                icon: (item.isPlayed == true)
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                iconColor: (item.isPlayed == true)
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 54,
                onPressed: () => _toggleWatched(item),
              ),
            ),
            const SizedBox(width: 10),

            // Download button (hide on web)
            if (!kIsWeb)
              FocusTraversalOrder(
                order: NumericFocusOrder(item.hasTrailer ? 4 : 3),
                child: _buildDownloadButton(item),
              ),
            if (!kIsWeb) const SizedBox(width: 10),

            // More options
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  item.overview ?? 'No overview available.',
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
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '"${item.taglines!.first}"',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 64),

          // Additional info
          Expanded(child: _buildAdditionalInfo(item)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
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
            loading: () => const _LoadingShimmer(height: 150),
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
            color: isSelected ? AppColors.primary : Colors.transparent,
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
                  Image.network(
                    season.getPrimaryImageUrl(serverUrl, width: 200),
                    width: 124,
                    height: 124,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 124,
                      height: 124,
                      color: AppColors.surface,
                      child: const Icon(Icons.tv, size: 32),
                    ),
                  ),
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
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
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
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
      loading: () => const _LoadingShimmer(height: 220),
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
                  child: Image.network(
                    episode.getPrimaryImageUrl(serverUrl, width: 500),
                    width: 320,
                    height: 120,
                    fit: BoxFit.cover,
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
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
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
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
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
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.primary,
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

  Widget _buildAlbumTracksSection(MediaItem album, String serverUrl) {
    final tracksAsync = ref.watch(albumTracksProvider(album.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Text('Tracks', style: AppTextStyles.titleLarge),
              const Spacer(),
              tracksAsync
                      .whenData(
                        (tracks) => Text(
                          '${tracks.length} songs',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                      .value ??
                  const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),

          // Tracks list
          tracksAsync.when(
            data: (tracks) => _buildTracksList(tracks, album, serverUrl),
            loading: () => const _LoadingShimmer(height: 300),
            error: (error, _) => Text('Error loading tracks: $error'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: displayPeople.map((person) {
              return _buildPersonCard(person, serverUrl);
            }).toList(),
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
                ? const Icon(Icons.person, size: 32)
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

  Widget _buildSimilarSection(String itemId, String serverUrl) {
    final similarAsync = ref.watch(similarItemsProvider(itemId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('More Like This', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: similarAsync.when(
              data: (items) => ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return AnimatedCard(
                    width: 160,
                    imageUrl: item.getDisplayImageUrl(serverUrl, width: 300),
                    title: item.name,
                    subtitle: item.productionYear?.toString(),
                    animationIndex: index,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              AdaptiveDetailPage(itemId: item.id),
                        ),
                      );
                    },
                  );
                },
              ),
              loading: () => const _LoadingShimmer(height: 280),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildDownloadButton(MediaItem item) {
    final downloadState = ref.watch(downloadProvider);
    final existingDownload = downloadState.getTaskForItem(item.id);

    if (existingDownload != null) {
      switch (existingDownload.status) {
        case DownloadStatus.downloading:
          return _FocusableDownloadProgress(
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
      builder: (context) => _MoreOptionsSheet(
        item: item,
        onDownload: () => _downloadItem(item),
        onShare: () => _shareItem(item),
        onMediaInfo: () => _showMediaInfoDialog(item),
        onAddToPlaylist: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add to playlist coming soon'), behavior: SnackBarBehavior.floating),
            );
          }
        },
        onReportIssue: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report issue coming soon'), behavior: SnackBarBehavior.floating),
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
                Text('Year: ${item.productionYear}', style: AppTextStyles.bodyMedium),
              ...[
              const SizedBox(height: 8),
              Text('Runtime: ${item.formattedRuntime}', style: AppTextStyles.bodyMedium),
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

class _DetailLoadingView extends StatelessWidget {
  const _DetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _DetailErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _DetailErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to load details', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(error, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  final double height;

  const _LoadingShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(height: height, borderRadius: AppTheme.radiusMd);
  }
}

class _MoreOptionsSheet extends StatelessWidget {
  final MediaItem item;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onMediaInfo;
  final VoidCallback? onReportIssue;

  const _MoreOptionsSheet({
    required this.item,
    this.onDownload,
    this.onShare,
    this.onAddToPlaylist,
    this.onMediaInfo,
    this.onReportIssue,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: AppTheme.blurHeavy,
      opacity: 0.1,
      borderRadius: AppTheme.radiusXl,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          _buildOption(context, Icons.download_outlined, 'Download', onDownload),
          _buildOption(context, Icons.playlist_add, 'Add to Playlist', onAddToPlaylist),
          _buildOption(context, Icons.share_outlined, 'Share', onShare),
          _buildOption(context, Icons.info_outline, 'Media Info', onMediaInfo),
          _buildOption(context, Icons.bug_report_outlined, 'Report Issue', onReportIssue),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String label, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap != null
          ? () {
              Navigator.pop(context);
              onTap();
            }
          : () {},
    );
  }
}

/// A focusable action button with controller/remote support
class _FocusableActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final bool autofocus;

  const _FocusableActionButton({
    required this.child,
    this.onPressed,
    this.width,
    this.height = 54,
    this.backgroundColor,
    this.autofocus = false,
  });

  @override
  State<_FocusableActionButton> createState() => _FocusableActionButtonState();
}

class _FocusableActionButtonState extends State<_FocusableActionButton> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_isFocused) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!ControllerService.isKeyDown(event)) {
      return KeyEventResult.ignored;
    }

    final action = ControllerService.getAction(event);
    if (action == ControllerAction.select) {
      widget.onPressed?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final hasBgColor = widget.backgroundColor != null;
    final borderRadius = BorderRadius.circular(14);

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: hasBgColor
              ? Container(
                  width: widget.width,
                  height: widget.height,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: _isFocused
                          ? AppColors.primary
                          : Colors.transparent,
                      width: _isFocused ? 2 : 1,
                    ),
                  ),
                  child: Center(child: widget.child),
                )
              : GlassContainer(
                  blur: AppTheme.blurLight,
                  opacity: _isFocused ? 0.16 : 0.1,
                  borderRadius: 14,
                  borderColor: _isFocused
                      ? AppColors.primary.withValues(alpha: 0.9)
                      : AppColors.glassBorder.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: widget.width,
                    height: widget.height,
                    child: Center(child: widget.child),
                  ),
                ),
        ),
      ),
    );
  }
}

/// A focusable download progress button with controller/remote support
class _FocusableDownloadProgress extends StatefulWidget {
  final double progress;
  final VoidCallback onPressed;

  const _FocusableDownloadProgress({
    required this.progress,
    required this.onPressed,
  });

  @override
  State<_FocusableDownloadProgress> createState() =>
      _FocusableDownloadProgressState();
}

class _FocusableDownloadProgressState
    extends State<_FocusableDownloadProgress> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!ControllerService.isKeyDown(event)) {
      return KeyEventResult.ignored;
    }

    final action = ControllerService.getAction(event);
    if (action == ControllerAction.select) {
      widget.onPressed();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused
                  ? AppColors.primary
                  : AppColors.divider.withValues(alpha: 0.5),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: widget.progress,
                  strokeWidth: 2,
                  color: AppColors.primary,
                  backgroundColor: AppColors.divider,
                ),
              ),
              Icon(
                Icons.pause_rounded,
                size: 18,
                color: _isFocused ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _DetailMobile extends ConsumerStatefulWidget {
  final String itemId;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const _DetailMobile({
    required this.itemId,
    this.initialSeasonId,
    this.initialEpisodeId,
  });

  @override
  ConsumerState<_DetailMobile> createState() => _DetailMobileState();
}

class _DetailMobileState extends ConsumerState<_DetailMobile>
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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
        isInWatchlist: isInWatchlist.when(
              data: (d) => d,
              loading: () => null,
              error: (_, stackTrace) => null,
            ) ?? false,
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
                          builder: (_) => AdaptiveDetailPage(itemId: item.id),
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
