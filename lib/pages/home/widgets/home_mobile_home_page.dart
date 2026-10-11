import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'home_widgets.dart';

class MobileHomePage extends ConsumerStatefulWidget {
  final void Function(String title, List<MediaItem> items) onSeeAll;
  final VoidCallback onLibraryTab;
  final VoidCallback onSettingsTab;
  final void Function(String itemId) onItemTap;
  final void Function(MediaItem item) onPlayItem;
  final void Function(MediaItem item) onAddToWatchlist;

  const MobileHomePage({
    super.key,
    required this.onSeeAll,
    required this.onLibraryTab,
    required this.onSettingsTab,
    required this.onItemTap,
    required this.onPlayItem,
    required this.onAddToWatchlist,
  });

  @override
  ConsumerState<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends ConsumerState<MobileHomePage> {
  final PageController _heroPageController = PageController(
    viewportFraction: 0.92,
  );
  int _currentHeroIndex = 0;

  // Dynamic colors from hero artwork
  Color _dominantColor = AppColors.background;
  Color _accentColor = AppColors.primary;
  String? _lastColorExtractedItemId;

  @override
  void dispose() {
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _extractColorsFromItem(dynamic item, String serverUrl) async {
    if (item == null || item.id == _lastColorExtractedItemId) return;
    _lastColorExtractedItemId = item.id;

    try {
      final imageUrl = item.getDisplayImageUrl(serverUrl, width: 100);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100),
        maximumColorCount: 16,
      );

      if (mounted) {
        setState(() {
          _dominantColor =
              paletteGenerator.dominantColor?.color ?? AppColors.background;
          _accentColor =
              paletteGenerator.vibrantColor?.color ??
              paletteGenerator.mutedColor?.color ??
              Theme.of(context).colorScheme.primary;
        });
      }
    } catch (e) {
      // Keep current colors on error
    }
  }

  static double _headerScaleFactor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= 600) return 1.0;
    return 1.0 + ((w - 600) / 1200).clamp(0.0, 1.0) * 0.35;
  }

  static double _scale(BuildContext context, double base) =>
      base * _headerScaleFactor(context);

  static double _desktopHeaderToolbarHeight(BuildContext context) =>
      64 * _headerScaleFactor(context);

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    // Show loading state
    if (libraryState.isLoading && libraryState.homeData == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // Get featured items for hero carousel
    final heroItems = <dynamic>[
      if (libraryState.featuredItem != null) libraryState.featuredItem,
      ...libraryState.recentlyAdded.take(4),
    ].take(5).toList();

    // Extract colors from current hero item
    if (heroItems.isNotEmpty && _currentHeroIndex < heroItems.length) {
      _extractColorsFromItem(heroItems[_currentHeroIndex], serverUrl);
    }

    return Stack(
      children: [
        // Animated gradient background
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _dominantColor.withValues(alpha: 0.6),
                _accentColor.withValues(alpha: 0.2),
                AppColors.background,
              ],
              stops: const [0.0, 0.3, 0.6],
            ),
          ),
        ),

        RefreshIndicator(
          onRefresh: () async {
            await ref.read(libraryProvider.notifier).loadHomeData();
          },
          color: Theme.of(context).colorScheme.primary,
          child: CustomScrollView(
            slivers: [
              // App bar - scaled for desktop (larger on big screens)
              SliverAppBar(
                floating: true,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: _desktopHeaderToolbarHeight(context),
                title: Row(
                  children: [
                    // Logo with refined styling
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _scale(context, 14),
                        vertical: _scale(context, 8),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(
                          _scale(context, 16),
                        ),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: _scale(context, 28),
                            height: _scale(context, 28),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                _scale(context, 8),
                              ),
                            ),
                            child: SvgPicture.asset(
                              'icon.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(width: _scale(context, 10)),
                          Text(
                            'Finar',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: _scale(context, 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Settings button with refined styling
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(
                          _scale(context, 12),
                        ),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.settings_outlined,
                          size: _scale(context, 22),
                        ),
                        onPressed: widget.onSettingsTab,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Hero carousel
              if (heroItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: _buildHeroCarousel(heroItems, serverUrl),
                  ),
                ),

              // Continue watching
              if (libraryState.continueWatching.isNotEmpty) ...[
                _buildSectionHeader(
                  'Continue Watching',
                  icon: Icons.play_circle_outline,
                  onSeeAll: () => widget.onSeeAll(
                    'Continue Watching',
                    libraryState.continueWatching,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildContinueWatchingRow(
                    libraryState.continueWatching,
                    serverUrl,
                  ),
                ),
              ],

              // Next Up
              if (libraryState.nextUp.isNotEmpty) ...[
                _buildSectionHeader(
                  'Next Up',
                  icon: Icons.skip_next_outlined,
                  onSeeAll: () =>
                      widget.onSeeAll('Next Up', libraryState.nextUp),
                ),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.nextUp, serverUrl),
                ),
              ],

              // Recently Added
              if (libraryState.recentlyAdded.isNotEmpty) ...[
                _buildSectionHeader(
                  'Recently Added',
                  icon: Icons.new_releases_outlined,
                  onSeeAll: () => widget.onSeeAll(
                    'Recently Added',
                    libraryState.recentlyAdded,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.recentlyAdded, serverUrl),
                ),
              ],

              // New Releases
              if (libraryState.recentlyReleased.isNotEmpty) ...[
                _buildSectionHeader(
                  'New Releases',
                  icon: Icons.fiber_new_outlined,
                  onSeeAll: () => widget.onSeeAll(
                    'New Releases',
                    libraryState.recentlyReleased,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildMediaRow(
                    libraryState.recentlyReleased,
                    serverUrl,
                  ),
                ),
              ],

              // New Movies
              if (libraryState.recentlyAddedMovies.isNotEmpty) ...[
                _buildSectionHeader(
                  'New Movies',
                  icon: Icons.movie_outlined,
                  onSeeAll: () => widget.onSeeAll(
                    'New Movies',
                    libraryState.recentlyAddedMovies,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildMediaRow(
                    libraryState.recentlyAddedMovies,
                    serverUrl,
                  ),
                ),
              ],

              // New TV Shows
              if (libraryState.recentlyAddedShows.isNotEmpty) ...[
                _buildSectionHeader(
                  'New TV Shows',
                  icon: Icons.tv_outlined,
                  onSeeAll: () => widget.onSeeAll(
                    'New TV Shows',
                    libraryState.recentlyAddedShows,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildMediaRow(
                    libraryState.recentlyAddedShows,
                    serverUrl,
                  ),
                ),
              ],

              // Recommended
              if (libraryState.recommended.isNotEmpty) ...[
                _buildSectionHeader(
                  'Recommended For You',
                  icon: Icons.thumb_up_outlined,
                  onSeeAll: () => widget.onSeeAll(
                    'Recommended For You',
                    libraryState.recommended,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.recommended, serverUrl),
                ),
              ],

              // Top Rated
              if (libraryState.topRated.isNotEmpty) ...[
                _buildSectionHeader(
                  'Top Rated',
                  icon: Icons.star_outline,
                  onSeeAll: () =>
                      widget.onSeeAll('Top Rated', libraryState.topRated),
                ),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.topRated, serverUrl),
                ),
              ],

              // Favorites
              if (libraryState.favorites.isNotEmpty) ...[
                _buildSectionHeader(
                  'My Favorites',
                  icon: Icons.favorite_outline,
                  onSeeAll: () =>
                      widget.onSeeAll('My Favorites', libraryState.favorites),
                ),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.favorites, serverUrl),
                ),
              ],

              // Watchlist
              if (libraryState.watchlist.isNotEmpty) ...[
                _buildSectionHeader(
                  'Watchlist',
                  icon: Icons.bookmark_outline,
                  onSeeAll: () =>
                      widget.onSeeAll('Watchlist', libraryState.watchlist),
                ),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.watchlist, serverUrl),
                ),
              ],

              // Libraries
              if (libraryState.libraries.isNotEmpty) ...[
                _buildSectionHeader(
                  'My Libraries',
                  icon: Icons.folder_outlined,
                  onSeeAll: widget.onLibraryTab,
                ),
                SliverToBoxAdapter(
                  child: _buildLibrariesRow(libraryState.libraries, serverUrl),
                ),
              ],

              // Bottom padding to clear the floating navbar
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCarousel(List<dynamic> items, String serverUrl) {
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _heroPageController,
            itemCount: items.length,
            onPageChanged: (index) {
              setState(() => _currentHeroIndex = index);
              _extractColorsFromItem(items[index], serverUrl);
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return AnimatedBuilder(
                animation: _heroPageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_heroPageController.position.haveDimensions) {
                    value = _heroPageController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.85, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: _buildHeroCard(
                      item,
                      serverUrl,
                      index == _currentHeroIndex,
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Page indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == _currentHeroIndex ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == _currentHeroIndex
                    ? _accentColor
                    : AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHeroCard(dynamic item, String serverUrl, bool isActive) {
    // Blend the poster's dominant color toward black so the scrim stays dark
    // enough for white text even on pale artwork.
    final scrim = Color.lerp(_dominantColor, Colors.black, 0.55)!;
    return GestureDetector(
      onTap: () => widget.onItemTap(item.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              CachedNetworkImage(
                imageUrl: item.getBackdropImageUrl(serverUrl, width: 800),
                memCacheWidth: 800,
                memCacheHeight: 1000,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: _dominantColor.withValues(alpha: 0.3),
                  child: const ShimmerLoading(),
                ),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.movie, size: 48),
                ),
              ),

              // Gradient overlay tinted by the poster but kept dark for contrast
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      scrim.withValues(alpha: 0.75),
                      scrim.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type?.toString().split('.').last.toUpperCase() ??
                            'MOVIE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item is MediaItem
                          ? item.heroTitle
                          : (item.name?.toString() ?? ''),
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Meta info row
                    Row(
                      children: [
                        if (item.productionYear != null) ...[
                          Text(
                            item.productionYear.toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item.communityRating != null) ...[
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            item.communityRating.toStringAsFixed(1),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onPlayItem(item),
                            icon: const Icon(Icons.play_arrow, size: 20),
                            label: const Text('Play'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GlassIconButton(
                          icon: Icons.add,
                          size: 44,
                          onPressed: item is MediaItem
                              ? () => widget.onAddToWatchlist(item)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: Icons.info_outline,
                          size: 44,
                          onPressed: () => widget.onItemTap(item.id),
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
    ).animate().fadeIn(duration: 300.ms);
  }

  SliverToBoxAdapter _buildSectionHeader(
    String title, {
    IconData? icon,
    VoidCallback? onSeeAll,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface,
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See All',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueWatchingRow(List<MediaItem> items, String serverUrl) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
        scrollCacheExtent: ScrollCacheExtent.pixels(400),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildContinueWatchingCard(item, serverUrl, index);
        },
      ),
    );
  }

  Widget _buildContinueWatchingCard(
    MediaItem item,
    String serverUrl,
    int index,
  ) {
    final progress = item.progressPercent;
    // Calculate remaining runtime from runtimeTicks and playbackPositionTicks
    final runtimeTicks = item.runtimeTicks;
    final positionTicks =
        item.userData?.playbackPositionTicks ?? item.playbackPositionTicks ?? 0;
    final remainingTicks =
        (runtimeTicks != null && runtimeTicks > positionTicks)
        ? runtimeTicks - positionTicks
        : null;
    final remainingMinutes = remainingTicks != null
        ? (remainingTicks / 600000000)
              .round() // Ticks to minutes (10,000 ticks per ms, 60,000 ms per min)
        : null;

    return GestureDetector(
          onTap: () => widget.onPlayItem(item),
          child: Container(
            width: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: _dominantColor.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  CachedNetworkImage(
                    imageUrl: item.getDisplayImageUrl(serverUrl, width: 400),
                    memCacheWidth: 440,
                    memCacheHeight: 320,
                    fit: BoxFit.cover,
                  ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),

                  // Play button
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 28,
                        color: AppColors.white,
                      ),
                    ),
                  ),

                  // Progress bar
                  Positioned(
                    bottom: 44,
                    left: 8,
                    right: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.white.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation(_accentColor),
                        minHeight: 4,
                      ),
                    ),
                  ),

                  // Info
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (remainingMinutes != null)
                          Text(
                            '${remainingMinutes}m left',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 50))
        .slideX(begin: 0.1);
  }

  Widget _buildMediaRow(List<MediaItem> items, String serverUrl) {
    return SizedBox(
      height: 214,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
        scrollCacheExtent: ScrollCacheExtent.pixels(400),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return AnimatedCard(
            width: 120,
            imageUrl: item.getDisplayImageUrl(serverUrl, width: 200),
            title: item.name,
            subtitle: item.productionYear?.toString(),
            isWatched: item.isPlayed == true,
            enableEntranceAnimation: false,
            onTap: () => widget.onItemTap(item.id),
          );
        },
      ),
    );
  }

  Widget _buildLibrariesRow(List<dynamic> libraries, String serverUrl) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: libraries.length,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
        scrollCacheExtent: ScrollCacheExtent.pixels(300),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final library = libraries[index];
          return _buildLibraryCard(library, index);
        },
      ),
    );
  }

  Widget _buildLibraryCard(dynamic library, int index) {
    return GestureDetector(
          onTap: () =>
              ref.read(shellNavProvider.notifier).openLibrary(library.id),
          child: SizedBox(
            width: 160,
            child: GlassContainer(
              blur: AppTheme.blurLight,
              opacity: 0.1,
              borderRadius: AppTheme.radiusMd,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    getLibraryIconByCollectionType(library.collectionType),
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    library.name,
                    style: AppTextStyles.titleSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 50))
        .scale(begin: const Offset(0.9, 0.9));
  }
}
