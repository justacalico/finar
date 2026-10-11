import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/api/models/library.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/api/auth_service.dart';
import 'package:finar/core/api/media_service.dart';
import 'package:finar/core/services/controller_service.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import '../../detail.dart';
import 'package:finar/core/utils/media_actions.dart';
import '../../settings/widgets/settings_desktop.dart';
import '../../library/library_page.dart';
import '../../downloads.dart';
import 'home_content_view.dart';
import 'home_favorites_view.dart';
import 'home_library_browser.dart';
import 'home_media_grid.dart';
import 'home_search_view.dart';
import 'home_sidebar.dart';
import 'home_video_mini_player.dart';

class HomeDesktop extends ConsumerStatefulWidget {
  const HomeDesktop({super.key});

  @override
  ConsumerState<HomeDesktop> createState() => HomeDesktopState();
}

class HomeDesktopState extends ConsumerState<HomeDesktop> {
  // Navigation state lives in shellNavProvider so switching between the
  // desktop and mobile layouts keeps the user on the same section.
  ShellNavState get _nav => ref.read(shellNavProvider);

  String? get _selectedLibraryId => _nav.libraryId;

  int get _selectedIndex => switch (_nav.section) {
    ShellSection.home => 0,
    ShellSection.search => 1,
    ShellSection.favorites => 2,
    ShellSection.downloads => 3,
    ShellSection.library => -1,
    ShellSection.settings => 100,
  };

  void _selectSection(ShellSection section) {
    ref.read(shellNavProvider.notifier).goTo(section);
    setState(() {
      // Clear expanded category when navigating
      _expandedCategory = null;
      _expandedCategoryItems = null;
    });
  }

  // Expanded category for "See All" functionality
  String? _expandedCategory;
  List<MediaItem>? _expandedCategoryItems;

  // Focus management for controller navigation
  final FocusNode _mainFocusNode = FocusNode();
  bool _sidebarFocused = false;
  int _focusedNavIndex = 0;

  // Sidebar collapse state (user toggle; auto-collapse also applies on narrow widths)
  bool _sidebarCollapsed = false;
  bool _sidebarUserToggled = false;

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
      if (_nav.libraryId != null) {
        ref.read(shellNavProvider.notifier).closeLibrary();
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
    final libraries =
        ref
            .read(librariesProvider)
            .when(
              data: (d) => d,
              loading: () => null,
              error: (_, stackTrace) => null,
            ) ??
        [];
    final int maxLibraryIndex =
        4 + libraries.length - 1; // Last library item index
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
    final notifier = ref.read(shellNavProvider.notifier);
    if (index >= 4 && index < 4 + libraries.length) {
      notifier.openLibrary(libraries[index - 4].id);
    } else {
      notifier.goTo(shellSectionForIndex(index));
    }
    setState(() {
      _sidebarFocused = false;
      _expandedCategory = null;
      _expandedCategoryItems = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeData = ref.watch(homeDataProvider);
    final libraries = ref.watch(librariesProvider);
    final showMiniPlayer = ref.watch(showMiniPlayerProvider);
    final playerState = ref.watch(playerProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final nav = ref.watch(shellNavProvider);
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
                  HomeSidebar(
                    libraries: libraries,
                    selectedIndex: _selectedIndex,
                    selectedLibraryId: _selectedLibraryId,
                    focused: _sidebarFocused,
                    focusedNavIndex: _focusedNavIndex,
                    userToggled: _sidebarUserToggled,
                    userCollapsed: _sidebarCollapsed,
                    onSelectSection: _selectSection,
                    onCollapsedChanged: (collapsed) => setState(() {
                      _sidebarUserToggled = true;
                      _sidebarCollapsed = collapsed;
                    }),
                    onSignOut: _showSignOutDialog,
                  ),

                  // Main content with FocusTraversalGroup
                  Expanded(
                    child: FocusTraversalGroup(
                      policy: OrderedTraversalPolicy(),
                      // Home is the only view that actually needs homeData.
                      // All other sections (search, favorites, downloads,
                      // settings, libraries) load their own state.
                      child:
                          nav.section != ShellSection.home ||
                              nav.libraryId != null
                          ? _buildContent(null)
                          : homeData.when(
                              data: (data) => _buildContent(data),
                              loading: () => Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              error: (error, stack) =>
                                  _buildError(error.toString()),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Music player bar at bottom
            if (showMiniPlayer && isMusic) const DesktopMusicPlayerBar(),

            // Video mini player bar (PiP mode)
            if (showMiniPlayer && isVideo) const HomeVideoMiniPlayer(),
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
          if (showMiniPlayer && isVideo) const HomeVideoMiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildContent(HomeData? data) {
    final nav = ref.read(shellNavProvider);
    final libraryId = nav.libraryId;
    if (libraryId != null) {
      return LibraryPage(libraryId: libraryId);
    }

    switch (nav.section) {
      case ShellSection.search:
        return DesktopSearchView(
          expandedCategory: _expandedCategory,
          expandedItems: _expandedCategoryItems,
          onShowAll: _showExpandedCategory,
          onClose: _closeExpandedCategory,
          onItemTap: _navigateToDetail,
        );
      case ShellSection.favorites:
        return DesktopFavoritesView(
          expandedCategory: _expandedCategory,
          expandedItems: _expandedCategoryItems,
          onShowAll: _showExpandedCategory,
          onClose: _closeExpandedCategory,
          onItemTap: _navigateToDetail,
        );
      case ShellSection.downloads:
        return const DownloadsPage();
      case ShellSection.settings:
        return const SettingsDesktop(embedded: true);
      case ShellSection.library:
        return LibraryBrowser(
          onLibraryTap: (id) =>
              ref.read(shellNavProvider.notifier).openLibrary(id),
        );
      case ShellSection.home:
        if (_expandedCategory != null && _expandedCategoryItems != null) {
          return ExpandedCategoryGrid(
            category: _expandedCategory!,
            items: _expandedCategoryItems!,
            serverUrl: ref.read(jellyfinApiProvider).serverUrl ?? '',
            onBack: _closeExpandedCategory,
            onItemTap: _navigateToDetail,
          );
        }
        if (data == null) return const SizedBox.shrink();
        return HomeContentView(
          data: data,
          onShowAll: _showExpandedCategory,
          onItemTap: _navigateToDetail,
          onPlayItem: (item) => playHomeItem(ref, context, item),
        );
    }
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

  void _navigateToDetail(MediaItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DetailPage(itemId: item.id)),
    );
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
              await ref
                  .read(authProvider.notifier)
                  .removeProfile(currentProfile!);
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
