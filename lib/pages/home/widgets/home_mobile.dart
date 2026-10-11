import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finar/core/utils/media_actions.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import '../../detail.dart';
import '../../downloads.dart';
import '../../settings/widgets/settings_mobile.dart';
import '../../library/library_page.dart';
import 'home_favorites_view.dart';
import 'home_library_browser.dart';
import 'home_mobile_home_page.dart';
import 'home_search_page.dart';
import 'home_see_all_page.dart';

class HomeMobile extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeMobile({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeMobile> createState() => HomeMobileState();
}

class HomeMobileState extends ConsumerState<HomeMobile> {
  late final PageController _pageController;
  bool _isPlayerExpanded = false;

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

  @override
  void dispose() {
    _pageController.dispose();
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
          ref.read(shellNavProvider.notifier).goTo(ShellSection.downloads);
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
              MobileHomePage(
                onSeeAll: _openSeeAllMedia,
                onLibraryTab: _goToLibraryTab,
                onSettingsTab: _goToSettingsTab,
                onItemTap: _navigateToDetail,
                onPlayItem: (item) => playHomeItem(ref, context, item),
                onAddToWatchlist: _addToWatchlist,
              ),
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

  Widget _buildSearchPage() {
    return const MobileSearchPage();
  }

  Widget _buildLibraryPage() {
    final nav = ref.watch(shellNavProvider);
    final libraryId = nav.libraryId;
    if (libraryId != null) {
      return LibraryPage(
        libraryId: libraryId,
        onBack: () => ref.read(shellNavProvider.notifier).closeLibrary(),
      );
    }
    return LibraryBrowser(
      onLibraryTap: (id) => ref.read(shellNavProvider.notifier).openLibrary(id),
    );
  }

  Widget _buildDownloadsPage() {
    return const DownloadsPage();
  }

  Widget _buildSettingsPage() {
    return const SettingsMobile();
  }

  void _openSeeAllMedia(String title, List<MediaItem> items) {
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
}
