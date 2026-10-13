import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/library_providers.dart';
import '../../providers/session_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/media_card.dart';
import '../../widgets/responsive.dart';

const _pageSize = 60;

final _queryProvider = StateProvider.autoDispose
    .family<LibraryQuery, String>(
        (ref, parentId) => LibraryQuery(parentId: parentId));

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key, required this.libraryId, this.libraryName});

  final String libraryId;
  final String? libraryName;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final _scroll = ScrollController();
  final _loaded = <BaseItem>[];
  int _total = -1;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_loadingMore) return;
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels <
        _scroll.position.maxScrollExtent - 400) {
      return;
    }
    if (_total != -1 && _loaded.length >= _total) return;
    _loadMore();
  }

  Future<void> _loadMore() async {
    _loadingMore = true;
    final query = ref.read(_queryProvider(widget.libraryId));
    try {
      final result = await ref.read(libraryPageProvider(
              (query: query, start: _loaded.length, limit: _pageSize))
          .future);
      if (mounted) {
        setState(() {
          _loaded.addAll(result.items);
          _total = result.total;
        });
      }
    } finally {
      _loadingMore = false;
    }
  }

  void _reset() {
    setState(() {
      _loaded.clear();
      _total = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(_queryProvider(widget.libraryId));
    final firstPage = ref.watch(libraryPageProvider(
        (query: query, start: 0, limit: _pageSize)));

    if (_total == -1 && firstPage.hasValue) {
      final value = firstPage.value!;
      _loaded
        ..clear()
        ..addAll(value.items);
      _total = value.total;
    }

    return Column(
      children: [
        _Toolbar(
          libraryId: widget.libraryId,
          title: widget.libraryName,
          onChanged: _reset,
        ),
        Expanded(
          child: firstPage.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, _) => EmptyState(
                icon: Icons.error_outline,
                message: l10n.error,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(libraryPageProvider)),
            data: (_) {
              if (_loaded.isEmpty) {
                return EmptyState(
                    icon: Icons.video_library_outlined,
                    message: l10n.emptyLibrary);
              }
              final width = MediaQuery.sizeOf(context).width -
                  (isDesktopLayout(context) ? 244 : 0);
              final columns = gridColumnsForWidth(width);
              return GridView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(20),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.62,
                ),
                itemCount: _loaded.length + (_loadingMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= _loaded.length) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final item = _loaded[i];
                  return _GridCard(item: item);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GridCard extends ConsumerWidget {
  const _GridCard({required this.item});

  final BaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(jellyfinClientProvider);
    return MediaCard(
      item: item,
      width: double.infinity,
      imageUrl: client?.primaryImageUrl(item, maxWidth: 400),
      subtitle: item.seriesName ??
          (item.productionYear != null ? '${item.productionYear}' : null) ??
          item.albumArtist,
      onTap: () => context.push('/item/${item.id}'),
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar(
      {required this.libraryId, this.title, required this.onChanged});

  final String libraryId;
  final String? title;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(_queryProvider(libraryId));
    final notifier = ref.read(_queryProvider(libraryId).notifier);
    final genres = ref.watch(genresProvider(libraryId)).valueOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(title!,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final filter in LibraryFilter.values)
                ChoiceChip(
                  label: Text(switch (filter) {
                    LibraryFilter.all => l10n.filterAll,
                    LibraryFilter.favorites => l10n.favorites,
                    LibraryFilter.unplayed => l10n.unwatched,
                    LibraryFilter.watched => l10n.watched,
                  }),
                  selected: query.filter == filter,
                  onSelected: (_) {
                    notifier.state = query.copyWith(filter: filter);
                    onChanged();
                  },
                ),
              const SizedBox(width: 8),
              _SortMenu(
                query: query,
                onChanged: (next) {
                  notifier.state = next;
                  onChanged();
                },
              ),
              if (genres != null && genres.isNotEmpty)
                _GenreMenu(
                  genres: genres,
                  active: query.genre,
                  onChanged: (genre) {
                    notifier.state =
                        query.copyWith(genre: () => genre);
                    onChanged();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.query, required this.onChanged});

  final LibraryQuery query;
  final ValueChanged<LibraryQuery> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      'SortName': l10n.sortName,
      'DateCreated': l10n.sortDateAdded,
      'CommunityRating': l10n.sortRating,
      'ProductionYear,PremiereDate': l10n.sortReleaseDate,
    };
    return PopupMenuButton<LibraryQuery>(
      icon: const Icon(Icons.sort),
      tooltip: l10n.sortBy,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final entry in labels.entries)
          CheckedPopupMenuItem(
            value: query.copyWith(sortBy: entry.key),
            checked: query.sortBy == entry.key,
            child: Text(entry.value),
          ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: query.copyWith(descending: false),
          checked: !query.descending,
          child: Text(l10n.ascending),
        ),
        CheckedPopupMenuItem(
          value: query.copyWith(descending: true),
          checked: query.descending,
          child: Text(l10n.descending),
        ),
      ],
    );
  }
}

class _GenreMenu extends StatelessWidget {
  const _GenreMenu(
      {required this.genres, required this.active, required this.onChanged});

  final List<BaseItem> genres;
  final String? active;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String?>(
      icon: const Icon(Icons.category_outlined),
      tooltip: l10n.genres,
      onSelected: onChanged,
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: null,
          checked: active == null,
          child: Text(l10n.filterAll),
        ),
        const PopupMenuDivider(),
        for (final genre in genres)
          CheckedPopupMenuItem(
            value: genre.name,
            checked: active == genre.name,
            child: Text(genre.name),
          ),
      ],
    );
  }
}
