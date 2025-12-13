import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'tv_library.dart';
import 'tv_detail.dart';
import 'tv_downloads.dart';
import 'tv_settings.dart';

class TvHome extends ConsumerStatefulWidget {
  const TvHome({super.key});

  @override
  ConsumerState<TvHome> createState() => _TvHomeState();
}

class _TvHomeState extends ConsumerState<TvHome> {
  final FocusNode _focusNode = FocusNode();
  int _selectedNavIndex = 0;
  int _selectedRowIndex = 0;
  int _selectedItemIndex = 0;

  final List<String> _navItems = ['Home', 'Movies', 'TV Shows', 'Downloads', 'Search', 'Settings'];

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _loadData() {
    ref.read(libraryProvider.notifier).loadLibraries();
    ref.read(libraryProvider.notifier).loadHomeData();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            // Background blur of featured item
            if (libraryState.featuredItem != null)
              _buildBackground(libraryState.featuredItem!, serverUrl),

            // Main content
            Row(
              children: [
                // Sidebar navigation
                _buildSidebar(),

                // Content area
                Expanded(
                  child: _buildContent(libraryState, serverUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(dynamic item, String serverUrl) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            item.getBackdropImageUrl(serverUrl, width: 1920),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Container(color: AppColors.background),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.background,
                  AppColors.background.withValues(alpha: 0.7),
                  AppColors.background.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.background,
            AppColors.background.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Text(
            'Finar',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),

          // Navigation items
          ..._navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            return _buildNavItem(index, label);
          }),

          const Spacer(),

          // User info
          Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(authProvider).user;
              return Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surface,
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user?.name ?? 'User',
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label) {
    final isSelected = _selectedNavIndex == index && _selectedRowIndex == -1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: isSelected
              ? null
              : Border.all(
                  color: Colors.transparent,
                  width: 2,
                ),
        ),
        child: Row(
          children: [
            Icon(
              _getNavIcon(index),
              size: 24,
              color: isSelected ? AppColors.black : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                color: isSelected ? AppColors.black : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNavIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_outlined;
      case 1:
        return Icons.movie_outlined;
      case 2:
        return Icons.tv_outlined;
      case 3:
        return Icons.download_outlined;
      case 4:
        return Icons.search_outlined;
      case 5:
        return Icons.settings_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _buildContent(LibraryState state, String serverUrl) {
    final rows = _buildRows(state, serverUrl);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 40),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: rows[index],
        );
      },
    );
  }

  List<Widget> _buildRows(LibraryState state, String serverUrl) {
    final rows = <Widget>[];
    int rowIndex = 0;

    // Featured hero
    if (state.featuredItem != null) {
      rows.add(_buildHeroRow(state.featuredItem!, serverUrl, rowIndex++));
    }

    // Continue watching
    if (state.continueWatching.isNotEmpty) {
      rows.add(_buildMediaRow(
        'Continue Watching',
        state.continueWatching,
        serverUrl,
        rowIndex++,
        showProgress: true,
      ));
    }

    // Next Up
    if (state.nextUp.isNotEmpty) {
      rows.add(_buildMediaRow(
        'Next Up',
        state.nextUp,
        serverUrl,
        rowIndex++,
      ));
    }

    // Recently Added
    if (state.recentlyAdded.isNotEmpty) {
      rows.add(_buildMediaRow(
        'Recently Added',
        state.recentlyAdded,
        serverUrl,
        rowIndex++,
      ));
    }

    // New Releases
    if (state.recentlyReleased.isNotEmpty) {
      rows.add(_buildMediaRow(
        'New Releases',
        state.recentlyReleased,
        serverUrl,
        rowIndex++,
      ));
    }

    // New Movies
    if (state.recentlyAddedMovies.isNotEmpty) {
      rows.add(_buildMediaRow(
        'New Movies',
        state.recentlyAddedMovies,
        serverUrl,
        rowIndex++,
      ));
    }

    // New TV Shows
    if (state.recentlyAddedShows.isNotEmpty) {
      rows.add(_buildMediaRow(
        'New TV Shows',
        state.recentlyAddedShows,
        serverUrl,
        rowIndex++,
      ));
    }

    // Recommended
    if (state.recommended.isNotEmpty) {
      rows.add(_buildMediaRow(
        'Recommended For You',
        state.recommended,
        serverUrl,
        rowIndex++,
      ));
    }

    // Top Rated
    if (state.topRated.isNotEmpty) {
      rows.add(_buildMediaRow(
        'Top Rated',
        state.topRated,
        serverUrl,
        rowIndex++,
      ));
    }

    // Favorites
    if (state.favorites.isNotEmpty) {
      rows.add(_buildMediaRow(
        'My Favorites',
        state.favorites,
        serverUrl,
        rowIndex++,
      ));
    }

    // Libraries (dynamically loaded items)
    for (final library in state.libraries) {
      if (state.libraryItems[library.id]?.isNotEmpty == true) {
        rows.add(_buildMediaRow(
          library.name,
          state.libraryItems[library.id]!,
          serverUrl,
          rowIndex++,
        ));
      }
    }

    return rows;
  }

  Widget _buildHeroRow(dynamic item, String serverUrl, int rowIndex) {
    final isRowSelected = _selectedRowIndex == rowIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: () => _navigateToDetail(item.id),
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg + 4),
            border: Border.all(
              color: isRowSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    item.getBackdropImageUrl(serverUrl, width: 1200),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.displaySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (item.productionYear != null)
                          Text(
                            item.productionYear.toString(),
                            style: AppTextStyles.bodyLarge,
                          ),
                        if (item.formattedRuntime != null) ...[
                          const SizedBox(width: 16),
                          Text(
                            item.formattedRuntime!,
                            style: AppTextStyles.bodyLarge,
                          ),
                        ],
                        if (item.communityRating != null) ...[
                          const SizedBox(width: 16),
                          const Icon(Icons.star, size: 18, color: AppColors.accentYellow),
                          const SizedBox(width: 4),
                          Text(
                            item.communityRating!.toStringAsFixed(1),
                            style: AppTextStyles.rating,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (item.overview != null)
                      Text(
                        item.overview!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        SizedBox(
                          width: 160,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _playItem(item),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GlassButton(
                          onPressed: () => _navigateToDetail(item.id),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 20),
                              SizedBox(width: 8),
                              Text('More Info'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildMediaRow(
    String title,
    List<dynamic> items,
    String serverUrl,
    int rowIndex, {
    bool showProgress = false,
  }) {
    final isRowSelected = _selectedRowIndex == rowIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 40, bottom: 16),
          child: Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: isRowSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: showProgress ? 180 : 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected =
                  isRowSelected && _selectedItemIndex == index;

              return _buildTvCard(
                item,
                serverUrl,
                isSelected,
                showProgress: showProgress,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTvCard(
    dynamic item,
    String serverUrl,
    bool isSelected, {
    bool showProgress = false,
  }) {
    final width = showProgress ? 250.0 : 150.0;
    final height = showProgress ? 140.0 : 220.0;

    return GestureDetector(
      onTap: () => _navigateToDetail(item.id),
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        width: width + 8,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd + 4),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
        ),
        transform: isSelected
            ? (Matrix4.identity()..scale(1.05))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Stack(
                children: [
                  Image.network(
                    showProgress
                        ? item.getBackdropImageUrl(serverUrl, width: 400)
                        : item.getPrimaryImageUrl(serverUrl, width: 250),
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: width,
                      height: height,
                      color: AppColors.surface,
                      child: const Icon(Icons.movie),
                    ),
                  ),
                  if (showProgress && item.progressPercent != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: item.progressPercent,
                        backgroundColor: AppColors.black.withValues(alpha: 0.5),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 4,
                      ),
                    ),
                ],
              ),
            ),

            // Title (for non-progress cards)
            if (!showProgress) ...[
              const SizedBox(height: 8),
              Text(
                item.name,
                style: AppTextStyles.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.productionYear != null)
                Text(
                  item.productionYear.toString(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final libraryState = ref.read(libraryProvider);
    final rows = _buildRowData(libraryState);
    final totalRows = rows.length;

    setState(() {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          if (_selectedRowIndex > 0) {
            _selectedRowIndex--;
            _selectedItemIndex = 0;
          } else if (_selectedRowIndex == 0) {
            _selectedRowIndex = -1; // Nav focus
          }
          break;

        case LogicalKeyboardKey.arrowDown:
          if (_selectedRowIndex == -1) {
            _selectedRowIndex = 0;
          } else if (_selectedRowIndex < totalRows - 1) {
            _selectedRowIndex++;
            _selectedItemIndex = 0;
          }
          break;

        case LogicalKeyboardKey.arrowLeft:
          if (_selectedRowIndex == -1) {
            // In nav
            if (_selectedNavIndex > 0) {
              _selectedNavIndex--;
            }
          } else {
            if (_selectedItemIndex > 0) {
              _selectedItemIndex--;
            }
          }
          break;

        case LogicalKeyboardKey.arrowRight:
          if (_selectedRowIndex == -1) {
            // In nav
            if (_selectedNavIndex < _navItems.length - 1) {
              _selectedNavIndex++;
            }
          } else {
            final rowItems = rows[_selectedRowIndex].length;
            if (_selectedItemIndex < rowItems - 1) {
              _selectedItemIndex++;
            }
          }
          break;

        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          _handleSelect(rows);
          break;

        case LogicalKeyboardKey.goBack:
        case LogicalKeyboardKey.escape:
          if (_selectedRowIndex >= 0) {
            _selectedRowIndex = -1;
          }
          break;
      }
    });
  }

  List<List<dynamic>> _buildRowData(LibraryState state) {
    final rows = <List<dynamic>>[];

    if (state.featuredItem != null) {
      rows.add([state.featuredItem]);
    }
    if (state.continueWatching.isNotEmpty) {
      rows.add(state.continueWatching);
    }
    if (state.recentlyAdded.isNotEmpty) {
      rows.add(state.recentlyAdded);
    }
    if (state.nextUp.isNotEmpty) {
      rows.add(state.nextUp);
    }
    for (final library in state.libraries) {
      if (state.libraryItems[library.id]?.isNotEmpty == true) {
        rows.add(state.libraryItems[library.id]!);
      }
    }

    return rows;
  }

  void _handleSelect(List<List<dynamic>> rows) {
    if (_selectedRowIndex == -1) {
      // Nav item selected
      _handleNavSelect(_selectedNavIndex);
    } else if (_selectedRowIndex < rows.length) {
      final item = rows[_selectedRowIndex][_selectedItemIndex];
      _navigateToDetail(item.id);
    }
  }

  void _handleNavSelect(int index) {
    switch (index) {
      case 0: // Home
        break;
      case 1: // Movies
        _navigateToLibrary('movies');
        break;
      case 2: // TV Shows
        _navigateToLibrary('tvshows');
        break;
      case 3: // Downloads
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TvDownloads(),
          ),
        );
        break;
      case 4: // Search
        // TODO: Navigate to search
        break;
      case 5: // Settings
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TvSettings(),
          ),
        );
        break;
    }
  }

  void _navigateToLibrary(String type) {
    final libraries = ref.read(libraryProvider).libraries;
    final library = libraries.firstWhere(
      (l) => l.collectionType == type,
      orElse: () => libraries.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TvLibrary(libraryId: library.id),
      ),
    );
  }

  void _navigateToDetail(String itemId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TvDetail(itemId: itemId),
      ),
    );
  }

  void _playItem(dynamic item) {
    ref.read(playerProvider.notifier).play(item);
    // Navigate to TV player
  }
}
