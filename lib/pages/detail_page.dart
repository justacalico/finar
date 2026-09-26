import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../core/api/models.dart';
import '../core/theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/providers.dart';
import '../widgets/app_image.dart';
import '../widgets/async_view.dart';
import '../widgets/backdrop_hero.dart';
import '../widgets/detail_actions.dart';
import '../widgets/focusable.dart';
import '../widgets/media_rail.dart';
import '../widgets/playing_indicator.dart';
import 'player_page.dart';

/// Item detail: hero, info, actions, children (episodes / tracks /
/// artist albums), cast and similar items. Same page for every kind.
class DetailPage extends ConsumerWidget {
  final String itemId;
  final MediaItem? item; // optimistic, list data until the fetch lands

  const DetailPage({super.key, required this.itemId, this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(itemProvider(itemId));
    final shown = async.valueOrNull ?? item;
    return Scaffold(
      body: shown == null
          ? AsyncView(
              value: async,
              onRetry: () => ref.invalidate(itemProvider(itemId)),
              builder: (i) => _Body(item: i))
          : _Body(item: shown),
    );
  }
}

class _Body extends ConsumerWidget {
  final MediaItem item;
  const _Body({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.of(context).size.width >= 840;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              BackdropHero(item: item, height: wide ? 420 : 260),
              SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white),
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.black38),
                  onPressed: () => ref
                      .read(shellNavProvider.notifier)
                      .closeDetail(),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(child: _Header(item: item, wide: wide)),
        if (item.kind == MediaKind.series)
          SliverToBoxAdapter(child: _SeasonsSection(item: item)),
        if (item.kind == MediaKind.album)
          SliverToBoxAdapter(child: _AlbumTracks(item: item)),
        if (item.kind == MediaKind.artist)
          SliverToBoxAdapter(child: _ArtistAlbums(item: item)),
        if (item.people.isNotEmpty)
          SliverToBoxAdapter(child: _CastRail(item: item)),
        if (item.kind != MediaKind.artist)
          SliverToBoxAdapter(child: _SimilarRail(item: item)),
        const SliverToBoxAdapter(child: SizedBox(height: Insets.xxl)),
      ],
    );
  }
}

class _Header extends ConsumerWidget {
  final MediaItem item;
  final bool wide;
  const _Header({required this.item, required this.wide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(jellyfinClientProvider);
    final poster = client.posterUrl(item, maxWidth: 400);

    void play({bool resume = true}) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlayerPage(
                item: item,
                startPosition: resume && item.resumeTicks > 0
                    ? Duration(
                        microseconds: item.resumeTicks ~/ 10)
                    : null,
              )));
    }

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.displayTitle,
            style: Theme.of(context).textTheme.headlineMedium),
        if (item.metaLine != null ||
            item.communityRating != null) ...[
          const SizedBox(height: Insets.xs),
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (item.metaLine != null)
                Text(item.metaLine!,
                    style:
                        Theme.of(context).textTheme.bodySmall),
              if (item.communityRating != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                        item.communityRating!
                            .toStringAsFixed(1),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall),
                  ],
                ),
            ],
          ),
        ],
        const SizedBox(height: Insets.md),
        DetailActions(
          item: item,
          onPlay: play,
          onPlayFromStart: () => play(resume: false),
        ),
        if (item.overview != null &&
            item.overview!.isNotEmpty) ...[
          const SizedBox(height: Insets.md),
          Text(item.overview!,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (item.genres.isNotEmpty) ...[
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: [
              for (final g in item.genres)
                Chip(
                  label: Text(g),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(Insets.md),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 220,
                    child: AppImage(poster)),
                const SizedBox(width: Insets.lg),
                Expanded(child: info),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (poster.isNotEmpty)
                  SizedBox(width: 140, child: AppImage(poster)),
                const SizedBox(height: Insets.md),
                info,
              ],
            ),
    );
  }
}

class _SeasonsSection extends ConsumerStatefulWidget {
  final MediaItem item;
  const _SeasonsSection({required this.item});

  @override
  ConsumerState<_SeasonsSection> createState() =>
      _SeasonsSectionState();
}

class _SeasonsSectionState extends ConsumerState<_SeasonsSection> {
  String? _seasonId;

  @override
  Widget build(BuildContext context) {
    final seasons = ref.watch(seasonsProvider(widget.item.id));
    return AsyncView(
      value: seasons,
      builder: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        _seasonId ??= list.first.id;
        final episodes = ref.watch(episodesProvider(
            (seriesId: widget.item.id, seasonId: _seasonId!)));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.md, Insets.md, Insets.md, Insets.sm),
              child: DropdownButton<String>(
                value: _seasonId,
                underline: const SizedBox.shrink(),
                items: [
                  for (final s in list)
                    DropdownMenuItem(
                        value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) =>
                    setState(() => _seasonId = v),
              ),
            ),
            AsyncView(
              value: episodes,
              builder: (eps) => Column(
                children: [
                  for (final ep in eps) _EpisodeTile(episode: ep),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EpisodeTile extends ConsumerWidget {
  final MediaItem episode;
  const _EpisodeTile({required this.episode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(jellyfinClientProvider);
    return Focusable(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PlayerPage(
                item: episode,
                startPosition: episode.resumeTicks > 0
                    ? Duration(
                        microseconds: episode.resumeTicks ~/ 10)
                    : null,
              ))),
      child: ListTile(
        leading: SizedBox(
          width: 120,
          child: Stack(
            children: [
              AppImage(
                  client.thumbUrl(episode, maxWidth: 320),
                  shape: ArtShape.backdrop,
                  borderRadius: 8),
              if (episode.hasProgress)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                      value: episode.progress, minHeight: 3),
                ),
            ],
          ),
        ),
        title: Text(
          episode.indexNumber != null
              ? '${episode.indexNumber}. ${episode.name}'
              : episode.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            if (episode.runtimeLabel.isNotEmpty)
              episode.runtimeLabel,
            if (episode.isPlayed) 'Watched',
          ].join('  •  '),
          maxLines: 1,
        ),
        trailing: episode.isPlayed
            ? Icon(Icons.check_circle,
                size: 18,
                color: Theme.of(context).colorScheme.primary)
            : null,
      ),
    );
  }
}

class _AlbumTracks extends ConsumerWidget {
  final MediaItem item;
  const _AlbumTracks({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksQuery = ItemQuery(
        parentId: item.id,
        types: const ['Audio'],
        sortBy: 'ParentIndexNumber,IndexNumber');
    final page = ref.watch(pagedItemsProvider(tracksQuery));
    final audio = ref.watch(audioPlayerProvider);
    return AsyncView(
      value: page,
      builder: (data) {
        if (data.items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Insets.md, vertical: Insets.sm),
              child: FilledButton.tonalIcon(
                onPressed: () => ref
                    .read(audioPlayerProvider.notifier)
                    .playTracks(data.items, 0),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play album'),
              ),
            ),
            for (var i = 0; i < data.items.length; i++)
              _TrackTile(
                  track: data.items[i],
                  index: i,
                  playing:
                      audio.current?.id == data.items[i].id,
                  paused: !audio.playing,
                  onTap: () => ref
                      .read(audioPlayerProvider.notifier)
                      .playTracks(data.items, i)),
          ],
        );
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  final MediaItem track;
  final int index;
  final bool playing;
  final bool paused;
  final VoidCallback onTap;

  const _TrackTile(
      {required this.track,
      required this.index,
      required this.playing,
      this.paused = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 28,
        child: Center(
          child: playing
              ? PlayingIndicator(playing: !paused)
              : Text('${track.indexNumber ?? index + 1}',
                  style:
                      Theme.of(context).textTheme.bodySmall),
        ),
      ),
      title: Text(track.name,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: track.artists.isNotEmpty
          ? Text(track.artists.join(', '),
              maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: track.runtimeLabel.isNotEmpty
          ? Text(track.runtimeLabel,
              style: Theme.of(context).textTheme.bodySmall)
          : null,
      onTap: onTap,
    );
  }
}

class _ArtistAlbums extends ConsumerWidget {
  final MediaItem item;
  const _ArtistAlbums({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ItemQuery(
        personIds: item.id,
        types: const ['MusicAlbum'],
        sortBy: 'PremiereDate',
        sortOrder: 'Descending');
    final page = ref.watch(pagedItemsProvider(query));
    return AsyncView(
      value: page,
      builder: (data) => data.items.isEmpty
          ? const SizedBox.shrink()
          : MediaRail(
              title: 'Albums',
              items: data.items,
              shape: ArtShape.square,
              cardWidth: 170,
              onTap: (a) => ref
                  .read(shellNavProvider.notifier)
                  .openDetail(a),
            ),
    );
  }
}

class _CastRail extends ConsumerWidget {
  final MediaItem item;
  const _CastRail({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(jellyfinClientProvider);
    final people = item.people.take(12).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              Insets.md, Insets.lg, Insets.md, Insets.sm),
          child: Text('Cast',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: Insets.md),
            itemCount: people.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: Insets.md),
            itemBuilder: (context, i) {
              final p = people[i];
              return SizedBox(
                width: 80,
                child: Column(
                  children: [
                    AppImage(
                      client.personImageUrl(p, maxWidth: 160),
                      shape: ArtShape.avatar,
                    ),
                    const SizedBox(height: 6),
                    Text(p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium),
                    if (p.role != null)
                      Text(p.role!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SimilarRail extends ConsumerWidget {
  final MediaItem item;
  const _SimilarRail({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similar = ref.watch(similarProvider(item.id));
    return AsyncView(
      value: similar,
      builder: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : MediaRail(
              title: 'More like this',
              items: items,
              onTap: (i) => ref
                  .read(shellNavProvider.notifier)
                  .openDetail(i),
            ),
    );
  }
}
