import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/pages/adaptive_pages.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'detail_loading_shimmer.dart';

class DetailArtistAlbumsSection extends ConsumerWidget {
  const DetailArtistAlbumsSection({
    super.key,
    required this.artistId,
    required this.serverUrl,
    this.isDesktop = true,
  });

  final String artistId;
  final String serverUrl;
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(artistAlbumsProvider(artistId));
    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) return const SizedBox.shrink();
        return RepaintBoundary(
          child: Padding(
            padding: isDesktop
                ? const EdgeInsets.fromLTRB(64, 0, 64, 40)
                : const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Albums',
                  style: isDesktop
                      ? AppTextStyles.titleLarge
                      : AppTextStyles.titleMedium,
                ),
                SizedBox(height: isDesktop ? 16 : 12),
                SizedBox(
                  height: isDesktop ? 280 : 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    addRepaintBoundaries: true,
                    addAutomaticKeepAlives: false,
                    cacheExtent: 500,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 6 : 0,
                      vertical: isDesktop ? 8 : 0,
                    ),
                    itemCount: albums.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(width: isDesktop ? 16 : 12),
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return AnimatedCard(
                        width: isDesktop ? 160 : 120,
                        imageUrl: album.getDisplayImageUrl(
                          serverUrl,
                          width: isDesktop ? 300 : 200,
                        ),
                        title: album.name,
                        subtitle: album.productionYear?.toString(),
                        animationIndex: index,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdaptiveDetailPage(itemId: album.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: isDesktop ? 400.ms : 200.ms),
          ),
        );
      },
      loading: () => isDesktop
          ? const DetailLoadingShimmer(height: 280)
          : const ShimmerLoading(height: 200),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
