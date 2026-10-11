import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/api/media_service.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';

class HomeContentView extends ConsumerWidget {
  final HomeData data;
  final void Function(String category, List<MediaItem> items) onShowAll;
  final void Function(MediaItem item) onItemTap;
  final void Function(MediaItem item) onPlayItem;

  const HomeContentView({
    super.key,
    required this.data,
    required this.onShowAll,
    required this.onItemTap,
    required this.onPlayItem,
  });

  /// For albums use album art (primary image); for other types use backdrop.
  static String _heroImageUrl(MediaItem item, String serverUrl) {
    if (item.type == MediaType.album) {
      return item.getPrimaryImageUrl(serverUrl, width: 1920);
    }
    return item.getBackdropUrl(serverUrl, width: 1920);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // Hero section
        SliverToBoxAdapter(
          child: data.recentlyAdded.isNotEmpty
              ? HeroCard(
                  imageUrl: _heroImageUrl(
                    data.recentlyAdded.first,
                    ref.read(jellyfinApiProvider).serverUrl ?? '',
                  ),
                  title: data.recentlyAdded.first.heroTitle,
                  subtitle: data.recentlyAdded.first.typeString,
                  description: data.recentlyAdded.first.overview,
                  year: data.recentlyAdded.first.productionYear?.toString(),
                  rating: data.recentlyAdded.first.communityRating
                      ?.toStringAsFixed(1),
                  runtime: data.recentlyAdded.first.formattedRuntime,
                  genres: data.recentlyAdded.first.genres?.take(3).toList(),
                  onTap: () => onItemTap(data.recentlyAdded.first),
                  onPlay: () => onPlayItem(data.recentlyAdded.first),
                  onInfo: () => onItemTap(data.recentlyAdded.first),
                )
              : const SizedBox(height: 300),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // Continue Watching
        if (data.continueWatching.isNotEmpty)
          SliverToBoxAdapter(
            child: _MediaRow(
              title: 'Continue Watching',
              items: data.continueWatching,
              showProgress: true,
              onShowAll: onShowAll,
              onItemTap: onItemTap,
            ),
          ),

        // Next Up
        if (data.nextUp.isNotEmpty)
          SliverToBoxAdapter(
            child: _MediaRow(
              title: 'Next Up',
              items: data.nextUp,
              onShowAll: onShowAll,
              onItemTap: onItemTap,
            ),
          ),

        // Recently Added
        if (data.recentlyAdded.isNotEmpty)
          SliverToBoxAdapter(
            child: _MediaRow(
              title: 'Recently Added',
              items: data.recentlyAdded.skip(1).toList(),
              onShowAll: onShowAll,
              onItemTap: onItemTap,
            ),
          ),

        // Recently Released Movies
        if (data.recentlyReleased.isNotEmpty)
          SliverToBoxAdapter(
            child: _MediaRow(
              title: 'New Releases',
              items: data.recentlyReleased,
              onShowAll: onShowAll,
              onItemTap: onItemTap,
            ),
          ),

        // Recently Added Movies
        if (data.recentlyAddedMovies.isNotEmpty)
          SliverToBoxAdapter(
            child: _MediaRow(
              title: 'New Movies',
              items: data.recentlyAddedMovies,
              onShowAll: onShowAll,
              onItemTap: onItemTap,
            ),
          ),

        // Recently Added Shows
        if (data.recentlyAddedShows.isNotEmpty)
          SliverToBoxAdapter(
            child: _MediaRow(
              title: 'New TV Shows',
              items: data.recentlyAddedShows,
              onShowAll: onShowAll,
              onItemTap: onItemTap,
            ),
          ),

        // Recommended
        if (data.recommended.isNotEmpty)
          SliverToBoxAdapter(
            child: _MediaRow(
              title: 'Recommended For You',
              items: data.recommended,
              onShowAll: onShowAll,
              onItemTap: onItemTap,
            ),
          ),

        // Top Rated
        if (data.topRated.isNotEmpty)
          SliverToBoxAdapter(
            child: _MediaRow(
              title: 'Top Rated',
              items: data.topRated,
              onShowAll: onShowAll,
              onItemTap: onItemTap,
            ),
          ),

        // Favorites
        if (data.favorites.isNotEmpty)
          SliverToBoxAdapter(
            child: _MediaRow(
              title: 'My Favorites',
              items: data.favorites,
              onShowAll: onShowAll,
              onItemTap: onItemTap,
            ),
          ),

        // Watchlist
        if (data.watchlist.isNotEmpty)
          SliverToBoxAdapter(
            child: _MediaRow(
              title: 'Watchlist',
              items: data.watchlist,
              onShowAll: onShowAll,
              onItemTap: onItemTap,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }
}

class _MediaRow extends ConsumerWidget {
  final String title;
  final List<MediaItem> items;
  final bool showProgress;
  final void Function(String category, List<MediaItem> items) onShowAll;
  final void Function(MediaItem item) onItemTap;

  const _MediaRow({
    required this.title,
    required this.items,
    this.showProgress = false,
    required this.onShowAll,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => onShowAll(title, items),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
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
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
              itemCount: items.length,
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: false,
              // Pre-cache items for smoother scrolling
              scrollCacheExtent: ScrollCacheExtent.pixels(500),
              separatorBuilder: (_, _) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: 170,
                  child: AnimatedCard(
                    imageUrl: item.getDisplayImageUrl(serverUrl, width: 300),
                    title: item.name,
                    subtitle: item.productionYear?.toString(),
                    progress: showProgress ? item.playbackProgress : null,
                    showProgress: showProgress,
                    isWatched: item.isPlayed == true,
                    enableEntranceAnimation: false,
                    onTap: () => onItemTap(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
