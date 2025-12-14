import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/jellyfin_api.dart';
import '../core/api/media_service.dart';
import '../core/api/models/media_item.dart';
import '../core/api/models/library.dart';
import 'auth_provider.dart';

/// Media service provider
final mediaServiceProvider = Provider<MediaService>((ref) {
  final api = ref.watch(jellyfinApiProvider);
  return MediaService(api);
});

/// Home data provider
final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final mediaService = ref.watch(mediaServiceProvider);
  return await mediaService.getHomeData();
});

/// Libraries provider
final librariesProvider = FutureProvider<List<Library>>((ref) async {
  final api = ref.watch(jellyfinApiProvider);
  return await api.getLibraries();
});

/// Library state for mobile/TV home pages
class LibraryState {
  final List<Library> libraries;
  final HomeData? homeData;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final List<MediaItem> searchResults;
  final Map<String, List<MediaItem>> libraryItems;

  const LibraryState({
    this.libraries = const [],
    this.homeData,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.searchResults = const [],
    this.libraryItems = const {},
  });

  // Convenience getters for home data
  List<MediaItem> get continueWatching => homeData?.continueWatching ?? [];
  List<MediaItem> get nextUp => homeData?.nextUp ?? [];
  List<MediaItem> get recentlyAdded => homeData?.recentlyAdded ?? [];
  List<MediaItem> get recentlyReleased => homeData?.recentlyReleased ?? [];
  List<MediaItem> get topRated => homeData?.topRated ?? [];
  List<MediaItem> get recommended => homeData?.recommended ?? [];
  List<MediaItem> get favorites => homeData?.favorites ?? [];
  List<MediaItem> get recentlyAddedMovies =>
      homeData?.recentlyAddedMovies ?? [];
  List<MediaItem> get recentlyAddedShows => homeData?.recentlyAddedShows ?? [];
  MediaItem? get featuredItem => continueWatching.isNotEmpty
      ? continueWatching.first
      : recentlyAdded.isNotEmpty
      ? recentlyAdded.first
      : null;

  LibraryState copyWith({
    List<Library>? libraries,
    HomeData? homeData,
    bool? isLoading,
    String? error,
    String? searchQuery,
    List<MediaItem>? searchResults,
    Map<String, List<MediaItem>>? libraryItems,
  }) {
    return LibraryState(
      libraries: libraries ?? this.libraries,
      homeData: homeData ?? this.homeData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      libraryItems: libraryItems ?? this.libraryItems,
    );
  }
}

/// Library notifier for mobile/TV home pages
class LibraryNotifier extends StateNotifier<LibraryState> {
  final MediaService _mediaService;
  final JellyfinApi _api;

  LibraryNotifier(this._mediaService, this._api) : super(const LibraryState());

  Future<void> loadLibraries() async {
    try {
      final libraries = await _api.getLibraries();
      state = state.copyWith(libraries: libraries);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadHomeData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final homeData = await _mediaService.getHomeData();
      state = state.copyWith(homeData: homeData, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchQuery: '', searchResults: []);
      return;
    }
    state = state.copyWith(searchQuery: query, isLoading: true);
    try {
      final results = await _mediaService.search(query);
      state = state.copyWith(
        searchResults: results.all
            .map(
              (h) => MediaItem(
                id: h.itemId,
                name: h.name,
                type: mediaTypeFromString(h.type),
                typeString: h.type,
              ),
            )
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '', searchResults: []);
  }
}

/// Library provider for mobile/TV home pages
final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((
  ref,
) {
  final mediaService = ref.watch(mediaServiceProvider);
  final api = ref.watch(jellyfinApiProvider);
  return LibraryNotifier(mediaService, api);
});

/// Library content state
class LibraryContentState {
  final List<MediaItem> items;
  final int totalCount;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const LibraryContentState({
    this.items = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  LibraryContentState copyWith({
    List<MediaItem>? items,
    int? totalCount,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return LibraryContentState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Library content notifier
class LibraryContentNotifier extends StateNotifier<LibraryContentState> {
  final MediaService _mediaService;
  final String _libraryId;
  String _sortBy = 'SortName';
  String _sortOrder = 'Ascending';
  List<String>? _genres;
  List<int>? _years;
  String? _searchTerm;

  LibraryContentNotifier(this._mediaService, this._libraryId)
    : super(const LibraryContentState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final content = await _mediaService.getLibraryContent(
        _libraryId,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        genres: _genres,
        years: _years,
        searchTerm: _searchTerm,
      );
      // Filter out seasons and episodes from library view
      final filteredItems = content.items
          .where(
            (item) =>
                item.type != MediaType.season && item.type != MediaType.episode,
          )
          .toList();
      state = LibraryContentState(
        items: filteredItems,
        totalCount: content.totalCount,
        hasMore: content.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final content = await _mediaService.getLibraryContent(
        _libraryId,
        startIndex: state.items.length,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        genres: _genres,
        years: _years,
        searchTerm: _searchTerm,
      );
      // Filter out seasons and episodes from library view
      final filteredItems = content.items
          .where(
            (item) =>
                item.type != MediaType.season && item.type != MediaType.episode,
          )
          .toList();
      state = state.copyWith(
        items: [...state.items, ...filteredItems],
        totalCount: content.totalCount,
        hasMore: content.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSorting(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    loadInitial();
  }

  void setFilters({List<String>? genres, List<int>? years}) {
    _genres = genres;
    _years = years;
    loadInitial();
  }

  void setSearch(String? term) {
    _searchTerm = term?.isEmpty == true ? null : term;
    loadInitial();
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

/// Library content provider factory
final libraryContentProvider =
    StateNotifierProvider.family<
      LibraryContentNotifier,
      LibraryContentState,
      String
    >((ref, libraryId) {
      final mediaService = ref.watch(mediaServiceProvider);
      return LibraryContentNotifier(mediaService, libraryId);
    });

/// Single item detail provider
final itemDetailProvider = FutureProvider.family<MediaItem, String>((
  ref,
  itemId,
) async {
  final api = ref.watch(jellyfinApiProvider);
  return await api.getItem(itemId);
});

/// Movie details provider
final movieDetailsProvider = FutureProvider.family<MovieDetails, String>((
  ref,
  movieId,
) async {
  final mediaService = ref.watch(mediaServiceProvider);
  return await mediaService.getMovieDetails(movieId);
});

/// Series details provider
final seriesDetailsProvider = FutureProvider.family<SeriesDetails, String>((
  ref,
  seriesId,
) async {
  final mediaService = ref.watch(mediaServiceProvider);
  return await mediaService.getSeriesDetails(seriesId);
});

/// Season episodes provider
final seasonEpisodesProvider =
    FutureProvider.family<
      List<MediaItem>,
      ({String seriesId, String seasonId})
    >((ref, params) async {
      final mediaService = ref.watch(mediaServiceProvider);
      return await mediaService.getSeasonEpisodes(
        params.seriesId,
        params.seasonId,
      );
    });

/// Similar items provider
final similarItemsProvider = FutureProvider.family<List<MediaItem>, String>((
  ref,
  itemId,
) async {
  final api = ref.watch(jellyfinApiProvider);
  return await api.getSimilarItems(itemId);
});

/// Continue watching provider
final continueWatchingProvider = FutureProvider<List<MediaItem>>((ref) async {
  final api = ref.watch(jellyfinApiProvider);
  return await api.getContinueWatching();
});

/// Next up provider
final nextUpProvider = FutureProvider<List<MediaItem>>((ref) async {
  final api = ref.watch(jellyfinApiProvider);
  return await api.getNextUp();
});

/// Recently added provider
final recentlyAddedProvider = FutureProvider.family<List<MediaItem>, String?>((
  ref,
  parentId,
) async {
  final api = ref.watch(jellyfinApiProvider);
  return await api.getRecentlyAdded(parentId: parentId);
});

/// Favorites provider
final favoritesProvider = FutureProvider.family<List<MediaItem>, List<String>?>(
  (ref, types) async {
    final api = ref.watch(jellyfinApiProvider);
    return await api.getFavorites(includeItemTypes: types);
  },
);

/// Search state
class SearchState {
  final String query;
  final SearchResults? results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results,
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    SearchResults? results,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Search notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final MediaService _mediaService;

  SearchNotifier(this._mediaService) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);
    try {
      final results = await _mediaService.search(query);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const SearchState();
  }
}

/// Search provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  final mediaService = ref.watch(mediaServiceProvider);
  return SearchNotifier(mediaService);
});

/// Favorite toggle provider
final favoriteToggleProvider =
    FutureProvider.family<bool, ({String itemId, bool currentState})>((
      ref,
      params,
    ) async {
      final mediaService = ref.watch(mediaServiceProvider);
      return await mediaService.toggleFavorite(
        params.itemId,
        params.currentState,
      );
    });
