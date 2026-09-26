import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/providers.dart';
import '../widgets/app_image.dart';
import '../widgets/async_view.dart';
import '../widgets/focusable.dart';
import '../widgets/media_grid.dart';
import '../widgets/page_header.dart';

/// Music library browser: Albums / Artists / Tracks tabs.
class MusicPage extends ConsumerStatefulWidget {
  final String libraryId;
  final String title;
  final bool inShell;

  const MusicPage(
      {super.key,
      required this.libraryId,
      this.title = 'Music',
      this.inShell = false});

  @override
  ConsumerState<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends ConsumerState<MusicPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          title: widget.title,
          showBack: widget.inShell,
          onBack: widget.inShell
              ? () => ref
                  .read(shellNavProvider.notifier)
                  .closeLibrary()
              : null,
          below: TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Albums'),
              Tab(text: 'Artists'),
              Tab(text: 'Tracks'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _AlbumsTab(libraryId: widget.libraryId),
              _ArtistsTab(libraryId: widget.libraryId),
              _TracksTab(libraryId: widget.libraryId),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlbumsTab extends ConsumerWidget {
  final String libraryId;
  const _AlbumsTab({required this.libraryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ItemQuery(
        parentId: libraryId, types: const ['MusicAlbum']);
    final page = ref.watch(pagedItemsProvider(query));
    return AsyncView(
      value: page,
      onRetry: () => ref.invalidate(pagedItemsProvider(query)),
      builder: (data) => data.items.isEmpty
          ? const EmptyView(
              icon: Icons.album_outlined, title: 'No albums')
          : MediaGrid(
              page: data,
              shape: ArtShape.square,
              onLoadMore: () => ref
                  .read(pagedItemsProvider(query).notifier)
                  .loadMore(),
              onTap: (item) => ref
                  .read(shellNavProvider.notifier)
                  .openDetail(item),
            ),
    );
  }
}

class _ArtistsTab extends ConsumerWidget {
  final String libraryId;
  const _ArtistsTab({required this.libraryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ItemQuery(
        parentId: libraryId, types: const ['MusicArtist']);
    final page = ref.watch(pagedItemsProvider(query));
    return AsyncView(
      value: page,
      onRetry: () => ref.invalidate(pagedItemsProvider(query)),
      builder: (data) => data.items.isEmpty
          ? const EmptyView(
              icon: Icons.person_outline, title: 'No artists')
          : MediaGrid(
              page: data,
              shape: ArtShape.square,
              onLoadMore: () => ref
                  .read(pagedItemsProvider(query).notifier)
                  .loadMore(),
              onTap: (item) => ref
                  .read(shellNavProvider.notifier)
                  .openDetail(item),
            ),
    );
  }
}

class _TracksTab extends ConsumerWidget {
  final String libraryId;
  const _TracksTab({required this.libraryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query =
        ItemQuery(parentId: libraryId, types: const ['Audio']);
    final page = ref.watch(pagedItemsProvider(query));
    final client = ref.read(jellyfinClientProvider);
    return AsyncView(
      value: page,
      onRetry: () => ref.invalidate(pagedItemsProvider(query)),
      builder: (data) => data.items.isEmpty
          ? const EmptyView(
              icon: Icons.music_note_outlined, title: 'No tracks')
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >
                        n.metrics.maxScrollExtent - 600 &&
                    data.hasMore &&
                    !data.loadingMore) {
                  ref
                      .read(pagedItemsProvider(query).notifier)
                      .loadMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(Insets.md),
                itemCount:
                    data.items.length + (data.hasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= data.items.length) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(Insets.md),
                      child:
                          CircularProgressIndicator.adaptive(),
                    ));
                  }
                  final track = data.items[i];
                  return Focusable(
                    onTap: () => ref
                        .read(audioPlayerProvider.notifier)
                        .playTracks(data.items, i),
                    child: ListTile(
                      leading: SizedBox(
                        width: 44,
                        child: AppImage(
                          track.albumId != null
                              ? client.imageUrl(
                                  track.albumId!, 'Primary',
                                  maxWidth: 88)
                              : '',
                          shape: ArtShape.square,
                          borderRadius: 8,
                        ),
                      ),
                      title: Text(track.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        [
                          if (track.artists.isNotEmpty)
                            track.artists.join(', '),
                          if (track.album != null) track.album!,
                        ].join('  •  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: track.runtimeLabel.isNotEmpty
                          ? Text(track.runtimeLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall)
                          : null,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
