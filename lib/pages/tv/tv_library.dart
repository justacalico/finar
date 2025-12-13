import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'tv_detail.dart';

class TvLibrary extends ConsumerStatefulWidget {
  final String libraryId;

  const TvLibrary({
    super.key,
    required this.libraryId,
  });

  @override
  ConsumerState<TvLibrary> createState() => _TvLibraryState();
}

class _TvLibraryState extends ConsumerState<TvLibrary> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;
  final int _columns = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryContent = ref.watch(libraryContentProvider(widget.libraryId));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) => _handleKeyEvent(event, libraryContent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(libraryContent),

            // Grid
            Expanded(
              child: libraryContent.items.isEmpty && libraryContent.isLoading
                  ? _buildLoadingGrid()
                  : _buildGrid(libraryContent, serverUrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LibraryContentState state) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          // Back button
          GlassIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 24),
          
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Library',
                style: AppTextStyles.headlineMedium,
              ),
              Text(
                '${state.totalCount} items',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Sort indicator
          GlassContainer(
            blur: AppTheme.blurLight,
            opacity: 0.1,
            borderRadius: AppTheme.radiusMd,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.sort, size: 20),
                const SizedBox(width: 8),
                const Text('Name'),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_upward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(LibraryContentState state, String serverUrl) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        childAspectRatio: 2 / 3.3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        final isSelected = _selectedIndex == index;

        return _buildGridItem(item, serverUrl, isSelected, index);
      },
    );
  }

  Widget _buildGridItem(
    dynamic item,
    String serverUrl,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _navigateToDetail(item.id),
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
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
            // Poster
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Image.network(
                  item.getPrimaryImageUrl(serverUrl, width: 250),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, ___) => Container(
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(Icons.movie_outlined, size: 32),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              item.name,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Year
            if (item.productionYear != null)
              Text(
                item.productionYear.toString(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        childAspectRatio: 2 / 3.3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 21,
      itemBuilder: (context, index) {
        return const ShimmerLoading(
          borderRadius: AppTheme.radiusMd,
        );
      },
    );
  }

  void _handleKeyEvent(KeyEvent event, LibraryContentState state) {
    if (event is! KeyDownEvent) return;

    final itemCount = state.items.length;
    if (itemCount == 0) return;

    setState(() {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          if (_selectedIndex >= _columns) {
            _selectedIndex -= _columns;
            _ensureVisible();
          }
          break;

        case LogicalKeyboardKey.arrowDown:
          if (_selectedIndex + _columns < itemCount) {
            _selectedIndex += _columns;
            _ensureVisible();
          }
          // Load more when near end
          if (_selectedIndex > itemCount - _columns * 2) {
            ref
                .read(libraryContentProvider(widget.libraryId).notifier)
                .loadMore();
          }
          break;

        case LogicalKeyboardKey.arrowLeft:
          if (_selectedIndex % _columns > 0) {
            _selectedIndex--;
          }
          break;

        case LogicalKeyboardKey.arrowRight:
          if (_selectedIndex % _columns < _columns - 1 &&
              _selectedIndex < itemCount - 1) {
            _selectedIndex++;
          }
          break;

        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          if (_selectedIndex < itemCount) {
            final item = state.items[_selectedIndex];
            _navigateToDetail(item.id);
          }
          break;

        case LogicalKeyboardKey.goBack:
        case LogicalKeyboardKey.escape:
          Navigator.pop(context);
          break;
      }
    });
  }

  void _ensureVisible() {
    final row = _selectedIndex ~/ _columns;
    final itemHeight = 280.0; // Approximate item height
    final targetOffset = row * itemHeight;

    _scrollController.animateTo(
      targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: AppTheme.durationNormal,
      curve: Curves.easeOut,
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
}
