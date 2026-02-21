import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/library.dart';
import '../../core/api/models/media_item.dart';
import '../../core/api/models/user.dart';
import '../../core/api/media_service.dart';
import '../../core/services/controller_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../adaptive_pages.dart';
import 'desktop_library.dart';
import 'desktop_music_library.dart';
import 'desktop_downloads.dart';

class DesktopHome extends ConsumerStatefulWidget {
  const DesktopHome({super.key});

  @override
  ConsumerState<DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends ConsumerState<DesktopHome> {
  int _selectedIndex = 0;
  String? _selectedLibraryId;
  String? _selectedLibraryType;

  // Expanded category for "See All" functionality
  String? _expandedCategory;
  List<MediaItem>? _expandedCategoryItems;

  // Focus management for controller navigation
  final FocusNode _mainFocusNode = FocusNode();
  bool _sidebarFocused = false;
  int _focusedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Request focus when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _mainFocusNode.dispose();
    super.dispose();
  }

  /// Handle global controller/keyboard navigation
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!ControllerService.isKeyDown(event)) {
      return KeyEventResult.ignored;
    }

    final action = ControllerService.getAction(event);

    // Handle back button to navigate back or toggle sidebar
    if (action == ControllerAction.back) {
      if (_selectedLibraryId != null) {
        setState(() {
          _selectedLibraryId = null;
          _selectedLibraryType = null;
          _selectedIndex = 0;
        });
        return KeyEventResult.handled;
      }
      if (!_sidebarFocused) {
        setState(() => _sidebarFocused = true);
        return KeyEventResult.handled;
      }
    }

    // Handle menu button to toggle sidebar focus
    if (action == ControllerAction.menu) {
      setState(() => _sidebarFocused = !_sidebarFocused);
      return KeyEventResult.handled;
    }

    // Handle sidebar navigation when sidebar is focused
    if (_sidebarFocused) {
      return _handleSidebarNavigation(action);
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleSidebarNavigation(ControllerAction? action) {
    final libraries = ref.read(librariesProvider).when(
          data: (d) => d,
          loading: () => null,
          error: (_, stackTrace) => null,
        ) ?? [];
    final int maxLibraryIndex = 4 + libraries.length - 1; // Last library item index
    const settingsIndex = 100;

    switch (action) {
      case ControllerAction.up:
        setState(() {
          if (_focusedNavIndex == settingsIndex) {
            // From settings, go to last library or Downloads (index 3)
            _focusedNavIndex = libraries.isNotEmpty ? maxLibraryIndex : 3;
          } else if (_focusedNavIndex > 0) {
            _focusedNavIndex--;
          }
        });
        return KeyEventResult.handled;
      case ControllerAction.down:
        setState(() {
          if (_focusedNavIndex == maxLibraryIndex ||
              (libraries.isEmpty && _focusedNavIndex == 3)) {
            // From last item, go to settings
            _focusedNavIndex = settingsIndex;
          } else if (_focusedNavIndex < maxLibraryIndex &&
              _focusedNavIndex != settingsIndex) {
            _focusedNavIndex++;
          }
        });
        return KeyEventResult.handled;
      case ControllerAction.select:
        _activateNavItem(_focusedNavIndex, libraries);
        return KeyEventResult.handled;
      case ControllerAction.right:
        setState(() => _sidebarFocused = false);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _activateNavItem(int index, List<Library> libraries) {
    if (index == 0) {
      // Home
      setState(() {
        _selectedIndex = 0;
        _selectedLibraryId = null;
        _selectedLibraryType = null;
        _sidebarFocused = false;
      });
    } else if (index == 1) {
      // Search
      setState(() {
        _selectedIndex = 1;
        _selectedLibraryId = null;
        _selectedLibraryType = null;
        _sidebarFocused = false;
      });
    } else if (index == 2) {
      // Favorites
      setState(() {
        _selectedIndex = 2;
        _selectedLibraryId = null;
        _selectedLibraryType = null;
        _sidebarFocused = false;
      });
    } else if (index == 3) {
      // Downloads
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdaptiveDownloadsPage()),
      );
    } else if (index == 100) {
      // Settings
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdaptiveSettingsPage()),
      );
    } else if (index >= 4 && index < 4 + libraries.length) {
      // Library
      final library = libraries[index - 4];
      setState(() {
        _selectedLibraryId = library.id;
        _selectedLibraryType = library.collectionType;
        _selectedIndex = -1;
        _sidebarFocused = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homeDataProvider);
    final libraries = ref.watch(librariesProvider);
    final showMiniPlayer = ref.watch(showMiniPlayerProvider);
    final playerState = ref.watch(playerProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final isMusic =
        playerState.currentItem?.type.name == 'audio' ||
        playerState.currentItem?.type.name == 'album';
    final isVideo = playerState.currentItem != null && !isMusic;

    // If offline, redirect to downloads page
    if (!isOnline) {
      return _buildOfflineView(libraries, showMiniPlayer, isMusic, isVideo);
    }

    return Focus(
      focusNode: _mainFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Sidebar with focus support
                  _buildSidebar(libraries),

                  // Main content with FocusTraversalGroup
                  Expanded(
                    child: FocusTraversalGroup(
                      policy: OrderedTraversalPolicy(),
                      child: homeData.when(
                        data: (data) => _buildContent(data),
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                        error: (error, stack) => _buildError(error.toString()),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Music player bar at bottom
            if (showMiniPlayer && isMusic) const DesktopMusicPlayerBar(),

            // Video mini player bar (PiP mode)
            if (showMiniPlayer && isVideo) _buildVideoMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineView(
    AsyncValue<List<Library>> libraries,
    bool showMiniPlayer,
    bool isMusic,
    bool isVideo,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Offline banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.9),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
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
                TextButton.icon(
                  onPressed: () {
                    ref.read(connectivityProvider.notifier).refresh();
                  },
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'Retry',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Show downloads page directly
          const Expanded(child: DesktopDownloads()),

          // Music player bar at bottom
          if (showMiniPlayer && isMusic) const DesktopMusicPlayerBar(),

          // Video mini player bar (PiP mode)
          if (showMiniPlayer && isVideo) _buildVideoMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildSidebar(AsyncValue<List<Library>> librariesAsync) {
    return Container(
          width: 260,
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            border: Border(
              right: BorderSide(
                color: AppColors.divider.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // App logo with refined styling
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primarySoftGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: AppColors.textOnPrimary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Finar',
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                color: AppColors.divider.withValues(alpha: 0.5),
                height: 1,
              ),

              // Navigation items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    _buildNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home_rounded,
                      label: 'Home',
                      index: 0,
                      focusIndex: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.search_outlined,
                      activeIcon: Icons.search_rounded,
                      label: 'Search',
                      index: 1,
                      focusIndex: 1,
                    ),
                    _buildNavItem(
                      icon: Icons.favorite_outline_rounded,
                      activeIcon: Icons.favorite_rounded,
                      label: 'Favorites',
                      index: 2,
                      focusIndex: 2,
                    ),
                    if (!kIsWeb)
                      _buildNavItem(
                        icon: Icons.download_outlined,
                        activeIcon: Icons.download_rounded,
                        label: 'Downloads',
                        index: 3,
                        focusIndex: 3,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdaptiveDownloadsPage(),
                            ),
                          );
                        },
                      ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                      child: Text(
                        'LIBRARIES',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    librariesAsync.when(
                      data: (libraries) => Column(
                        children: libraries
                            .asMap()
                            .entries
                            .map(
                              (entry) =>
                                  _buildLibraryItem(entry.value, entry.key + 4),
                            )
                            .toList(),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: ShimmerLoading(height: 40),
                      ),
                      error: (_, _) => const SizedBox(),
                    ),

                    const SizedBox(height: 20),
                    Divider(
                      color: AppColors.divider.withValues(alpha: 0.5),
                      indent: 16,
                      endIndent: 16,
                    ),

                    _buildNavItem(
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings_rounded,
                      label: 'Settings',
                      index: 100,
                      focusIndex: 100, // Settings always at high index
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdaptiveSettingsPage(),
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
        .slideX(begin: -0.05, end: 0, duration: AppTheme.durationNormal);
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    int? focusIndex,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == index && _selectedLibraryId == null;
    final isFocused =
        _sidebarFocused && _focusedNavIndex == (focusIndex ?? index);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              onTap ??
              () {
                setState(() {
                  _selectedIndex = index;
                  _selectedLibraryId = null;
                  _selectedLibraryType = null;
                  // Clear expanded category when navigating
                  _expandedCategory = null;
                  _expandedCategoryItems = null;
                });
              },
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : isFocused
                  ? AppColors.glassActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isFocused
                  ? Border.all(color: AppColors.primary, width: 2)
                  : isSelected
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected || isFocused
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected || isFocused
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryItem(Library library, int focusIndex) {
    final isSelected = _selectedLibraryId == library.id;
    final isFocused = _sidebarFocused && _focusedNavIndex == focusIndex;
    final icon = _getLibraryIcon(library.icon);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedLibraryId = library.id;
              _selectedLibraryType = library.collectionType;
              _selectedIndex = -1;
            });
          },
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : isFocused
                  ? AppColors.glassActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isFocused
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 2,
                    )
                  : isSelected
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    library.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (library.childCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      library.childCount.toString(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';
    final userName = user?.name.trim();
    final hasUserName = userName != null && userName.isNotEmpty;
    final avatarLetter = hasUserName ? userName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildUserAvatar(user, serverUrl, avatarLetter),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUserName ? userName : 'Guest',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Signed in',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () => _showLogoutDialog(),
            tooltip: 'Sign out',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              backgroundColor: AppColors.glassWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(User? user, String serverUrl, String fallbackLetter) {
    final avatarUrl = (user != null && serverUrl.isNotEmpty)
        ? user.getAvatarUrl(serverUrl)
        : '';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: AppColors.primarySoftGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: avatarUrl.isEmpty
            ? Center(
                child: Text(
                  fallbackLetter,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    fallbackLetter,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildContent(HomeData data) {
    if (_selectedLibraryId != null) {
      if (_selectedLibraryType?.toLowerCase() == 'music') {
        return DesktopMusicLibrary(libraryId: _selectedLibraryId!);
      }
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
                  imageUrl: data.recentlyAdded.first.getBackdropUrl(
                    ref.read(jellyfinApiProvider).serverUrl ?? '',
                    width: 1920,
                  ),
                  title: data.recentlyAdded.first.heroTitle,
                  subtitle: data.recentlyAdded.first.typeString,
                  description: data.recentlyAdded.first.overview,
                  year: data.recentlyAdded.first.productionYear?.toString(),
                  rating: data.recentlyAdded.first.communityRating
                      ?.toStringAsFixed(1),
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
            child: _buildMediaRow(title: 'Next Up', items: data.nextUp),
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
            child: _buildMediaRow(title: 'Top Rated', items: data.topRated),
          ),

        // Favorites
        if (data.favorites.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildMediaRow(title: 'My Favorites', items: data.favorites),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }

  Widget _buildMediaRow({
    required String title,
    required List<MediaItem> items,
    bool showProgress = false,
  }) {
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => _showExpandedCategory(title, items),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
              itemCount: items.length,
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: false,
              cacheExtent: 500, // Pre-cache items for smoother scrolling
              separatorBuilder: (_, _) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: 170,
                  child: AnimatedCard(
                    imageUrl: item.getDisplayImageUrl(serverUrl, width: 300),
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

  /// Shows expanded category view with all items in a grid
  void _showExpandedCategory(String category, List<MediaItem> items) {
    setState(() {
      _expandedCategory = category;
      _expandedCategoryItems = items;
    });
  }

  /// Closes expanded category view and returns to grouped view
  void _closeExpandedCategory() {
    setState(() {
      _expandedCategory = null;
      _expandedCategoryItems = null;
    });
  }

  Widget _buildSearchView() {
    final searchResults = ref.watch(searchResultsProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';
    final isLoading = ref.watch(libraryProvider).isLoading;

    // If a category is expanded, show the expanded view
    if (_expandedCategory != null && _expandedCategoryItems != null) {
      return _buildExpandedCategoryView(
        _expandedCategory!,
        _expandedCategoryItems!,
        serverUrl,
      );
    }

    // Group results by type
    final groupedResults = _groupMediaByType(searchResults);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Search', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 24),

          // Search bar
          SizedBox(
            width: double.infinity,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search movies, shows, music...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  ref.read(libraryProvider.notifier).search(value);
                } else if (value.isEmpty) {
                  ref.read(libraryProvider.notifier).clearSearch();
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // Results
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : searchResults.isEmpty
                ? _buildEmptySearch()
                : _buildGroupedMediaGrid(groupedResults, serverUrl),
          ),
        ],
      ),
    );
  }

  /// Groups media items by their type for organized display
  Map<String, List<MediaItem>> _groupMediaByType(List<MediaItem> items) {
    final Map<String, List<MediaItem>> grouped = {};

    for (final item in items) {
      final category = _getMediaCategory(item.type);
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(item);
    }

    // Sort each category by name
    for (final category in grouped.keys) {
      grouped[category]!.sort((a, b) => a.name.compareTo(b.name));
    }

    return grouped;
  }

  /// Returns a user-friendly category name for the media type
  String _getMediaCategory(MediaType type) {
    switch (type) {
      case MediaType.movie:
        return 'Movies';
      case MediaType.series:
        return 'TV Shows';
      case MediaType.episode:
        return 'Episodes';
      case MediaType.season:
        return 'Seasons';
      case MediaType.audio:
      case MediaType.album:
      case MediaType.artist:
      case MediaType.musicVideo:
        return 'Music';
      case MediaType.playlist:
        return 'Playlists';
      case MediaType.boxSet:
        return 'Collections';
      default:
        return 'Other';
    }
  }

  /// Returns an icon for the media category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Movies':
        return Icons.movie_outlined;
      case 'TV Shows':
        return Icons.tv_outlined;
      case 'Episodes':
        return Icons.video_library_outlined;
      case 'Seasons':
        return Icons.folder_outlined;
      case 'Music':
        return Icons.music_note_outlined;
      case 'Playlists':
        return Icons.playlist_play_outlined;
      case 'Collections':
        return Icons.collections_bookmark_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  /// Builds a grouped grid with sections for each media type
  Widget _buildGroupedMediaGrid(
    Map<String, List<MediaItem>> groupedItems,
    String serverUrl,
  ) {
    // Define display order for categories
    const categoryOrder = [
      'Movies',
      'TV Shows',
      'Episodes',
      'Seasons',
      'Music',
      'Playlists',
      'Collections',
      'Other',
    ];

    final sortedCategories = groupedItems.keys.toList()
      ..sort((a, b) {
        final aIndex = categoryOrder.indexOf(a);
        final bIndex = categoryOrder.indexOf(b);
        if (aIndex == -1 && bIndex == -1) return a.compareTo(b);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });

    return ListView.builder(
      itemCount: sortedCategories.length,
      itemBuilder: (context, sectionIndex) {
        final category = sortedCategories[sectionIndex];
        final items = groupedItems[category]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // See All button
                  if (items.length > 5)
                    TextButton(
                      onPressed: () => _showExpandedCategory(category, items),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See All',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Items grid (horizontal scrolling row)
              SizedBox(
                height: 236,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SizedBox(
                      width: 140,
                      child: AnimatedCard(
                        imageUrl: item.getDisplayImageUrl(
                          serverUrl,
                          width: 300,
                        ),
                        title: item.name,
                        subtitle: _getItemSubtitle(item),
                        animationIndex: index,
                        isWatched: item.isPlayed == true,
                        onTap: () => _navigateToDetail(item),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the expanded category view showing all items in a grid
  Widget _buildExpandedCategoryView(
    String category,
    List<MediaItem> items,
    String serverUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              IconButton(
                onPressed: _closeExpandedCategory,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              Icon(
                _getCategoryIcon(category),
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(category, style: AppTextStyles.headlineLarge),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length} items',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Grid of all items
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 2 / 3.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return AnimatedCard(
                  imageUrl: item.getDisplayImageUrl(serverUrl, width: 300),
                  title: item.name,
                  subtitle: _getItemSubtitle(item),
                  animationIndex: index,
                  isWatched: item.isPlayed == true,
                  onTap: () => _navigateToDetail(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Gets a contextual subtitle for the item based on its type
  String? _getItemSubtitle(MediaItem item) {
    switch (item.type) {
      case MediaType.episode:
        if (item.seriesName != null) {
          final season = item.parentIndexNumber ?? 0;
          final episode = item.indexNumber ?? 0;
          return '${item.seriesName} • S${season}E$episode';
        }
        return item.productionYear?.toString();
      case MediaType.audio:
        return item.albumArtist ??
            item.album ??
            item.productionYear?.toString();
      case MediaType.album:
        return item.albumArtist ?? item.productionYear?.toString();
      case MediaType.season:
        return item.seriesName;
      default:
        return item.productionYear?.toString();
    }
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Search your media',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find movies, TV shows, music, and more',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesView() {
    final favorites = ref.watch(favoritesProvider(null));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    // If a category is expanded, show the expanded view
    if (_expandedCategory != null && _expandedCategoryItems != null) {
      return _buildExpandedCategoryView(
        _expandedCategory!,
        _expandedCategoryItems!,
        serverUrl,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.favorite, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text('Favorites', style: AppTextStyles.headlineLarge),
            ],
          ),
          const SizedBox(height: 24),

          // Content
          Expanded(
            child: favorites.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyFavorites();
                }
                // Group favorites by type
                final groupedItems = _groupMediaByType(items);
                return _buildGroupedMediaGrid(groupedItems, serverUrl);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
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
                      'Failed to load favorites',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(e.toString(), style: AppTextStyles.bodySmall),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(favoritesProvider(null)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No favorites yet',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mark items as favorites to see them here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return Center(child: Text('Settings', style: AppTextStyles.headlineLarge));
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to load content', style: AppTextStyles.headlineSmall),
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
        builder: (context) => AdaptiveDetailPage(itemId: item.id),
      ),
    );
  }

  void _playItem(dynamic item) {
    // Get the MediaType from the item
    final itemType = item.type is MediaType
        ? item.type as MediaType
        : MediaType.values.firstWhere(
            (e) =>
                e.toString().split('.').last.toLowerCase() ==
                item.type?.toString().toLowerCase(),
            orElse: () => MediaType.unknown,
          );

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
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const AdaptivePlayerPage()),
        );
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

  /// Builds a mini video player bar for PiP-like functionality
  Widget _buildVideoMiniPlayer() {
    final playerState = ref.watch(playerProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';
    final item = playerState.currentItem;

    if (item == null) return const SizedBox.shrink();

    final duration = playerState.duration;
    final position = playerState.position;

    return GlassContainer(
      blur: AppTheme.blurMedium,
      opacity: 0.1,
      borderRadius: 0,
      showBorder: false,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surface,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: playerState.progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (duration.inMilliseconds * value).round(),
                );
                ref.read(playerProvider.notifier).seek(newPosition);
              },
            ),
          ),

          // Player content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                // Thumbnail
                GestureDetector(
                  onTap: () => _openFullPlayer(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: SizedBox(
                      width: 80,
                      height: 45,
                      child: Image.network(
                        item.getDisplayImageUrl(serverUrl, width: 200),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.movie,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Track info
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _openFullPlayer(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getVideoSubtitle(item),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Center controls
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 28,
                        color: playerState.hasPrevious
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        onPressed: playerState.hasPrevious
                            ? () => ref
                                  .read(playerProvider.notifier)
                                  .playPrevious()
                            : null,
                        tooltip: 'Previous',
                      ),

                      const SizedBox(width: 8),

                      // Play/Pause
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: AppTheme.shadowGlow(AppColors.primary),
                        ),
                        child: IconButton(
                          icon: Icon(
                            playerState.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          iconSize: 28,
                          color: Colors.white,
                          onPressed: () {
                            ref.read(playerProvider.notifier).playOrPause();
                          },
                          tooltip: playerState.isPlaying ? 'Pause' : 'Play',
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Next
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 28,
                        color: playerState.hasNext
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        onPressed: playerState.hasNext
                            ? () => ref.read(playerProvider.notifier).playNext()
                            : null,
                        tooltip: 'Next',
                      ),
                    ],
                  ),
                ),

                // Right side - time and actions
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Time
                      Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Expand to full player
                      IconButton(
                        icon: const Icon(Icons.open_in_full),
                        iconSize: 20,
                        color: AppColors.textSecondary,
                        onPressed: () => _openFullPlayer(),
                        tooltip: 'Open player',
                      ),

                      const SizedBox(width: 4),

                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        color: AppColors.textSecondary,
                        onPressed: () {
                          ref.read(playerProvider.notifier).stop();
                        },
                        tooltip: 'Close player',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getVideoSubtitle(MediaItem item) {
    final parts = <String>[];
    if (item.seriesName != null) {
      parts.add(item.seriesName!);
      if (item.parentIndexNumber != null && item.indexNumber != null) {
        parts.add('S${item.parentIndexNumber}E${item.indexNumber}');
      }
    } else if (item.productionYear != null) {
      parts.add(item.productionYear.toString());
    }
    return parts.join(' • ');
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _openFullPlayer() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AdaptivePlayerPage()));
  }
}
