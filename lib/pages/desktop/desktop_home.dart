import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/library.dart';
import '../../core/api/media_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'desktop_library.dart';
import 'desktop_music_library.dart';
import 'desktop_detail.dart';
import 'desktop_downloads.dart';
import 'desktop_settings.dart';

class DesktopHome extends ConsumerStatefulWidget {
  const DesktopHome({super.key});

  @override
  ConsumerState<DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends ConsumerState<DesktopHome> {
  int _selectedIndex = 0;
  String? _selectedLibraryId;

  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homeDataProvider);
    final libraries = ref.watch(librariesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(libraries),
          
          // Main content
          Expanded(
            child: homeData.when(
              data: (data) => _buildContent(data),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stack) => _buildError(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AsyncValue<List<Library>> librariesAsync) {
    return GlassContainer(
      width: 240,
      blur: AppTheme.blurLight,
      opacity: 0.05,
      borderRadius: 0,
      showBorder: false,
      child: Column(
        children: [
          // App logo
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.play_circle_fill,
                    color: AppColors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Finar',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: AppColors.glassBorder),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search,
                  label: 'Search',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.favorite_outline,
                  activeIcon: Icons.favorite,
                  label: 'Favorites',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.download_outlined,
                  activeIcon: Icons.download,
                  label: 'Downloads',
                  index: 3,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DesktopDownloads(),
                      ),
                    );
                  },
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text(
                    'LIBRARIES',
                    style: AppTextStyles.labelSmall,
                  ),
                ),
                
                librariesAsync.when(
                  data: (libraries) => Column(
                    children: libraries.map((lib) => _buildLibraryItem(lib)).toList(),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerLoading(height: 40),
                  ),
                  error: (_, _) => const SizedBox(),
                ),
                
                const SizedBox(height: 16),
                const Divider(color: AppColors.glassBorder),
                
                _buildNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  index: 100,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DesktopSettings(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // User profile
          _buildUserProfile(),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppTheme.durationNormal)
        .slideX(begin: -0.1, end: 0, duration: AppTheme.durationNormal);
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == index && _selectedLibraryId == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap ?? () {
            setState(() {
              _selectedIndex = index;
              _selectedLibraryId = null;
            });
          },
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryItem(Library library) {
    final isSelected = _selectedLibraryId == library.id;
    final icon = _getLibraryIcon(library.icon);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () {
            setState(() {
              _selectedLibraryId = library.id;
              _selectedIndex = -1;
            });
          },
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    library.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (library.childCount != null)
                  Text(
                    library.childCount.toString(),
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getLibraryIcon(LibraryIcon icon) {
    switch (icon) {
      case LibraryIcon.movies:
        return Icons.movie_outlined;
      case LibraryIcon.tvShows:
        return Icons.tv_outlined;
      case LibraryIcon.music:
        return Icons.music_note_outlined;
      case LibraryIcon.photos:
        return Icons.photo_library_outlined;
      case LibraryIcon.collections:
        return Icons.collections_outlined;
      case LibraryIcon.homeVideos:
        return Icons.videocam_outlined;
      case LibraryIcon.playlists:
        return Icons.playlist_play_outlined;
      case LibraryIcon.liveTv:
        return Icons.live_tv_outlined;
      case LibraryIcon.books:
        return Icons.book_outlined;
      case LibraryIcon.folder:
        return Icons.folder_outlined;
    }
  }

  Widget _buildUserProfile() {
    final user = ref.watch(currentUserProvider);
    final authNotifier = ref.watch(authProvider.notifier);

    return GlassContainer(
      margin: const EdgeInsets.all(16),
      blur: AppTheme.blurLight,
      opacity: 0.1,
      borderRadius: AppTheme.radiusMd,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(
              user?.name.substring(0, 1).toUpperCase() ?? '?',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Guest',
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  authNotifier.serverUrl ?? '',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => _showLogoutDialog(),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(HomeData data) {
    if (_selectedLibraryId != null) {
      return DesktopLibrary(libraryId: _selectedLibraryId!);
    }

    switch (_selectedIndex) {
      case 1:
        return _buildSearchView();
      case 2:
        return _buildFavoritesView();
      case 100:
        return _buildSettingsView();
      default:
        return _buildHomeContent(data);
    }
  }

  Widget _buildHomeContent(HomeData data) {
    return CustomScrollView(
      slivers: [
        // Hero section
        SliverToBoxAdapter(
          child: data.recentlyAdded.isNotEmpty
              ? HeroCard(
                  imageUrl: data.recentlyAdded.first
                      .getBackdropUrl(ref.read(jellyfinApiProvider).serverUrl ?? '', width: 1920),
                  title: data.recentlyAdded.first.name,
                  subtitle: data.recentlyAdded.first.typeString,
                  description: data.recentlyAdded.first.overview,
                  year: data.recentlyAdded.first.productionYear?.toString(),
                  rating: data.recentlyAdded.first.communityRating?.toStringAsFixed(1),
                  runtime: data.recentlyAdded.first.formattedRuntime,
                  genres: data.recentlyAdded.first.genres?.take(3).toList(),
                  onTap: () => _navigateToDetail(data.recentlyAdded.first),
                  onPlay: () => _playItem(data.recentlyAdded.first),
                  onInfo: () => _navigateToDetail(data.recentlyAdded.first),
                )
              : const SizedBox(height: 300),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        
        // Continue Watching
        if (data.continueWatching.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildMediaRow(
              title: 'Continue Watching',
              items: data.continueWatching,
              showProgress: true,
            ),
          ),
        
        // Next Up
        if (data.nextUp.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildMediaRow(
              title: 'Next Up',
              items: data.nextUp,
            ),
          ),
        
        // Recently Added
        if (data.recentlyAdded.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildMediaRow(
              title: 'Recently Added',
              items: data.recentlyAdded.skip(1).toList(),
            ),
          ),
        
        // Recently Released Movies
        if (data.recentlyReleased.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildMediaRow(
              title: 'New Releases',
              items: data.recentlyReleased,
            ),
          ),
        
        // Recently Added Movies
        if (data.recentlyAddedMovies.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildMediaRow(
              title: 'New Movies',
              items: data.recentlyAddedMovies,
            ),
          ),
        
        // Recently Added Shows
        if (data.recentlyAddedShows.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildMediaRow(
              title: 'New TV Shows',
              items: data.recentlyAddedShows,
            ),
          ),
        
        // Recommended
        if (data.recommended.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildMediaRow(
              title: 'Recommended For You',
              items: data.recommended,
            ),
          ),
        
        // Top Rated
        if (data.topRated.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildMediaRow(
              title: 'Top Rated',
              items: data.topRated,
            ),
          ),
        
        // Favorites
        if (data.favorites.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildMediaRow(
              title: 'My Favorites',
              items: data.favorites,
            ),
          ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }

  Widget _buildMediaRow({
    required String title,
    required List items,
    bool showProgress = false,
  }) {
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.headlineSmall),
                TextButton(
                  onPressed: () {},
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: 160,
                  child: AnimatedCard(
                    imageUrl: item.getPrimaryImageUrl(serverUrl, width: 300),
                    title: item.name,
                    subtitle: item.productionYear?.toString(),
                    progress: showProgress ? item.playbackProgress : null,
                    showProgress: showProgress,
                    animationIndex: index,
                    onTap: () => _navigateToDetail(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView() {
    return Center(
      child: Text(
        'Search',
        style: AppTextStyles.headlineLarge,
      ),
    );
  }

  Widget _buildFavoritesView() {
    return Center(
      child: Text(
        'Favorites',
        style: AppTextStyles.headlineLarge,
      ),
    );
  }

  Widget _buildSettingsView() {
    return Center(
      child: Text(
        'Settings',
        style: AppTextStyles.headlineLarge,
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load content',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.refresh(homeDataProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(dynamic item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DesktopDetail(itemId: item.id),
      ),
    );
  }

  void _playItem(dynamic item) {
    ref.read(playerProvider.notifier).play(item);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
