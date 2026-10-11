import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/widgets/widgets.dart';
import 'home_widgets.dart';

class GroupedMediaGrid extends ConsumerWidget {
  final Map<String, List<MediaItem>> groupedItems;
  final String serverUrl;
  final void Function(String category, List<MediaItem> items) onShowAll;
  final void Function(MediaItem item) onItemTap;

  const GroupedMediaGrid({
    super.key,
    required this.groupedItems,
    required this.serverUrl,
    required this.onShowAll,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      scrollCacheExtent: ScrollCacheExtent.pixels(500),
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
                    getCategoryIcon(category),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15),
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
                      onPressed: () => onShowAll(category, items),
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
                  addRepaintBoundaries: true,
                  addAutomaticKeepAlives: false,
                  scrollCacheExtent: ScrollCacheExtent.pixels(500),
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
                        subtitle: getItemSubtitle(item),
                        enableEntranceAnimation: false,
                        isWatched: item.isPlayed == true,
                        onTap: () => onItemTap(item),
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
}

class ExpandedCategoryGrid extends ConsumerWidget {
  final String category;
  final List<MediaItem> items;
  final String serverUrl;
  final VoidCallback onBack;
  final void Function(MediaItem item) onItemTap;

  const ExpandedCategoryGrid({
    super.key,
    required this.category,
    required this.items,
    required this.serverUrl,
    required this.onBack,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              Icon(
                getCategoryIcon(category),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
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
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: false,
              scrollCacheExtent: ScrollCacheExtent.pixels(1000),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return AnimatedCard(
                  imageUrl: item.getDisplayImageUrl(serverUrl, width: 300),
                  title: item.name,
                  subtitle: getItemSubtitle(item),
                  enableEntranceAnimation: false,
                  isWatched: item.isPlayed == true,
                  onTap: () => onItemTap(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
