import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/providers.dart';
import '../../../widgets/widgets.dart';
import '../../detail.dart';

/// Favorites view for the mobile shell. Favorites has no bottom-nav tab, so
/// this only shows when the section was selected on desktop and the window
/// was resized down.
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
