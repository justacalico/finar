import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/models.dart';
import 'session_provider.dart';

final librariesProvider = FutureProvider<List<BaseItem>>((ref) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) return const [];
  return (await client.getUserViews()).items;
});

final resumeItemsProvider = FutureProvider<List<BaseItem>>((ref) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) return const [];
  return (await client.getResumeItems(limit: 16)).items;
});

final nextUpProvider = FutureProvider<List<BaseItem>>((ref) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) return const [];
  return (await client.getNextUp(limit: 16)).items;
});

final latestMediaProvider =
    FutureProvider.family<List<BaseItem>, String>((ref, parentId) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) return const [];
  return (await client.getLatestMedia(parentId: parentId, limit: 12)).items;
});

final itemProvider =
    FutureProvider.family<BaseItem, String>((ref, id) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) throw StateError('not signed in');
  return client.getItem(id);
});

final similarItemsProvider =
    FutureProvider.family<List<BaseItem>, String>((ref, id) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) return const [];
  return (await client.getSimilar(id)).items;
});

final seasonsProvider =
    FutureProvider.family<List<BaseItem>, String>((ref, seriesId) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) return const [];
  return (await client.getSeasons(seriesId)).items;
});

final episodesProvider = FutureProvider.autoDispose
    .family<List<BaseItem>, ({String seriesId, String? seasonId})>(
        (ref, key) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) return const [];
  return (await client.getEpisodes(key.seriesId, seasonId: key.seasonId))
      .items;
});

final favoritesProvider = FutureProvider<List<BaseItem>>((ref) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) return const [];
  return (await client.getItems(
    filters: ['IsFavorite'],
    sortBy: ['SortName'],
    limit: 200,
  ))
      .items;
});

enum LibraryFilter { all, favorites, unplayed, watched }

class LibraryQuery {
  const LibraryQuery({
    required this.parentId,
    this.sortBy = 'SortName',
    this.descending = false,
    this.filter = LibraryFilter.all,
    this.genre,
  });

  final String parentId;
  final String sortBy;
  final bool descending;
  final LibraryFilter filter;
  final String? genre;

  LibraryQuery copyWith({
    String? sortBy,
    bool? descending,
    LibraryFilter? filter,
    String? Function()? genre,
  }) =>
      LibraryQuery(
        parentId: parentId,
        sortBy: sortBy ?? this.sortBy,
        descending: descending ?? this.descending,
        filter: filter ?? this.filter,
        genre: genre != null ? genre() : this.genre,
      );

  @override
  bool operator ==(Object other) =>
      other is LibraryQuery &&
      parentId == other.parentId &&
      sortBy == other.sortBy &&
      descending == other.descending &&
      filter == other.filter &&
      genre == other.genre;

  @override
  int get hashCode =>
      Object.hash(parentId, sortBy, descending, filter, genre);
}

class LibraryPageResult {
  const LibraryPageResult({required this.items, required this.total});

  final List<BaseItem> items;
  final int total;
}

final libraryPageProvider =
    FutureProvider.autoDispose.family<LibraryPageResult, ({LibraryQuery query, int start, int limit})>(
        (ref, args) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) {
    return const LibraryPageResult(items: [], total: 0);
  }
  final filters = switch (args.query.filter) {
    LibraryFilter.favorites => ['IsFavorite'],
    LibraryFilter.unplayed => ['IsUnplayed'],
    LibraryFilter.watched => ['IsPlayed'],
    LibraryFilter.all => null,
  };
  final result = await client.getItems(
    parentId: args.query.parentId,
    sortBy: [args.query.sortBy],
    sortOrder: args.query.descending ? 'Descending' : 'Ascending',
    filters: filters,
    genres: args.query.genre,
    limit: args.limit,
    startIndex: args.start,
    excludeItemTypes: 'Folder,CollectionFolder,UserView',
  );
  return LibraryPageResult(
      items: result.items, total: result.totalRecordCount);
});

final genresProvider =
    FutureProvider.autoDispose.family<List<BaseItem>, String>(
        (ref, parentId) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) return const [];
  final result = await client.getItems(
    parentId: parentId,
    includeItemTypes: ['Genre'],
    sortBy: ['SortName'],
    limit: 200,
    recursive: true,
  );
  return result.items;
});

final searchResultsProvider =
    FutureProvider.autoDispose.family<List<BaseItem>, String>(
        (ref, query) async {
  final client = ref.watch(jellyfinClientProvider);
  final trimmed = query.trim();
  if (client == null || trimmed.isEmpty) return const [];
  return (await client.getItems(
    searchTerm: trimmed,
    limit: 60,
    excludeItemTypes: 'Folder,CollectionFolder,UserView',
  ))
      .items;
});

final albumTracksProvider =
    FutureProvider.autoDispose.family<List<BaseItem>, String>(
        (ref, albumId) async {
  final client = ref.watch(jellyfinClientProvider);
  if (client == null) return const [];
  return (await client.getItems(
    parentId: albumId,
    includeItemTypes: ['Audio'],
    sortBy: ['SortName'],
    limit: 500,
  ))
      .items;
});
