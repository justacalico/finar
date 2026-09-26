import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';
import '../core/theme/app_theme.dart';
import '../providers/downloads_provider.dart';
import '../providers/home_provider.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/async_view.dart';
import '../widgets/backdrop_hero.dart';
import '../widgets/item_menu.dart';
import '../widgets/media_rail.dart';
import 'player_page.dart';
import 'see_all_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _openItem(BuildContext context, WidgetRef ref, MediaItem item) {
    ref.read(shellNavProvider.notifier).openDetail(item);
  }

  void _play(BuildContext context, MediaItem item) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PlayerPage(
            item: item,
            startPosition: item.resumeTicks > 0
                ? Duration(microseconds: item.resumeTicks ~/ 10)
                : null)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    return RefreshIndicator.adaptive(
      onRefresh: () => ref.refresh(homeProvider.future),
      child: AsyncView(
        value: home,
        onRetry: () => ref.invalidate(homeProvider),
        builder: (data) {
          if (data.resume.isEmpty &&
              data.nextUp.isEmpty &&
              data.latestByLibrary.isEmpty) {
            return const EmptyView(
              icon: Icons.video_library_outlined,
              title: 'Nothing here yet',
              subtitle:
                  'Add some media to your Jellyfin libraries to get started.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: Insets.xl),
            children: [
              if (data.featured != null)
                _Feature(
                    item: data.featured!,
                    onPlay: () => _play(context, data.featured!),
                    onOpen: () => _openItem(context, ref, data.featured!)),
              if (data.resume.isNotEmpty)
                MediaRail(
                  title: 'Continue watching',
                  items: data.resume,
                  shape: ArtShape.backdrop,
                  cardWidth: 260,
                  onTap: (i) => _openItem(context, ref, i),
                  onLongPress: (i) =>
                      showItemMenu(context, ref, i, onPlay: (x) => _play(context, x), onOpen: (i) => _openItem(context, ref, i)),
                ),
              if (data.nextUp.isNotEmpty)
                MediaRail(
                  title: 'Next up',
                  items: data.nextUp,
                  shape: ArtShape.backdrop,
                  cardWidth: 260,
                  onTap: (i) => _openItem(context, ref, i),
                  onLongPress: (i) =>
                      showItemMenu(context, ref, i, onPlay: (x) => _play(context, x), onOpen: (i) => _openItem(context, ref, i)),
                ),
              for (final section in data.latestByLibrary)
                MediaRail(
                  title: section.title,
                  items: section.items,
                  onSeeAll: section.libraryId == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => SeeAllPage(
                                    title: section.title,
                                    query: ItemQuery(
                                        parentId: section.libraryId,
                                        sortBy: 'DateCreated',
                                        sortOrder: 'Descending'),
                                  ))),
                  onTap: (i) => _openItem(context, ref, i),
                  onLongPress: (i) =>
                      showItemMenu(context, ref, i, onPlay: (x) => _play(context, x), onOpen: (i) => _openItem(context, ref, i)),
                ),
              if (data.favorites.isNotEmpty)
                MediaRail(
                  title: 'Favorites',
                  items: data.favorites,
                  onTap: (i) => _openItem(context, ref, i),
                  onLongPress: (i) =>
                      showItemMenu(context, ref, i, onPlay: (x) => _play(context, x), onOpen: (i) => _openItem(context, ref, i)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Feature extends ConsumerWidget {
  final MediaItem item;
  final VoidCallback onPlay;
  final VoidCallback onOpen;

  const _Feature(
      {required this.item, required this.onPlay, required this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(downloadsProvider);
    final downloaded = entries.any((e) =>
        e.item.id == item.id && e.status == DownloadStatus.done);
    return GestureDetector(
      onTap: onOpen,
      child: BackdropHero(
        item: item,
        height: 340,
        overlay: Padding(
          padding: const EdgeInsets.all(Insets.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(color: Colors.white)),
              if (item.metaLine != null) ...[
                const SizedBox(height: Insets.xs),
                Text(item.metaLine!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
              const SizedBox(height: Insets.md),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(item.hasProgress ? 'Resume' : 'Play'),
                  ),
                  const SizedBox(width: Insets.sm),
                  OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38)),
                  ),
                  if (downloaded) ...[
                    const SizedBox(width: Insets.sm),
                    const Icon(Icons.download_done,
                        color: Colors.white70),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
