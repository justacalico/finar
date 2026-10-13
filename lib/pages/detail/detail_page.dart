import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/models.dart';
import '../../core/storage/downloads_store.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/downloads_provider.dart';
import '../../providers/item_actions.dart';
import '../../providers/library_providers.dart';
import '../../providers/player_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/media_card.dart';
import '../../widgets/media_image.dart';
import '../../widgets/section_row.dart';

class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final item = ref.watch(itemProvider(itemId));
    return item.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (_, _) => EmptyState(
          icon: Icons.error_outline,
          message: l10n.error,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(itemProvider(itemId))),
      data: (item) => _DetailBody(item: item),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.item});

  final BaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final client = ref.watch(jellyfinClientProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width > 700;

    final poster = SizedBox(
      width: isWide ? 200 : 130,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: MediaImage(
          url: client?.primaryImageUrl(item, maxWidth: 400),
          icon: MediaCard.iconForType(item.type),
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.seriesName != null)
          Text(item.seriesName!,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: scheme.primary)),
        Text(item.name,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (item.productionYear != null)
              _Chip(label: '${item.productionYear}'),
            if (item.runTimeTicks != null)
              _Chip(label: formatTicks(item.runTimeTicks!)),
            if (item.communityRating != null)
              _Chip(
                  icon: Icons.star,
                  label: item.communityRating!
                      .toStringAsFixed(1)),
            if (item.officialRating != null)
              _Chip(label: item.officialRating!),
            if (item.type == 'Episode' &&
                item.parentIndexNumber != null)
              _Chip(
                  label:
                      'S${item.parentIndexNumber} E${item.indexNumber ?? ''}'),
          ],
        ),
        const SizedBox(height: 16),
        _Actions(item: item),
      ],
    );

    return ListView(
      children: [
        Stack(
          children: [
            SizedBox(
              height: isWide ? 380 : 260,
              width: double.infinity,
              child: MediaImage(
                url: client?.backdropImageUrl(item, maxWidth: 1600),
                icon: MediaCard.iconForType(item.type),
                borderRadius: 0,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      theme.scaffoldBackgroundColor,
                    ],
                    stops: const [0.35, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.back,
                style: IconButton.styleFrom(
                    backgroundColor:
                        Colors.black.withValues(alpha: 0.4),
                    foregroundColor: Colors.white),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 0,
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        poster,
                        const SizedBox(width: 20),
                        Expanded(child: info),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        poster,
                        const SizedBox(height: 12),
                        info,
                      ],
                    ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.genres.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in item.genres)
                      ActionChip(
                        label: Text(g),
                        onPressed: () {},
                      ),
                  ],
                ),
              if (item.overview != null &&
                  item.overview!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(l10n.overview,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(item.overview!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5)),
              ],
            ],
          ),
        ),
        if (item.type == 'Series') _SeasonsSection(item: item),
        if (item.type == 'MusicAlbum') _TracksSection(item: item),
        if (item.type == 'MusicArtist')
          _ArtistAlbumsSection(item: item),
        if (item.people.isNotEmpty) _CastSection(item: item),
        _SimilarSection(item: item),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: scheme.primary),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.item});

  final BaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.watch(itemActionsProvider);
    final downloads = ref.watch(downloadsProvider);
    final downloaded = ref
        .watch(downloadsProvider.notifier)
        .isDownloaded(item.id);
    final isBusy = downloads.any((d) =>
        d.itemId == item.id &&
        d.status == DownloadStatus.downloading);
    final queue = item.type == 'MusicAlbum'
        ? ref.watch(albumTracksProvider(item.id)).valueOrNull
        : null;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (item.isPlayable)
          FilledButton.icon(
            onPressed: () {
              ref.read(playerProvider.notifier).playItem(item);
              context.push('/play');
            },
            icon: const Icon(Icons.play_arrow),
            label: Text(item.userData.playbackPositionTicks > 0
                ? l10n.resume
                : l10n.play),
          ),
        if (item.type == 'Series')
          FilledButton.icon(
            onPressed: () => _playNextUp(context, ref),
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.play),
          ),
        if (item.type == 'MusicAlbum' && (queue?.isNotEmpty ?? false))
          FilledButton.icon(
            onPressed: () {
              ref
                  .read(playerProvider.notifier)
                  .playQueue(queue!, 0);
              context.push('/play');
            },
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.play),
          ),
        _ActionButton(
          icon: item.userData.isFavorite
              ? Icons.favorite
              : Icons.favorite_outline,
          label: item.userData.isFavorite
              ? l10n.unfavourite
              : l10n.favourite,
          onPressed: () => actions.setFavorite(
              item.id, !item.userData.isFavorite),
        ),
        _ActionButton(
          icon: item.userData.played
              ? Icons.check_circle
              : Icons.check_circle_outline,
          label: item.userData.played
              ? l10n.markUnplayed
              : l10n.markPlayed,
          onPressed: () =>
              actions.setPlayed(item.id, !item.userData.played),
        ),
        if (item.isPlayable)
          _ActionButton(
            icon: downloaded
                ? Icons.download_done
                : isBusy
                    ? Icons.downloading
                    : Icons.download_outlined,
            label: downloaded
                ? l10n.downloaded
                : l10n.download,
            onPressed: downloaded || isBusy
                ? null
                : () =>
                    ref.read(downloadsProvider.notifier).start(item),
          ),
        _ActionButton(
          icon: Icons.share_outlined,
          label: l10n.share,
          onPressed: () {
            final client = ref.read(jellyfinClientProvider);
            if (client != null) {
              SharePlus.instance.share(ShareParams(
                  text:
                      '${client.serverUrl}/web/index.html#/details?id=${item.id}'));
            }
          },
        ),
      ],
    );
  }

  Future<void> _playNextUp(BuildContext context, WidgetRef ref) async {
    try {
      final client = ref.read(jellyfinClientProvider);
      if (client == null) return;
      final next = (await client.getNextUp(seriesId: item.id, limit: 1))
          .items
          .firstOrNull;
      final target = next ??
          (await client.getEpisodes(item.id)).items.firstOrNull;
      if (target == null) return;
      await ref.read(playerProvider.notifier).playItem(target);
      if (context.mounted) context.push('/play');
    } catch (_) {}
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.icon, required this.label, this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _SeasonsSection extends ConsumerStatefulWidget {
  const _SeasonsSection({required this.item});

  final BaseItem item;

  @override
  ConsumerState<_SeasonsSection> createState() =>
      _SeasonsSectionState();
}

class _SeasonsSectionState extends ConsumerState<_SeasonsSection> {
  String? _seasonId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final seasons =
        ref.watch(seasonsProvider(widget.item.id)).valueOrNull ?? [];
    final seasonId = _seasonId ??
        (seasons.isNotEmpty ? seasons.first.id : null);
    final episodes = seasonId == null
        ? const <BaseItem>[]
        : ref
                .watch(episodesProvider(
                    (seriesId: widget.item.id, seasonId: seasonId)))
                .valueOrNull ??
            [];
    final client = ref.watch(jellyfinClientProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          child: Text(l10n.episodes,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        if (seasons.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: DropdownButton<String>(
              value: seasonId,
              items: [
                for (final season in seasons)
                  DropdownMenuItem(
                    value: season.id,
                    child: Text(season.name),
                  ),
              ],
              onChanged: (v) => setState(() => _seasonId = v),
            ),
          ),
        for (final episode in episodes)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            child: Card(
              child: ListTile(
                leading: SizedBox(
                  width: 110,
                  height: 62,
                  child: MediaImage(
                    url: client?.primaryImageUrl(episode,
                        maxWidth: 220),
                    icon: Icons.play_circle_outline,
                  ),
                ),
                title: Text(
                  '${episode.indexNumber ?? ''}. ${episode.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (episode.runTimeTicks != null)
                      Text(formatTicks(episode.runTimeTicks!),
                          style: theme.textTheme.bodySmall),
                    if (episode.userData.playbackPositionTicks > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: LinearProgressIndicator(
                          value: episode.resumeFraction,
                          minHeight: 3,
                        ),
                      ),
                  ],
                ),
                trailing: episode.userData.played
                    ? Icon(Icons.check_circle,
                        color: theme.colorScheme.primary, size: 20)
                    : null,
                onTap: () =>
                    context.push('/item/${episode.id}'),
              ),
            ),
          ),
      ],
    );
  }
}

class _TracksSection extends ConsumerWidget {
  const _TracksSection({required this.item});

  final BaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tracks =
        ref.watch(albumTracksProvider(item.id)).valueOrNull ?? [];
    if (tracks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          child: Text(l10n.tracks,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        for (var i = 0; i < tracks.length; i++)
          ListTile(
            dense: true,
            leading: SizedBox(
              width: 30,
              child: Text('${tracks[i].indexNumber ?? i + 1}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant)),
            ),
            title: Text(tracks[i].name,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: tracks[i].runTimeTicks != null
                ? Text(formatTicks(tracks[i].runTimeTicks!),
                    style: theme.textTheme.bodySmall)
                : null,
            onTap: () {
              ref
                  .read(playerProvider.notifier)
                  .playQueue(tracks, i);
            },
          ),
      ],
    );
  }
}

class _ArtistAlbumsSection extends ConsumerWidget {
  const _ArtistAlbumsSection({required this.item});

  final BaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final client = ref.watch(jellyfinClientProvider);
    final albums = ref.watch(
      FutureProvider.autoDispose<List<BaseItem>>((ref) async {
        final c = ref.watch(jellyfinClientProvider);
        if (c == null) return const [];
        return (await c.getItems(
          artistIds: item.id,
          includeItemTypes: ['MusicAlbum'],
          sortBy: ['ProductionYear'],
          sortOrder: 'Descending',
          recursive: true,
        ))
            .items;
      }),
    );
    return albums.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) => SectionRow(
        title: l10n.album,
        children: [
          for (final album in items)
            MediaCard(
              item: album,
              width: 160,
              imageUrl:
                  client?.primaryImageUrl(album, maxWidth: 320),
              subtitle: album.productionYear?.toString(),
              onTap: () => context.push('/item/${album.id}'),
            ),
        ],
      ),
    );
  }
}

class _CastSection extends ConsumerWidget {
  const _CastSection({required this.item});

  final BaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final client = ref.watch(jellyfinClientProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
          child: Text(l10n.cast,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: item.people.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final person = item.people[i];
              final url = client?.imageUrl(person.id, 'Primary',
                  maxWidth: 120);
              return SizedBox(
                width: 72,
                child: Column(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: ClipOval(
                        child: MediaImage(
                          url: url,
                          icon: Icons.person_outline,
                          borderRadius: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(person.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall),
                    if (person.role != null)
                      Text(person.role!,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme
                                  .colorScheme.onSurfaceVariant,
                              fontSize: 10)),
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

class _SimilarSection extends ConsumerWidget {
  const _SimilarSection({required this.item});

  final BaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final client = ref.watch(jellyfinClientProvider);
    final similar = ref.watch(similarItemsProvider(item.id));
    return similar.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) => SectionRow(
        title: l10n.similar,
        children: [
          for (final similar in items)
            MediaCard(
              item: similar,
              width: 160,
              imageUrl: client?.primaryImageUrl(similar,
                  maxWidth: 320),
              subtitle: similar.productionYear?.toString(),
              onTap: () => context.push('/item/${similar.id}'),
            ),
        ],
      ),
    );
  }
}
