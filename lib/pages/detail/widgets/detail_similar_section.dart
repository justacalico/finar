import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/pages/adaptive_pages.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'detail_loading_shimmer.dart';

/// Section widget that watches only [similarItemsProvider] so only this rebuilds when similar items load.
class DetailSimilarSection extends ConsumerWidget {
  const DetailSimilarSection({
    super.key,
    required this.itemId,
    required this.serverUrl,
    this.isDesktop = true,
  });

  final String itemId;
  final String serverUrl;
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarAsync = ref.watch(similarItemsProvider(itemId));
    return RepaintBoundary(
      child: Padding(
        padding: isDesktop
            ? const EdgeInsets.fromLTRB(64, 0, 64, 40)
            : const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'More Like This',
              style: isDesktop
                  ? AppTextStyles.titleLarge
                  : AppTextStyles.titleMedium,
            ),
            SizedBox(height: isDesktop ? 16 : 12),
            SizedBox(
              height: isDesktop ? 280 : 200,
              child: similarAsync.when(
                data: (items) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  addRepaintBoundaries: true,
                  addAutomaticKeepAlives: false,
                  cacheExtent: 500,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 6 : 0,
                    vertical: isDesktop ? 8 : 0,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(width: isDesktop ? 16 : 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return AnimatedCard(
                      width: isDesktop ? 160 : 120,
                      imageUrl: item.getDisplayImageUrl(
                        serverUrl,
                        width: isDesktop ? 300 : 200,
                      ),
                      title: item.name,
                      subtitle: item.productionYear?.toString(),
                      isWatched: item.isPlayed == true,
                      animationIndex: index,
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => AdaptiveDetailPage(itemId: item.id),
                          ),
                        );
                      },
                    );
                  },
                ),
                loading: () => isDesktop
                    ? const DetailLoadingShimmer(height: 280)
                    : const ShimmerLoading(height: 200),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ).animate().fadeIn(delay: isDesktop ? 600.ms : 200.ms),
      ),
    );
  }
}
