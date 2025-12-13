import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/download_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'mobile_library.dart';
import 'mobile_detail.dart';

class MobileHome extends ConsumerStatefulWidget {
  const MobileHome({super.key});

  @override
  ConsumerState<MobileHome> createState() => _MobileHomeState();
}

class _MobileHomeState extends ConsumerState<MobileHome> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    ref.read(libraryProvider.notifier).loadLibraries();
    ref.read(libraryProvider.notifier).loadHomeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BlurBackdrop(
      blur: AppTheme.blurMedium,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            _pageController.jumpToPage(index);
          },
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.video_library_outlined),
              selectedIcon: Icon(Icons.video_library),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Icon(Icons.download_outlined),
              selectedIcon: Icon(Icons.download),
              label: 'Downloads',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    final libraryState = ref.watch(libraryProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(libraryProvider.notifier).loadHomeData();
      },
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: BlurBackdrop(
              blur: AppTheme.blurLight,
              child: const SizedBox.expand(),
            ),
            title: Row(
              children: [
                Text(
                  'Finar',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // User avatar
                Consumer(
                  builder: (context, ref, _) {
                    final user = ref.watch(authProvider).user;
                    return GestureDetector(
                      onTap: () => _showUserMenu(),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.surface,
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'U',
                          style: AppTextStyles.labelMedium,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Hero banner
          if (libraryState.featuredItem != null)
            SliverToBoxAdapter(
              child: _buildHeroBanner(libraryState.featuredItem!, serverUrl),
            ),

          // Continue watching
          if (libraryState.continueWatching.isNotEmpty) ...[
            _buildSectionHeader('Continue Watching'),
            SliverToBoxAdapter(
              child: _buildContinueWatchingRow(
                  libraryState.continueWatching, serverUrl),
            ),
          ],

          // Next Up
          if (libraryState.nextUp.isNotEmpty) ...[
            _buildSectionHeader('Next Up'),
            SliverToBoxAdapter(
              child: _buildMediaRow(libraryState.nextUp, serverUrl),
            ),
          ],

          // Recently Added
          if (libraryState.recentlyAdded.isNotEmpty) ...[
            _buildSectionHeader('Recently Added'),
            SliverToBoxAdapter(
              child: _buildMediaRow(libraryState.recentlyAdded, serverUrl),
            ),
          ],

          // New Releases
          if (libraryState.recentlyReleased.isNotEmpty) ...[
            _buildSectionHeader('New Releases'),
            SliverToBoxAdapter(
              child: _buildMediaRow(libraryState.recentlyReleased, serverUrl),
            ),
          ],

          // New Movies
          if (libraryState.recentlyAddedMovies.isNotEmpty) ...[
            _buildSectionHeader('New Movies'),
            SliverToBoxAdapter(
              child: _buildMediaRow(libraryState.recentlyAddedMovies, serverUrl),
            ),
          ],

          // New TV Shows
          if (libraryState.recentlyAddedShows.isNotEmpty) ...[
            _buildSectionHeader('New TV Shows'),
            SliverToBoxAdapter(
              child: _buildMediaRow(libraryState.recentlyAddedShows, serverUrl),
            ),
          ],

          // Recommended
          if (libraryState.recommended.isNotEmpty) ...[
            _buildSectionHeader('Recommended For You'),
            SliverToBoxAdapter(
              child: _buildMediaRow(libraryState.recommended, serverUrl),
            ),
          ],

          // Top Rated
          if (libraryState.topRated.isNotEmpty) ...[
            _buildSectionHeader('Top Rated'),
            SliverToBoxAdapter(
              child: _buildMediaRow(libraryState.topRated, serverUrl),
            ),
          ],

          // Favorites
          if (libraryState.favorites.isNotEmpty) ...[
            _buildSectionHeader('My Favorites'),
            SliverToBoxAdapter(
              child: _buildMediaRow(libraryState.favorites, serverUrl),
            ),
          ],

          // Libraries
          if (libraryState.libraries.isNotEmpty) ...[
            _buildSectionHeader('My Libraries'),
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
    );
  }

  Widget _buildHeroBanner(dynamic item, String serverUrl) {
    return GestureDetector(
      onTap: () => _navigateToDetail(item.id),
      child: Container(
        height: 280,
        margin: const EdgeInsets.all(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: CachedNetworkImage(
                imageUrl: item.getBackdropImageUrl(serverUrl, width: 800),
                fit: BoxFit.cover,
                placeholder: (_, _) => const ShimmerLoading(),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.movie, size: 48),
                ),
              ),
            ),

            // Gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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

            // Content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.headlineMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _playItem(item),
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text('Play'),
                        ),
                      ),
                      const SizedBox(width: 12),
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
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  SliverToBoxAdapter _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Text(title, style: AppTextStyles.titleLarge),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueWatchingRow(List<dynamic> items, String serverUrl) {
    return SizedBox(
      height: 140,
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
    return GestureDetector(
      onTap: () => _playItem(item),
      child: SizedBox(
        width: 200,
        child: GlassContainer(
          blur: AppTheme.blurLight,
          opacity: 0.08,
          borderRadius: AppTheme.radiusMd,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with progress
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusMd),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: item.getPrimaryImageUrl(serverUrl, width: 400),
                        fit: BoxFit.cover,
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 40,
                        color: AppColors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: item.progressPercent ?? 0.0,
                        backgroundColor: AppColors.black.withValues(alpha: 0.5),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),

              // Info
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  item.name,
                  style: AppTextStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          builder: (_) => MobileLibrary(libraryId: library.id),
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
            title: Text('Library', style: AppTextStyles.headlineMedium),
            backgroundColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final library = libraries[index];
                  return GlassCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MobileLibrary(libraryId: library.id),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getLibraryIcon(library.collectionType),
                          size: 40,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          library.name,
                          style: AppTextStyles.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
                childCount: libraries.length,
              ),
            ),
          ),
        ],
      ),
    );
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
                      placeholder: (_, __) => Container(
                        width: 56,
                        height: 80,
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.movie_outlined, color: AppColors.textTertiary),
                      ),
                      errorWidget: (_, __, ___) => Container(
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

  const _UserMenuSheet({required this.onLogout});

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
            onTap: () {},
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
