import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import '../../detail.dart';
import '../../player.dart';
import '../../settings/widgets/settings_mobile.dart';
import '../../library/library_page.dart';
import '../../downloads.dart';
import 'home_search_page.dart';
import 'home_favorites_view.dart';
import 'home_library_browser.dart';
import 'home_see_all_page.dart';
import 'home_widgets.dart';

class HomeMobile extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeMobile({this.initialIndex = 0});

  @override
  ConsumerState<HomeMobile> createState() => HomeMobileState();
}

class HomeMobileState extends ConsumerState<HomeMobile>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  final PageController _heroPageController = PageController(
    viewportFraction: 0.92,
  );
  int _currentHeroIndex = 0;
  bool _isPlayerExpanded = false;

  // Dynamic colors from hero artwork
  Color _dominantColor = AppColors.background;
  Color _accentColor = AppColors.primary;
  String? _lastColorExtractedItemId;

  // Downloads is hidden on web, so the settings tab index shifts.
  static const int _downloadsIndex = 3;
  static int get _settingsIndex => kIsWeb ? 3 : 4;

  // Bottom nav order: Home, Search, Library, Downloads (not on web), Settings.
  static int _sectionToIndex(ShellSection section) => switch (section) {
    ShellSection.home => 0,
    ShellSection.search => 1,
    ShellSection.library => 2,
    ShellSection.downloads => _downloadsIndex,
    ShellSection.settings => _settingsIndex,
    // Favorites has no mobile tab; it renders as an overlay and the nav
    // keeps Home highlighted underneath.
    ShellSection.favorites => 0,
  };

  static ShellSection _indexToSection(int index) {
    if (kIsWeb) {
      return switch (index) {
        1 => ShellSection.search,
        2 => ShellSection.library,
        3 => ShellSection.settings,
        _ => ShellSection.home,
      };
    }
    return switch (index) {
      1 => ShellSection.search,
      2 => ShellSection.library,
      3 => ShellSection.downloads,
      4 => ShellSection.settings,
      _ => ShellSection.home,
    };
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _sectionToIndex(ref.read(shellNavProvider).section),
    );
    // Delay provider modification until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = ref.read(shellNavProvider);
      if (widget.initialIndex != 0 &&
          nav.section == ShellSection.home &&
          nav.libraryId == null) {
        final maxIndex = kIsWeb ? 3 : 4;
        ref
            .read(shellNavProvider.notifier)
            .goTo(_indexToSection(widget.initialIndex.clamp(0, maxIndex)));
      }
      _loadData();
    });
  }

  void _loadData() {
    final libraryState = ref.read(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);
    // Skip reloads on remount (e.g. after a layout switch) so the home tab
    // does not flash a spinner every time the window crosses the breakpoint.
    if (libraryState.libraries.isEmpty) {
      notifier.loadLibraries();
    }
    if (libraryState.homeData == null && !libraryState.isLoading) {
      notifier.loadHomeData();
    }
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

  @override
  void dispose() {
    _pageController.dispose();
    _heroPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showMiniPlayer = ref.watch(showMiniPlayerProvider);
    final playerState = ref.watch(playerProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final nav = ref.watch(shellNavProvider);
    final isMusic =
        playerState.currentItem?.type.name == 'audio' ||
        playerState.currentItem?.type.name == 'album';

    // Keep the PageView in sync with the shared navigation state.
    ref.listen<ShellNavState>(shellNavProvider, (previous, next) {
      final index = _sectionToIndex(next.section);
      if (_pageController.hasClients &&
          _pageController.page?.round() != index) {
        _pageController.jumpToPage(index);
      }
    });

    // If offline, force navigation to downloads. Settings stays reachable
    // since it only touches local state.
    if (!isOnline &&
        !kIsWeb &&
        nav.section != ShellSection.downloads &&
        nav.section != ShellSection.settings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(shellNavProvider.notifier)
              .goTo(ShellSection.downloads);
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main page content
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              // Prevent navigation away from downloads when offline
              if (!isOnline &&
                  !kIsWeb &&
                  index != _downloadsIndex &&
                  index != _settingsIndex) {
                _pageController.jumpToPage(_downloadsIndex);
                return;
              }
              // Skip the programmatic jump fired by the provider listener so
              // an open library (same tab index) is not closed.
              final current = _sectionToIndex(
                ref.read(shellNavProvider).section,
              );
              if (index != current) {
                ref
                    .read(shellNavProvider.notifier)
                    .goTo(_indexToSection(index));
              }
            },
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildHomePage(),
              _buildSearchPage(),
              _buildLibraryPage(),
              if (!kIsWeb) _buildDownloadsPage(),
              _buildSettingsPage(),
            ],
          ),

          // Favorites has no bottom-nav tab; it covers the content when it is
          // the active section (reached by resizing down from desktop).
          if (nav.section == ShellSection.favorites)
            const Positioned.fill(child: MobileFavoritesView()),

          // Offline banner
          if (!isOnline)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: _buildOfflineBanner(),
            ),

          // Expanded music player overlay
          if (_isPlayerExpanded && showMiniPlayer && isMusic)
            ExpandedMusicPlayer(
              onCollapse: () => setState(() => _isPlayerExpanded = false),
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player above nav bar
          if (showMiniPlayer && isMusic && !_isPlayerExpanded)
            MobileMiniPlayer(
              onExpand: () => setState(() => _isPlayerExpanded = true),
            ),
          _buildBottomNav(isOnline: isOnline),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You\'re offline',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Only downloaded content is available',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.read(connectivityProvider.notifier).refresh();
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Retry connection',
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -1, end: 0, duration: 300.ms);
  }

  Widget _buildBottomNav({bool isOnline = true}) {
    final nav = ref.watch(shellNavProvider);
    return NavigationBar(
      selectedIndex: _sectionToIndex(nav.section),
      onDestinationSelected: (index) {
        ref.read(shellNavProvider.notifier).goTo(_indexToSection(index));
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: 'Home',
          enabled: isOnline,
        ),
        NavigationDestination(
          icon: const Icon(Icons.search_outlined),
          selectedIcon: const Icon(Icons.search_rounded),
          label: 'Search',
          enabled: isOnline,
        ),
        NavigationDestination(
          icon: const Icon(Icons.video_library_outlined),
          selectedIcon: const Icon(Icons.video_library_rounded),
          label: 'Library',
          enabled: isOnline,
        ),
        if (!kIsWeb)
          const NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download_rounded),
            label: 'Downloads',
          ),
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }

  /// Scale factor for the main content header (1.0 at 600px width, up to ~1.35 on large screens).
  static double _headerScaleFactor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= 600) return 1.0;
    return 1.0 + ((w - 600) / 1200).clamp(0.0, 1.0) * 0.35;
  }

  static double _scale(BuildContext context, double base) =>
      base * _headerScaleFactor(context);

  static double _desktopHeaderToolbarHeight(BuildContext context) =>
      64 * _headerScaleFactor(context);

  Widget _buildHomePage() {
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
                        onPressed: _goToSettingsTab,
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
                  onSeeAll: () => _openSeeAllMedia(
                    title: 'Continue Watching',
                    items: libraryState.continueWatching,
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
                  onSeeAll: () => _openSeeAllMedia(
                    title: 'Next Up',
                    items: libraryState.nextUp,
                  ),
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
                  onSeeAll: () => _openSeeAllMedia(
                    title: 'Recently Added',
                    items: libraryState.recentlyAdded,
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
                  onSeeAll: () => _openSeeAllMedia(
                    title: 'New Releases',
                    items: libraryState.recentlyReleased,
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
                  onSeeAll: () => _openSeeAllMedia(
                    title: 'New Movies',
                    items: libraryState.recentlyAddedMovies,
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
                  onSeeAll: () => _openSeeAllMedia(
                    title: 'New TV Shows',
                    items: libraryState.recentlyAddedShows,
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
                  onSeeAll: () => _openSeeAllMedia(
                    title: 'Recommended For You',
                    items: libraryState.recommended,
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
                  onSeeAll: () => _openSeeAllMedia(
                    title: 'Top Rated',
                    items: libraryState.topRated,
                  ),
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
                  onSeeAll: () => _openSeeAllMedia(
                    title: 'My Favorites',
                    items: libraryState.favorites,
                  ),
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
                  onSeeAll: () => _openSeeAllMedia(
                    title: 'Watchlist',
                    items: libraryState.watchlist,
                  ),
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
                  onSeeAll: _goToLibraryTab,
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
      onTap: () => _navigateToDetail(item.id),
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
                            onPressed: () => _playItem(item),
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
                              ? () => _addToWatchlist(item)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: Icons.info_outline,
                          size: 44,
                          onPressed: () => _navigateToDetail(item.id),
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
        cacheExtent: 400,
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
          onTap: () => _playItem(item),
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
        cacheExtent: 400,
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
            onTap: () => _navigateToDetail(item.id),
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
        cacheExtent: 300,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final library = libraries[index];
          return _buildLibraryCard(library, serverUrl, index);
        },
      ),
    );
  }

  Widget _buildLibraryCard(dynamic library, String serverUrl, int index) {
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
                    _getLibraryIcon(library.collectionType),
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

  IconData _getLibraryIcon(String? collectionType) {
    switch (collectionType) {
      case 'movies':
        return Icons.movie_outlined;
      case 'tvshows':
        return Icons.tv_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'photos':
        return Icons.photo_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  Widget _buildSearchPage() {
    return const MobileSearchPage();
  }

  Widget _buildLibraryPage() {
    final nav = ref.watch(shellNavProvider);
    final libraryId = nav.libraryId;
    if (libraryId != null) {
      return LibraryPage(
        libraryId: libraryId,
        onBack: () =>
            ref.read(shellNavProvider.notifier).closeLibrary(),
      );
    }
    return LibraryBrowser(
      onLibraryTap: (id) =>
          ref.read(shellNavProvider.notifier).openLibrary(id),
    );
  }

  Widget _buildDownloadsPage() {
    return const DownloadsPage();
  }

  Widget _buildSettingsPage() {
    return const SettingsMobile(embedded: true);
  }

  void _openSeeAllMedia({
    required String title,
    required List<MediaItem> items,
  }) {
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MobileSeeAllPage(title: title, items: items, serverUrl: serverUrl),
      ),
    );
  }

  void _goToLibraryTab() {
    ref.read(shellNavProvider.notifier).goTo(ShellSection.library);
  }

  void _goToSettingsTab() {
    ref.read(shellNavProvider.notifier).goTo(ShellSection.settings);
  }

  void _navigateToDetail(String itemId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPage(itemId: itemId)),
    );
  }

  Future<void> _addToWatchlist(MediaItem item) async {
    try {
      final isNowInWatchlist = await ref
          .read(mediaActionsProvider)
          .toggleWatchlist(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowInWatchlist
                  ? 'Added to Watchlist'
                  : 'Removed from Watchlist',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update watchlist'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _playItem(dynamic item) {
    // Get the MediaType from the item
    final itemType = item.type is MediaType
        ? item.type as MediaType
        : getMediaTypeFromString(item.type?.toString());

    if (itemType == MediaType.series) {
      // For series, play the next up episode (continue watching)
      _playSeries(item);
    } else {
      ref.read(playerProvider.notifier).play(item);
      // Navigate to player for video content
      final isMusic =
          itemType == MediaType.audio ||
          itemType == MediaType.album ||
          itemType == MediaType.musicVideo;
      if (!isMusic) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PlayerPage()));
      }
    }
  }

  Future<void> _playSeries(dynamic series) async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final nextUp = await mediaService.getNextUpForSeries(series.id);

      if (nextUp != null) {
        // Play the next up episode
        ref.read(playerProvider.notifier).play(nextUp);
        if (mounted) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PlayerPage()));
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
              ).push(MaterialPageRoute(builder: (_) => const PlayerPage()));
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
}
