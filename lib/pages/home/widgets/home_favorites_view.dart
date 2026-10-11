import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/providers.dart';
import '../../../widgets/widgets.dart';
import '../../../core/api/models/media_item.dart';
import '../../detail.dart';
import 'home_media_grid.dart';
import 'home_widgets.dart';

class DesktopFavoritesView extends ConsumerWidget {
  final String? expandedCategory;
  final List<MediaItem>? expandedItems;
  final void Function(String category, List<MediaItem> items) onShowAll;
  final VoidCallback onClose;
  final void Function(MediaItem item) onItemTap;

  const DesktopFavoritesView({
    super.key,
    required this.expandedCategory,
    required this.expandedItems,
    required this.onShowAll,
    required this.onClose,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider(null));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(title: 'Favorites'),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: favorites.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyFavorites();
                }
                // Group favorites by type
                final groupedItems = groupMediaByType(items);
                return GroupedMediaGrid(
                  groupedItems: groupedItems,
                  serverUrl: serverUrl,
                  onShowAll: onShowAll,
                  onItemTap: onItemTap,
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
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
        ),
      ],
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
}

class MobileFavoritesView extends ConsumerWidget {
  const MobileFavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider(null));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(title: 'Favorites'),
            Expanded(
              child: favorites.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 64,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No favorites yet',
                            style: AppTextStyles.titleMedium.copyWith(
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
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AnimatedCard(
                        imageUrl: item.getDisplayImageUrl(
                          serverUrl,
                          width: 240,
                        ),
                        title: item.name,
                        subtitle: item.productionYear?.toString(),
                        isWatched: item.isPlayed == true,
                        enableEntranceAnimation: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailPage(itemId: item.id),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                error: (e, _) => Center(
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
                          'Couldn\'t load favorites',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.refresh(favoritesProvider(null)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
