import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import '../adaptive_pages.dart';

class DesktopLibrary extends ConsumerStatefulWidget {
  final String libraryId;

  const DesktopLibrary({super.key, required this.libraryId});

  @override
  ConsumerState<DesktopLibrary> createState() => _DesktopLibraryState();
}

class _DesktopLibraryState extends ConsumerState<DesktopLibrary> {
  final ScrollController _scrollController = ScrollController();
  String _sortBy = 'SortName';
  String _sortOrder = 'Ascending';
  ViewMode _viewMode = ViewMode.grid;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      ref.read(libraryContentProvider(widget.libraryId).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryContent = ref.watch(libraryContentProvider(widget.libraryId));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Column(
      children: [
        // Header
        _buildHeader(libraryContent),

        // Content
        Expanded(
          child: libraryContent.items.isEmpty && libraryContent.isLoading
              ? _buildLoadingGrid()
              : libraryContent.error != null
              ? _buildError(libraryContent.error!)
              : _viewMode == ViewMode.grid
              ? _buildGrid(libraryContent, serverUrl)
              : _buildList(libraryContent, serverUrl),
        ),
      ],
    );
  }

  Widget _buildHeader(LibraryContentState state) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      borderRadius: 0,
      showBorder: false,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Title and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Library', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  '${state.totalCount} items',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Search field
          SizedBox(
            width: 300,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search in library...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                ref
                    .read(libraryContentProvider(widget.libraryId).notifier)
                    .setSearch(value);
              },
            ),
          ),

          const SizedBox(width: 16),

          // Sort dropdown
          _buildSortDropdown(),

          const SizedBox(width: 16),

          // View mode toggle
          _buildViewModeToggle(),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return PopupMenuButton<String>(
      initialValue: _sortBy,
      onSelected: (value) {
        setState(() => _sortBy = value);
        ref
            .read(libraryContentProvider(widget.libraryId).notifier)
            .setSorting(_sortBy, _sortOrder);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'SortName', child: Text('Name')),
        const PopupMenuItem(value: 'DateCreated', child: Text('Date Added')),
        const PopupMenuItem(value: 'PremiereDate', child: Text('Release Date')),
        const PopupMenuItem(value: 'CommunityRating', child: Text('Rating')),
        const PopupMenuItem(value: 'Random', child: Text('Random')),
      ],
      child: GlassButton(
        onPressed: null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 18),
            const SizedBox(width: 8),
            Text(_getSortLabel(_sortBy)),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                _sortOrder == 'Ascending'
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 16,
              ),
              onPressed: () {
                setState(() {
                  _sortOrder = _sortOrder == 'Ascending'
                      ? 'Descending'
                      : 'Ascending';
                });
                ref
                    .read(libraryContentProvider(widget.libraryId).notifier)
                    .setSorting(_sortBy, _sortOrder);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'SortName':
        return 'Name';
      case 'DateCreated':
        return 'Date Added';
      case 'PremiereDate':
        return 'Release Date';
      case 'CommunityRating':
        return 'Rating';
      case 'Random':
        return 'Random';
      default:
        return sortBy;
    }
  }

  Widget _buildViewModeToggle() {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.1,
      borderRadius: AppTheme.radiusMd,
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewModeButton(ViewMode.grid, Icons.grid_view),
          _buildViewModeButton(ViewMode.list, Icons.view_list),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(ViewMode mode, IconData icon) {
    final isSelected = _viewMode == mode;

    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? AppColors.black : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildGrid(LibraryContentState state, String serverUrl) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 2 / 3.3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final item = state.items[index];
        return AnimatedCard(
          imageUrl: item.getDisplayImageUrl(serverUrl, width: 300),
          title: item.name,
          subtitle: item.productionYear?.toString(),
          animationIndex: index % 20,
          onTap: () => _navigateToDetail(item.id),
        );
      },
    );
  }

  Widget _buildList(LibraryContentState state, String serverUrl) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(32),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final item = state.items[index];
        return _buildListItem(item, serverUrl, index);
      },
    );
  }

  Widget _buildListItem(dynamic item, String serverUrl, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () => _navigateToDetail(item.id),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Image.network(
                item.getDisplayImageUrl(serverUrl, width: 150),
                width: 80,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 80,
                  height: 120,
                  color: AppColors.surface,
                  child: const Icon(Icons.movie_outlined),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (item.productionYear != null)
                        item.productionYear.toString(),
                      if (item.formattedRuntime != null) item.formattedRuntime,
                    ].join(' • '),
                    style: AppTextStyles.bodySmall,
                  ),
                  if (item.overview != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.overview!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.communityRating != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.accentYellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.communityRating.toStringAsFixed(1),
                          style: AppTextStyles.rating,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Play button
            GlassIconButton(
              icon: Icons.play_arrow,
              size: 44,
              backgroundColor: AppColors.primary,
              iconColor: AppColors.black,
              onPressed: () => _playItem(item),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: (index % 10) * 30),
      duration: AppTheme.durationNormal,
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 2 / 3.3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return const ShimmerLoading(borderRadius: AppTheme.radiusMd);
      },
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to load library', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(libraryContentProvider(widget.libraryId).notifier)
                  .refresh();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(String itemId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdaptiveDetailPage(itemId: itemId),
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
}

enum ViewMode { grid, list }
