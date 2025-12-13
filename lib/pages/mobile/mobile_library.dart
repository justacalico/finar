import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'mobile_detail.dart';

class MobileLibrary extends ConsumerStatefulWidget {
  final String libraryId;

  const MobileLibrary({
    super.key,
    required this.libraryId,
  });

  @override
  ConsumerState<MobileLibrary> createState() => _MobileLibraryState();
}

class _MobileLibraryState extends ConsumerState<MobileLibrary> {
  final ScrollController _scrollController = ScrollController();
  String _sortBy = 'SortName';
  String _sortOrder = 'Ascending';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
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

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text('Library', style: AppTextStyles.headlineMedium),
            backgroundColor: Colors.transparent,
            flexibleSpace: BlurBackdrop(
              blur: AppTheme.blurLight,
              child: const SizedBox.expand(),
            ),
            actions: [
              // Sort button
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: _showSortOptions,
              ),
              // View mode toggle
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
            ],
          ),
        ],
        body: libraryContent.items.isEmpty && libraryContent.isLoading
            ? _buildLoadingGrid()
            : libraryContent.error != null
                ? _buildError(libraryContent.error!)
                : _isGridView
                    ? _buildGrid(libraryContent, serverUrl)
                    : _buildList(libraryContent, serverUrl),
      ),
    );
  }

  Widget _buildGrid(LibraryContentState state, String serverUrl) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(libraryContentProvider(widget.libraryId).notifier)
            .refresh();
      },
      color: AppColors.primary,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2 / 3.3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final item = state.items[index];
          return AnimatedCard(
            imageUrl: item.getPrimaryImageUrl(serverUrl, width: 200),
            title: item.name,
            subtitle: item.productionYear?.toString(),
            animationIndex: index % 15,
            onTap: () => _navigateToDetail(item.id),
          );
        },
      ),
    );
  }

  Widget _buildList(LibraryContentState state, String serverUrl) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(libraryContentProvider(widget.libraryId).notifier)
            .refresh();
      },
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
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
      ),
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
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Image.network(
                item.getPrimaryImageUrl(serverUrl, width: 100),
                width: 60,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 90,
                  color: AppColors.surface,
                  child: const Icon(Icons.movie_outlined, size: 24),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (item.productionYear != null)
                        item.productionYear.toString(),
                      if (item.formattedRuntime != null) item.formattedRuntime,
                    ].join(' • '),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (item.communityRating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.accentYellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.communityRating.toStringAsFixed(1),
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Play button
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () => _playItem(item),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: (index % 10) * 30))
        .slideX(begin: 0.05);
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2 / 3.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return const ShimmerLoading(
          borderRadius: AppTheme.radiusMd,
        );
      },
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load',
              style: AppTextStyles.titleMedium,
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
              onPressed: () {
                ref
                    .read(libraryContentProvider(widget.libraryId).notifier)
                    .refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        blur: AppTheme.blurHeavy,
        opacity: 0.1,
        borderRadius: AppTheme.radiusXl,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Sort By', style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            _buildSortOption('Name', 'SortName'),
            _buildSortOption('Date Added', 'DateCreated'),
            _buildSortOption('Release Date', 'PremiereDate'),
            _buildSortOption('Rating', 'CommunityRating'),
            _buildSortOption('Random', 'Random'),
            const SizedBox(height: 24),
            Text('Order', style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateSort(_sortBy, 'Ascending'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _sortOrder == 'Ascending'
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: _sortOrder == 'Ascending'
                                ? AppColors.black
                                : AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ascending',
                            style: TextStyle(
                              color: _sortOrder == 'Ascending'
                                  ? AppColors.black
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateSort(_sortBy, 'Descending'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _sortOrder == 'Descending'
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: _sortOrder == 'Descending'
                                ? AppColors.black
                                : AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Descending',
                            style: TextStyle(
                              color: _sortOrder == 'Descending'
                                  ? AppColors.black
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        _updateSort(value, _sortOrder);
        Navigator.pop(context);
      },
    );
  }

  void _updateSort(String sortBy, String sortOrder) {
    setState(() {
      _sortBy = sortBy;
      _sortOrder = sortOrder;
    });
    ref
        .read(libraryContentProvider(widget.libraryId).notifier)
        .setSorting(sortBy, sortOrder);
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
