import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'home_media_grid.dart';
import 'home_widgets.dart';

class DesktopSearchView extends ConsumerWidget {
  final String? expandedCategory;
  final List<MediaItem>? expandedItems;
  final void Function(String category, List<MediaItem> items) onShowAll;
  final VoidCallback onClose;
  final void Function(MediaItem item) onItemTap;

  const DesktopSearchView({
    super.key,
    required this.expandedCategory,
    required this.expandedItems,
    required this.onShowAll,
    required this.onClose,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';
    final isLoading = ref.watch(libraryProvider).isLoading;

    // If a category is expanded, show the expanded view
    if (expandedCategory != null && expandedItems != null) {
      return ExpandedCategoryGrid(
        category: expandedCategory!,
        items: expandedItems!,
        serverUrl: serverUrl,
        onBack: onClose,
        onItemTap: onItemTap,
      );
    }

    // Group results by type
    final groupedResults = groupMediaByType(searchResults);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'Search'),

        // Search bar
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        )
                      : searchResults.isEmpty
                      ? _buildEmptySearch()
                      : GroupedMediaGrid(
                          groupedItems: groupedResults,
                          serverUrl: serverUrl,
                          onShowAll: onShowAll,
                          onItemTap: onItemTap,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
}
