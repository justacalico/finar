import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/library.dart';
import '../../core/api/models/media_item.dart';
import '../../core/api/auth_service.dart';
import '../../core/api/models/user.dart';
import '../../core/api/media_service.dart';
import '../../core/services/download_service.dart';
import '../../core/services/controller_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'detail.dart';
import 'player.dart';
import 'settings.dart';
import 'whos_watching_page.dart';
import 'library.dart';
import 'music_library.dart';
import 'downloads.dart';

class HomePage extends ConsumerWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveLayout(
      desktopBuilder: () => const _HomeDesktop(),
      mobileBuilder: () => _HomeMobile(initialIndex: initialIndex),
    );
  }
}

class _HomeDesktop extends ConsumerStatefulWidget {
  const _HomeDesktop();

  @override
  ConsumerState<_HomeDesktop> createState() => _HomeDesktopState();
}

class _HomeDesktopState extends ConsumerState<_HomeDesktop> {
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
        MaterialPageRoute(builder: (_) => const DownloadsPage()),
      );
    } else if (index == 100) {
      // Settings
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
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
                        loading: () => Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
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
          const Expanded(child: DownloadsPage()),

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
                        gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                        ],
                      ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                              builder: (_) => const DownloadsPage(),
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
                            builder: (_) => const SettingsPage(),
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
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                  : isFocused
                  ? AppColors.glassActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isFocused
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                      ? Theme.of(context).colorScheme.primary
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
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                  : isFocused
                  ? AppColors.glassActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isFocused
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      width: 2,
                    )
                  : isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                      ? Theme.of(context).colorScheme.primary
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
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                onPressed: () async {
                  final message = await Navigator.of(context).push<String?>(
                    MaterialPageRoute<String?>(
                      builder: (_) => const WhosWatchingPage(),
                    ),
                  );
                  if (message != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                },
                tooltip: 'Switch profile',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  backgroundColor: AppColors.glassWhite,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 20),
                onPressed: () => _showSignOutDialog(),
                tooltip: 'Sign out',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  backgroundColor: AppColors.glassWhite,
                ),
              ),
            ],
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
        gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                        ],
                      ),
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
        return MusicLibraryPage(libraryId: _selectedLibraryId!);
      }
      return LibraryPage(libraryId: _selectedLibraryId!);
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

  /// For albums use album art (primary image); for other types use backdrop.
  String _heroImageUrl(MediaItem item, String serverUrl) {
    if (item.type == MediaType.album) {
      return item.getPrimaryImageUrl(serverUrl, width: 1920);
    }
    return item.getBackdropUrl(serverUrl, width: 1920);
  }

  Widget _buildHomeContent(HomeData data) {
    return CustomScrollView(
      slivers: [
        // Hero section
        SliverToBoxAdapter(
          child: data.recentlyAdded.isNotEmpty
              ? HeroCard(
                  imageUrl: _heroImageUrl(
                    data.recentlyAdded.first,
                    ref.read(jellyfinApiProvider).serverUrl ?? '',
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

        // Watchlist
        if (data.watchlist.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildMediaRow(title: 'Watchlist', items: data.watchlist),
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
                    foregroundColor: Theme.of(context).colorScheme.primary,
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
                          color: Theme.of(context).colorScheme.primary,
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
                    isWatched: item.isPlayed == true,
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
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
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
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    ),
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
                    color: Theme.of(context).colorScheme.primary,
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
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
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
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
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
                color: Theme.of(context).colorScheme.primary,
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
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length} items',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
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
              Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary, size: 28),
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
              loading: () => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
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
        builder: (context) => DetailPage(itemId: item.id),
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
          MaterialPageRoute(builder: (context) => const PlayerPage()),
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
            MaterialPageRoute(builder: (context) => const PlayerPage()),
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
                  builder: (context) => const PlayerPage(),
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

  void _showSignOutDialog() {
    final profiles = ref.read(savedProfilesProvider);
    final user = ref.read(currentUserProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl;
    if (user == null || serverUrl == null) return;
    SavedProfile? currentProfile;
    for (final p in profiles) {
      if (p.userId == user.id && p.serverUrl == serverUrl) {
        currentProfile = p;
        break;
      }
    }
    if (currentProfile == null) {
      ref.read(authProvider.notifier).logout();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text(
          'Sign out and remove this profile from this device? You can add it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).removeProfile(currentProfile!);
            },
            child: const Text('Sign out'),
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
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: AppColors.surface,
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
                          color: Theme.of(context).colorScheme.primary,
                          boxShadow: AppTheme.shadowGlow(Theme.of(context).colorScheme.primary),
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
    ).push(MaterialPageRoute(builder: (context) => const PlayerPage()));
  }
}

/// Helper to get MediaType from string
MediaType _getMediaTypeFromString(String? typeString) {
  switch (typeString?.toLowerCase()) {
    case 'movie':
      return MediaType.movie;
    case 'episode':
      return MediaType.episode;
    case 'series':
      return MediaType.series;
    case 'audio':
      return MediaType.audio;
    case 'musicvideo':
      return MediaType.musicVideo;
    case 'album':
      return MediaType.album;
    default:
      return MediaType.movie;
  }
}

class _HomeMobile extends ConsumerStatefulWidget {
  final int initialIndex;

  const _HomeMobile({this.initialIndex = 0});

  @override
  ConsumerState<_HomeMobile> createState() => _HomeMobileState();
}

class _HomeMobileState extends ConsumerState<_HomeMobile>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
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

  @override
  void initState() {
    super.initState();
    final maxIndex = kIsWeb ? 2 : 3;
    _currentIndex = widget.initialIndex.clamp(0, maxIndex);
    _pageController = PageController(initialPage: _currentIndex);
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
    final isMusic =
        playerState.currentItem?.type.name == 'audio' ||
        playerState.currentItem?.type.name == 'album';

    // If offline and not on downloads page, force navigation to downloads
    if (!isOnline && _currentIndex != 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentIndex = 3);
          _pageController.jumpToPage(3);
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
              if (!isOnline && index != 3) {
                _pageController.jumpToPage(3);
                return;
              }
              setState(() => _currentIndex = index);
            },
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildHomePage(),
              _buildSearchPage(),
              _buildLibraryPage(),
              if (!kIsWeb) _buildDownloadsPage(),
            ],
          ),

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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomPadding > 0 ? bottomPadding : 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              // Refined glass effect
              color: AppColors.backgroundSecondary.withValues(alpha: 0.85),
              border: Border.all(
                width: 1,
                color: AppColors.divider.withValues(alpha: 0.3),
              ),
              boxShadow: [
                // Soft ambient shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Animated pill indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: _getIndicatorPosition(context),
                  top: 4,
                  child: Container(
                    width: 52,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.2,
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Navigation items
                Row(
                  children: [
                    _buildNavItem(
                      0,
                      Icons.home_outlined,
                      Icons.home_rounded,
                      'Home',
                      isOnline: isOnline,
                    ),
                    _buildNavItem(
                      1,
                      Icons.search_outlined,
                      Icons.search_rounded,
                      'Search',
                      isOnline: isOnline,
                    ),
                    _buildNavItem(
                      2,
                      Icons.video_library_outlined,
                      Icons.video_library_rounded,
                      'Library',
                      isOnline: isOnline,
                    ),
                    if (!kIsWeb)
                      _buildNavItem(
                        3,
                        Icons.download_outlined,
                        Icons.download_rounded,
                        'Downloads',
                        isOnline: isOnline,
                      ),
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
    final screenWidth =
        MediaQuery.of(context).size.width - 32; // Account for margin
    final navItemCount = kIsWeb ? 3 : 4;
    final itemWidth = screenWidth / navItemCount;
    return (itemWidth * _currentIndex) + (itemWidth / 2) - 26;
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label, {
    bool isOnline = true,
  }) {
    final isSelected = _currentIndex == index;
    // Disable non-downloads items when offline
    final isDisabled = !isOnline && index != 3;

    return Expanded(
      child: GestureDetector(
        onTap: isDisabled
            ? null
            : () {
                setState(() => _currentIndex = index);
                _pageController.jumpToPage(index);
              },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                transform: Matrix4.diagonal3Values(
                  isSelected ? 1.05 : 1.0,
                  isSelected ? 1.05 : 1.0,
                  1.0,
                ),
                transformAlignment: Alignment.center,
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: 24,
                  color: isDisabled
                      ? AppColors.textDisabled
                      : isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isDisabled
                      ? AppColors.textDisabled
                      : isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
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
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
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
                        borderRadius: BorderRadius.circular(_scale(context, 16)),
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
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(_scale(context, 8)),
                            ),
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: AppColors.textOnPrimary,
                              size: _scale(context, 18),
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
                        borderRadius: BorderRadius.circular(_scale(context, 12)),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.settings_outlined, size: _scale(context, 22)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                        color: AppColors.textSecondary,
                      ),
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

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
                          onPressed: item is MediaItem ? () => _addToWatchlist(item) : null,
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
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => library.collectionType?.toLowerCase() == 'music'
                  ? MusicLibraryPage(libraryId: library.id)
                  : LibraryPage(libraryId: library.id),
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
    return const _MobileSearchPage();
  }

  Widget _buildLibraryPage() {
    return const _MobileLibraryBrowser();
  }

  Widget _buildDownloadsPage() {
    return const _MobileDownloadsPage();
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
            _MobileSeeAllPage(title: title, items: items, serverUrl: serverUrl),
      ),
    );
  }

  void _goToLibraryTab() {
    setState(() => _currentIndex = 2);
    _pageController.jumpToPage(2);
  }

  void _navigateToDetail(String itemId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPage(itemId: itemId)),
    );
  }

  Future<void> _addToWatchlist(MediaItem item) async {
    try {
      final isNowInWatchlist =
          await ref.read(mediaActionsProvider).toggleWatchlist(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowInWatchlist ? 'Added to Watchlist' : 'Removed from Watchlist',
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
        : _getMediaTypeFromString(item.type?.toString());

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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlayerPage()),
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
}

class _MobileSeeAllPage extends StatelessWidget {
  final String title;
  final List<MediaItem> items;
  final String serverUrl;

  const _MobileSeeAllPage({
    required this.title,
    required this.items,
    required this.serverUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.62,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return AnimatedCard(
            imageUrl: item.getDisplayImageUrl(serverUrl, width: 240),
            title: item.name,
            subtitle: item.productionYear?.toString(),
            isWatched: item.isPlayed == true,
            animationIndex: index,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(itemId: item.id),
                ),
              );
            },
          );
        },
      ),
    );
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
                        imageUrl: item.getDisplayImageUrl(
                          serverUrl,
                          width: 200,
                        ),
                        title: item.name,
                        subtitle: item.productionYear?.toString(),
                        isWatched: item.isPlayed == true,
                        animationIndex: index,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailPage(itemId: item.id),
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

class _LibraryListCard extends StatelessWidget {
  final Library library;
  final Color accentColor;
  final IconData icon;
  final String typeLabel;
  final VoidCallback onTap;

  const _LibraryListCard({
    required this.library,
    required this.accentColor,
    required this.icon,
    required this.typeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final count = library.childCount;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      library.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count != null
                          ? '$typeLabel · $count items'
                          : typeLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileLibraryBrowser extends ConsumerWidget {
  const _MobileLibraryBrowser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final libraries = libraryState.libraries;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Library',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your collections',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (libraryState.isLoading && libraries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              ),
            )
          else if (libraryState.error != null && libraries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Couldn\'t load libraries',
                        style: AppTextStyles.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        libraryState.error!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final library = libraries[index];
                    final accentColor = _getLibraryAccentColor(
                      library.collectionType,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LibraryListCard(
                        library: library,
                        accentColor: accentColor,
                        icon: _getLibraryIcon(library.collectionType),
                        typeLabel: _getLibraryTypeLabel(library.collectionType),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                library.collectionType?.toLowerCase() == 'music'
                                    ? MusicLibraryPage(
                                        libraryId: library.id,
                                      )
                                    : LibraryPage(
                                        libraryId: library.id,
                                      ),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: index * 50))
                        .slideX(begin: 0.03, end: 0, curve: Curves.easeOutCubic);
                  },
                  childCount: libraries.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getLibraryAccentColor(String? collectionType) {
    switch (collectionType) {
      case 'movies':
        return const Color(0xFFE53935);
      case 'tvshows':
        return const Color(0xFF1E88E5);
      case 'music':
        return const Color(0xFF43A047);
      case 'photos':
        return const Color(0xFFFF9800);
      default:
        return AppColors.secondary;
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
                Text('Downloads', style: AppTextStyles.headlineMedium),
                const Spacer(),
                if (downloadState.activeDownloads.isNotEmpty)
                  Text(
                    '${downloadState.activeDownloads.length} active',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.primary,
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
                  onPause: () => ref
                      .read(downloadProvider.notifier)
                      .pauseDownload(download.id),
                  onResume: () => ref
                      .read(downloadProvider.notifier)
                      .resumeDownload(download.id),
                  onCancel: () => ref
                      .read(downloadProvider.notifier)
                      .cancelDownload(download.id),
                  onRemove: () => ref
                      .read(downloadProvider.notifier)
                      .deleteDownload(download.id),
                  onTap: () async {
                    if (download.status == DownloadStatus.completed &&
                        download.localPath != null) {
                      // Play directly from local file using playLocalFile
                      // This avoids server lookups which fail for items from other servers
                      final playerNotifier = ref.read(playerProvider.notifier);

                      // Create a minimal MediaItem for the player
                      final item = MediaItem(
                        id: download.itemId,
                        name: download.itemName,
                        type: _getMediaTypeFromString(download.itemType),
                      );

                      try {
                        await playerNotifier.playLocalFile(
                          item,
                          download.localPath!,
                        );

                        // Navigate to player
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlayerPage(),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to play: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
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
            // Thumbnail - prefer local image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: _buildThumbnailImage(),
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
                  _buildStatusRow(context),
                  if (download.status == DownloadStatus.downloading ||
                      download.status == DownloadStatus.paused) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: download.progress,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        download.status == DownloadStatus.paused
                            ? AppColors.warning
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Actions
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
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
        color = Theme.of(context).colorScheme.primary;
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

  Widget _buildThumbnailImage() {
    // Check for local primary image first
    final localPrimaryPath = download.localPrimaryImagePath;
    if (localPrimaryPath != null && localPrimaryPath.isNotEmpty) {
      final localFile = File(localPrimaryPath);
      if (localFile.existsSync()) {
        return SizedBox(
          width: 56,
          height: 80,
          child: Image.file(
            localFile,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildNetworkImage(),
          ),
        );
      }
    }
    return _buildNetworkImage();
  }

  Widget _buildNetworkImage() {
    if (download.primaryImageTag != null) {
      return CachedNetworkImage(
        imageUrl:
            '$serverUrl/Items/${download.itemId}/Images/Primary?fillHeight=120&fillWidth=80&tag=${download.primaryImageTag}',
        width: 56,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (_, _) => _buildPlaceholder(),
        errorWidget: (_, _, _) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56,
      height: 80,
      color: AppColors.surfaceElevated,
      child: const Icon(Icons.movie_outlined, color: AppColors.textTertiary),
    );
  }

  Widget _buildActionButton(BuildContext context) {
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
              icon: Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary),
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
              icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
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
