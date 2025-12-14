import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/download_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'mobile_library.dart';
import 'mobile_music_library.dart';
import 'mobile_detail.dart';
import 'mobile_settings.dart';

class MobileHome extends ConsumerStatefulWidget {
  const MobileHome({super.key});

  @override
  ConsumerState<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends ConsumerState<MobileHome> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final PageController _heroPageController = PageController(viewportFraction: 0.92);
  int _currentHeroIndex = 0;
  bool _isPlayerExpanded = false;
  
  // Dynamic colors from hero artwork
  Color _dominantColor = AppColors.background;
  Color _accentColor = AppColors.primary;
  String? _lastColorExtractedItemId;

  @override
  void initState() {
    super.initState();
    // Delay provider modification until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    ref.read(libraryProvider.notifier).loadLibraries();
    ref.read(libraryProvider.notifier).loadHomeData();
  }
  
  Future<void> _extractColorsFromItem(dynamic item, String serverUrl) async {
    if (item == null || item.id == _lastColorExtractedItemId) return;
    _lastColorExtractedItemId = item.id;
    
    try {
      final imageUrl = item.getPrimaryImageUrl(serverUrl, width: 100);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100),
        maximumColorCount: 16,
      );
      
      if (mounted) {
        setState(() {
          _dominantColor = paletteGenerator.dominantColor?.color ?? AppColors.background;
          _accentColor = paletteGenerator.vibrantColor?.color ?? 
                         paletteGenerator.mutedColor?.color ?? 
                         AppColors.primary;
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
    final isMusic = playerState.currentItem?.type.name == 'audio' || 
                    playerState.currentItem?.type.name == 'album';
    
    return Scaffold(
      body: Stack(
        children: [
          // Main page content
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildHomePage(),
              _buildSearchPage(),
              _buildLibraryPage(),
              _buildDownloadsPage(),
            ],
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
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding > 0 ? bottomPadding : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              // Refined liquid glass effect
              color: Colors.black.withValues(alpha: 0.25),
              border: Border.all(
                width: 0.5,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              boxShadow: [
                // Soft ambient shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Subtle inner highlight at top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Animated pill indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  left: _getIndicatorPosition(context),
                  top: 6,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.2,
                        colors: [
                          _accentColor.withValues(alpha: 0.5),
                          _accentColor.withValues(alpha: 0.25),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Navigation items
                Row(
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                    _buildNavItem(1, Icons.search_outlined, Icons.search_rounded, 'Search'),
                    _buildNavItem(2, Icons.video_library_outlined, Icons.video_library_rounded, 'Library'),
                    _buildNavItem(3, Icons.download_outlined, Icons.download_rounded, 'Downloads'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _getIndicatorPosition(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 40; // Account for margin
    final itemWidth = screenWidth / 4;
    return (itemWidth * _currentIndex) + (itemWidth / 2) - 28;
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()..scale(isSelected ? 1.1 : 1.0),
                transformAlignment: Alignment.center,
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: 24,
                  color: isSelected 
                      ? Colors.white 
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                      ? Colors.white 
                      : Colors.white.withValues(alpha: 0.5),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    final libraryState = ref.watch(libraryProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';
    
    // Show loading state
    if (libraryState.isLoading && libraryState.homeData == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
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
          color: _accentColor,
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverAppBar(
                floating: true,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: 70,
                title: Row(
                  children: [
                    // Animated logo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _accentColor.withValues(alpha: 0.3),
                            _dominantColor.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_filled, color: _accentColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Finar',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Notifications (placeholder)
                    GlassIconButton(
                      icon: Icons.notifications_outlined,
                      size: 40,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    // User avatar
                    Consumer(
                      builder: (context, ref, _) {
                        final user = ref.watch(authProvider).user;
                        return GestureDetector(
                          onTap: () => _showUserMenu(),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _accentColor, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: _dominantColor.withValues(alpha: 0.5),
                              child: Text(
                                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Hero carousel
              if (heroItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildHeroCarousel(heroItems, serverUrl),
                ),

              // Continue watching
              if (libraryState.continueWatching.isNotEmpty) ...[
                _buildSectionHeader('Continue Watching', icon: Icons.play_circle_outline),
                SliverToBoxAdapter(
                  child: _buildContinueWatchingRow(
                      libraryState.continueWatching, serverUrl),
                ),
              ],

              // Next Up
              if (libraryState.nextUp.isNotEmpty) ...[
                _buildSectionHeader('Next Up', icon: Icons.skip_next_outlined),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.nextUp, serverUrl),
                ),
              ],

              // Recently Added
              if (libraryState.recentlyAdded.isNotEmpty) ...[
                _buildSectionHeader('Recently Added', icon: Icons.new_releases_outlined),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.recentlyAdded, serverUrl),
                ),
              ],

              // New Releases
              if (libraryState.recentlyReleased.isNotEmpty) ...[
                _buildSectionHeader('New Releases', icon: Icons.fiber_new_outlined),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.recentlyReleased, serverUrl),
                ),
              ],

              // New Movies
              if (libraryState.recentlyAddedMovies.isNotEmpty) ...[
                _buildSectionHeader('New Movies', icon: Icons.movie_outlined),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.recentlyAddedMovies, serverUrl),
                ),
              ],

              // New TV Shows
              if (libraryState.recentlyAddedShows.isNotEmpty) ...[
                _buildSectionHeader('New TV Shows', icon: Icons.tv_outlined),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.recentlyAddedShows, serverUrl),
                ),
              ],

              // Recommended
              if (libraryState.recommended.isNotEmpty) ...[
                _buildSectionHeader('Recommended For You', icon: Icons.thumb_up_outlined),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.recommended, serverUrl),
                ),
              ],

              // Top Rated
              if (libraryState.topRated.isNotEmpty) ...[
                _buildSectionHeader('Top Rated', icon: Icons.star_outline),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.topRated, serverUrl),
                ),
              ],

              // Favorites
              if (libraryState.favorites.isNotEmpty) ...[
                _buildSectionHeader('My Favorites', icon: Icons.favorite_outline),
                SliverToBoxAdapter(
                  child: _buildMediaRow(libraryState.favorites, serverUrl),
                ),
              ],

              // Libraries
              if (libraryState.libraries.isNotEmpty) ...[
                _buildSectionHeader('My Libraries', icon: Icons.folder_outlined),
                SliverToBoxAdapter(
                  child: _buildLibrariesRow(libraryState.libraries, serverUrl),
                ),
              ],

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
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
                    child: _buildHeroCard(item, serverUrl, index == _currentHeroIndex),
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
    return GestureDetector(
      onTap: () => _navigateToDetail(item.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: isActive ? [
            BoxShadow(
              color: _accentColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              CachedNetworkImage(
                imageUrl: item.getBackdropImageUrl(serverUrl, width: 800),
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

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      _dominantColor.withValues(alpha: 0.7),
                      _dominantColor.withValues(alpha: 0.95),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type?.toString().split('.').last.toUpperCase() ?? 'MOVIE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.name ?? '',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
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
                              color: AppColors.textSecondary,
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
                              color: AppColors.textSecondary,
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
                          onPressed: () {},
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

  SliverToBoxAdapter _buildSectionHeader(String title, {IconData? icon}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: _accentColor),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title, 
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
              ),
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See All',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 10, color: _accentColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueWatchingRow(List<dynamic> items, String serverUrl) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildContinueWatchingCard(item, serverUrl, index);
        },
      ),
    );
  }

  Widget _buildContinueWatchingCard(dynamic item, String serverUrl, int index) {
    final progress = item.progressPercent ?? 0.0;
    // Calculate remaining runtime from runtimeTicks and playbackPositionTicks
    final runtimeTicks = item.runtimeTicks ?? item.userData?.runtimeTicks;
    final positionTicks = item.userData?.playbackPositionTicks ?? item.playbackPositionTicks ?? 0;
    final remainingTicks = (runtimeTicks != null && runtimeTicks > positionTicks) 
        ? runtimeTicks - positionTicks 
        : null;
    final remainingMinutes = remainingTicks != null 
        ? (remainingTicks / 600000000).round()  // Ticks to minutes (10,000 ticks per ms, 60,000 ms per min)
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
                imageUrl: item.getPrimaryImageUrl(serverUrl, width: 400),
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
                        item.name ?? '',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (remainingMinutes != null)
                      Text(
                        '${remainingMinutes}m left',
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
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 50))
        .slideX(begin: 0.1);
  }

  Widget _buildMediaRow(List<dynamic> items, String serverUrl) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return AnimatedCard(
            width: 120,
            imageUrl: item.getPrimaryImageUrl(serverUrl, width: 200),
            title: item.name,
            subtitle: item.productionYear?.toString(),
            animationIndex: index,
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => library.collectionType?.toLowerCase() == 'music'
              ? MobileMusicLibrary(libraryId: library.id)
              : MobileLibrary(libraryId: library.id),
        ),
      ),
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
                color: AppColors.primary,
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
    return const _MobileSearchPage();
  }

  Widget _buildLibraryPage() {
    return const _MobileLibraryBrowser();
  }

  Widget _buildDownloadsPage() {
    return const _MobileDownloadsPage();
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserMenuSheet(
        onLogout: () {
          ref.read(authProvider.notifier).logout();
          Navigator.of(context).pop();
        },
        onSettings: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MobileSettings()),
          );
        },
      ),
    );
  }

  void _navigateToDetail(String itemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MobileDetail(itemId: itemId),
      ),
    );
  }

  void _playItem(dynamic item) {
    ref.read(playerProvider.notifier).play(item);
    // Navigate to player
  }
}

class _MobileSearchPage extends ConsumerStatefulWidget {
  const _MobileSearchPage();

  @override
  ConsumerState<_MobileSearchPage> createState() => _MobileSearchPageState();
}

class _MobileSearchPageState extends ConsumerState<_MobileSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return SafeArea(
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search movies, shows, people...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(libraryProvider.notifier).clearSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  ref.read(libraryProvider.notifier).search(value);
                }
              },
            ),
          ),

          // Results
          Expanded(
            child: searchResults.isEmpty
                ? _buildEmptySearch()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2 / 3.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final item = searchResults[index];
                      return AnimatedCard(
                        imageUrl: item.getPrimaryImageUrl(serverUrl, width: 200),
                        title: item.name,
                        subtitle: item.productionYear?.toString(),
                        animationIndex: index,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MobileDetail(itemId: item.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search your media',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find movies, TV shows, and more',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileLibraryBrowser extends ConsumerWidget {
  const _MobileLibraryBrowser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraries = ref.watch(libraryProvider).libraries;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                Icon(Icons.video_library, color: AppColors.primary),
                const SizedBox(width: 12),
                Text('Library', style: AppTextStyles.headlineMedium),
              ],
            ),
            backgroundColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final library = libraries[index];
                  final gradient = _getLibraryGradient(library.collectionType);
                  
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => library.collectionType?.toLowerCase() == 'music'
                            ? MobileMusicLibrary(libraryId: library.id)
                            : MobileLibrary(libraryId: library.id),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Pattern overlay
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Icon(
                              _getLibraryIcon(library.collectionType),
                              size: 100,
                              color: AppColors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getLibraryIcon(library.collectionType),
                                    size: 24,
                                    color: AppColors.white,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      library.name,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getLibraryTypeLabel(library.collectionType),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.white.withValues(alpha: 0.8),
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
                  ).animate()
                      .fadeIn(delay: Duration(milliseconds: index * 100))
                      .scale(begin: const Offset(0.9, 0.9));
                },
                childCount: libraries.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getLibraryGradient(String? collectionType) {
    switch (collectionType) {
      case 'movies':
        return [const Color(0xFFE53935), const Color(0xFFB71C1C)];
      case 'tvshows':
        return [const Color(0xFF1E88E5), const Color(0xFF0D47A1)];
      case 'music':
        return [const Color(0xFF43A047), const Color(0xFF1B5E20)];
      case 'photos':
        return [const Color(0xFFFF9800), const Color(0xFFE65100)];
      default:
        return [const Color(0xFF7E57C2), const Color(0xFF4527A0)];
    }
  }

  String _getLibraryTypeLabel(String? collectionType) {
    switch (collectionType) {
      case 'movies':
        return 'Movies';
      case 'tvshows':
        return 'TV Shows';
      case 'music':
        return 'Music';
      case 'photos':
        return 'Photos';
      default:
        return 'Collection';
    }
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
}

class _MobileDownloadsPage extends ConsumerWidget {
  const _MobileDownloadsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadProvider);
    final downloads = List<DownloadTask>.from(downloadState.downloads);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    // Sort downloads: active first, then completed, then others
    downloads.sort((a, b) {
      const statusOrder = {
        DownloadStatus.downloading: 0,
        DownloadStatus.pending: 1,
        DownloadStatus.paused: 2,
        DownloadStatus.completed: 3,
        DownloadStatus.failed: 4,
        DownloadStatus.cancelled: 5,
      };
      return (statusOrder[a.status] ?? 6).compareTo(statusOrder[b.status] ?? 6);
    });

    if (downloads.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.download_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Downloads',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Downloaded content will appear here',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Downloads',
                  style: AppTextStyles.headlineMedium,
                ),
                const Spacer(),
                if (downloadState.activeDownloads.isNotEmpty)
                  Text(
                    '${downloadState.activeDownloads.length} active',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final download = downloads[index];
                return _DownloadListTile(
                  download: download,
                  serverUrl: serverUrl,
                  onPause: () => ref.read(downloadProvider.notifier).pauseDownload(download.id),
                  onResume: () => ref.read(downloadProvider.notifier).resumeDownload(download.id),
                  onCancel: () => ref.read(downloadProvider.notifier).cancelDownload(download.id),
                  onRemove: () => ref.read(downloadProvider.notifier).deleteDownload(download.id),
                  onTap: () {
                    if (download.status == DownloadStatus.completed) {
                      // Navigate to detail page or play
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MobileDetail(itemId: download.itemId),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadListTile extends StatelessWidget {
  final DownloadTask download;
  final String serverUrl;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _DownloadListTile({
    required this.download,
    required this.serverUrl,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      blur: AppTheme.blurLight,
      opacity: 0.05,
      borderRadius: AppTheme.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: download.primaryImageTag != null
                  ? CachedNetworkImage(
                      imageUrl: '$serverUrl/Items/${download.itemId}/Images/Primary?fillHeight=120&fillWidth=80&tag=${download.primaryImageTag}',
                      width: 56,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 56,
                        height: 80,
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.movie_outlined, color: AppColors.textTertiary),
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 56,
                        height: 80,
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.movie_outlined, color: AppColors.textTertiary),
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 80,
                      color: AppColors.surfaceElevated,
                      child: const Icon(Icons.movie_outlined, color: AppColors.textTertiary),
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    download.itemName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildStatusRow(),
                  if (download.status == DownloadStatus.downloading ||
                      download.status == DownloadStatus.paused) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: download.progress,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        download.status == DownloadStatus.paused
                            ? AppColors.warning
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Actions
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow() {
    IconData icon;
    Color color;
    String text;

    switch (download.status) {
      case DownloadStatus.pending:
        icon = Icons.hourglass_empty;
        color = AppColors.textSecondary;
        text = 'Pending';
        break;
      case DownloadStatus.downloading:
        icon = Icons.downloading;
        color = AppColors.primary;
        text = '${(download.progress * 100).toInt()}%';
        break;
      case DownloadStatus.paused:
        icon = Icons.pause_circle_outline;
        color = AppColors.warning;
        text = 'Paused - ${(download.progress * 100).toInt()}%';
        break;
      case DownloadStatus.completed:
        icon = Icons.check_circle_outline;
        color = AppColors.success;
        text = 'Downloaded';
        break;
      case DownloadStatus.failed:
        icon = Icons.error_outline;
        color = AppColors.error;
        text = download.errorMessage ?? 'Failed';
        break;
      case DownloadStatus.cancelled:
        icon = Icons.cancel_outlined;
        color = AppColors.textSecondary;
        text = 'Cancelled';
        break;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    switch (download.status) {
      case DownloadStatus.downloading:
        return IconButton(
          onPressed: onPause,
          icon: const Icon(Icons.pause, color: AppColors.textSecondary),
          tooltip: 'Pause',
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow, color: AppColors.primary),
              tooltip: 'Resume',
            ),
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close, color: AppColors.error),
              tooltip: 'Cancel',
            ),
          ],
        );
      case DownloadStatus.pending:
        return IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          tooltip: 'Cancel',
        );
      case DownloadStatus.completed:
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          onSelected: (value) {
            if (value == 'remove') {
              onRemove();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text('Remove'),
                ],
              ),
            ),
          ],
        );
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onResume,
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              tooltip: 'Retry',
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Remove',
            ),
          ],
        );
    }
  }
}

class _UserMenuSheet extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onSettings;

  const _UserMenuSheet({required this.onLogout, required this.onSettings});

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
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              onSettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
