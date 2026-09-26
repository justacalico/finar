import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';
import 'providers.dart';

/// A fetchable slice of the item catalog. Immutable key for family providers.
class ItemQuery {
  final String? parentId;
  final List<String>? types;
  final String sortBy;
  final String sortOrder;
  final String? searchTerm;
  final bool? isFavorite;
  final List<String>? filters;
  final String? genres;
  final String? personIds;
  final int pageSize;

  const ItemQuery({
    this.parentId,
    this.types,
    this.sortBy = 'SortName',
    this.sortOrder = 'Ascending',
    this.searchTerm,
    this.isFavorite,
    this.filters,
    this.genres,
    this.personIds,
    this.pageSize = 60,
  });

  ItemQuery copyWith({
    String? sortBy,
    String? sortOrder,
    String? searchTerm,
    bool? isFavorite,
  }) =>
      ItemQuery(
        parentId: parentId,
        types: types,
        sortBy: sortBy ?? this.sortBy,
        sortOrder: sortOrder ?? this.sortOrder,
        searchTerm: searchTerm ?? this.searchTerm,
        isFavorite: isFavorite ?? this.isFavorite,
        filters: filters,
        genres: genres,
        personIds: personIds,
        pageSize: pageSize,
      );

  @override
  bool operator ==(Object other) =>
      other is ItemQuery &&
      other.parentId == parentId &&
      _listEq(other.types, types) &&
      other.sortBy == sortBy &&
      other.sortOrder == sortOrder &&
      other.searchTerm == searchTerm &&
      other.isFavorite == isFavorite &&
      _listEq(other.filters, filters) &&
      other.genres == genres &&
      other.personIds == personIds &&
      other.pageSize == pageSize;

  @override
  int get hashCode => Object.hash(
        parentId,
        Object.hashAll(types ?? const []),
        sortBy,
        sortOrder,
        searchTerm,
        isFavorite,
        Object.hashAll(filters ?? const []),
        genres,
        personIds,
        pageSize,
      );

  static bool _listEq(List<String>? a, List<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Paged list state for a query.
class PagedItems {
  final List<MediaItem> items;
  final int total;
  final bool loadingMore;

  const PagedItems({
    this.items = const [],
    this.total = 0,
    this.loadingMore = false,
  });

  bool get hasMore => items.length < total;

  PagedItems copyLoading(bool v) =>
      PagedItems(items: items, total: total, loadingMore: v);
}

/// Every live [PagedItemsNotifier] registers here so mutations can patch
/// all visible lists at once.
final itemListRegistryProvider =
    Provider<Set<PagedItemsNotifier>>((ref) => <PagedItemsNotifier>{});

class PagedItemsNotifier extends FamilyAsyncNotifier<PagedItems, ItemQuery> {
  @override
  Future<PagedItems> build(ItemQuery arg) async {
    final registry = ref.read(itemListRegistryProvider);
    registry.add(this);
    ref.onDispose(() => registry.remove(this));
    final result = await _fetch(0);
    return PagedItems(items: result.items, total: result.totalCount);
  }

  Future<ItemsResult> _fetch(int startIndex) {
    return ref.read(jellyfinClientProvider).getItems(
          parentId: arg.parentId,
          includeItemTypes: arg.types,
          startIndex: startIndex,
          limit: arg.pageSize,
          sortBy: arg.sortBy,
          sortOrder: arg.sortOrder,
          recursive: true,
          fields: const ['Overview'],
          searchTerm: arg.searchTerm,
          isFavorite: arg.isFavorite,
          filters: arg.filters,
          genres: arg.genres,
          personIds: arg.personIds,
        );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyLoading(true));
    try {
      final result = await _fetch(current.items.length);
      final latest = state.valueOrNull ?? current;
      state = AsyncData(PagedItems(
        items: [...latest.items, ...result.items],
        total: result.totalCount,
      ));
    } catch (_) {
      state = AsyncData(current.copyLoading(false));
      rethrow;
    }
  }

  /// Patch one item's user data in place (favorite/watched toggles).
  void updateItem(MediaItem updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(PagedItems(
      items: [
        for (final i in current.items) i.id == updated.id ? updated : i
      ],
      total: current.total,
      loadingMore: current.loadingMore,
    ));
  }
}

final pagedItemsProvider = AsyncNotifierProvider.family<PagedItemsNotifier,
    PagedItems, ItemQuery>(PagedItemsNotifier.new);

final itemProvider =
    FutureProvider.family.autoDispose<MediaItem, String>((ref, id) async {
  return ref.read(jellyfinClientProvider).getItem(id);
});

final similarProvider = FutureProvider.family
    .autoDispose<List<MediaItem>, String>((ref, id) async {
  return ref.read(jellyfinClientProvider).getSimilar(id);
});

final seasonsProvider = FutureProvider.family
    .autoDispose<List<MediaItem>, String>((ref, seriesId) async {
  return ref.read(jellyfinClientProvider).getSeasons(seriesId);
});

final episodesProvider = FutureProvider.family
    .autoDispose<List<MediaItem>, ({String seriesId, String seasonId})>(
        (ref, arg) async {
  return ref
      .read(jellyfinClientProvider)
      .getEpisodes(arg.seriesId, seasonId: arg.seasonId);
});

final searchProvider = FutureProvider.autoDispose
    .family<List<SearchHint>, String>((ref, query) async {
  if (query.trim().isEmpty) return const [];
  return ref.read(jellyfinClientProvider).search(query);
});

/// User-data mutations. Patches every live list plus the item cache so
/// the UI stays consistent everywhere.
class MediaActions {
  final Ref _ref;
  MediaActions(this._ref);

  Future<void> toggleFavorite(MediaItem item) async {
    final client = _ref.read(jellyfinClientProvider);
    final next = !item.isFavorite;
    await client.setFavorite(item.id, next);
    _patch(item.copyWith(
        userData: UserData(
      rating: item.userData.rating,
      playedPercentage: item.userData.playedPercentage,
      playbackPositionTicks: item.userData.playbackPositionTicks,
      playCount: item.userData.playCount,
      isFavorite: next,
      played: item.userData.played,
      lastPlayedDate: item.userData.lastPlayedDate,
    )));
  }

  Future<void> togglePlayed(MediaItem item) async {
    final client = _ref.read(jellyfinClientProvider);
    final next = !item.isPlayed;
    if (next) {
      await client.markPlayed(item.id);
    } else {
      await client.markUnplayed(item.id);
    }
    _patch(item.copyWith(
        userData: UserData(
      rating: item.userData.rating,
      playedPercentage: next ? 100 : 0,
      playbackPositionTicks: next ? item.userData.playbackPositionTicks : 0,
      playCount: item.userData.playCount,
      isFavorite: item.userData.isFavorite,
      played: next,
      lastPlayedDate: item.userData.lastPlayedDate,
    )));
  }

  void _patch(MediaItem updated) {
    for (final notifier in _ref.read(itemListRegistryProvider)) {
      notifier.updateItem(updated);
    }
    _ref.invalidate(itemProvider(updated.id));
  }
}

final mediaActionsProvider = Provider<MediaActions>(MediaActions.new);
