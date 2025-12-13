import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/jellyfin_api.dart';
import '../core/api/media_service.dart';
import '../core/api/models/media_item.dart';
import 'auth_provider.dart';

/// Provider for the Jellyfin API client
final jellyfinApiProvider = Provider<JellyfinApi>((ref) {
  final authState = ref.watch(authProvider);
  final api = JellyfinApi();
  
  if (authState.user != null) {
    api.configure(
      serverUrl: authState.user!.serverUrl,
      accessToken: authState.user!.accessToken,
      userId: authState.user!.id,
    );
  }
  
  return api;
});

/// Provider for the media service
final mediaServiceProvider = Provider<MediaService>((ref) {
  final api = ref.watch(jellyfinApiProvider);
  return MediaService(api);
});

/// Provider for media item detail
final mediaItemDetailProvider = FutureProvider.family<MediaItem, String>((ref, itemId) async {
  final mediaService = ref.watch(mediaServiceProvider);
  return mediaService.getItemDetails(itemId);
});

/// Provider for library content with pagination
final libraryContentProvider = StateNotifierProvider.family<LibraryContentNotifier, LibraryContentState, String>(
  (ref, libraryId) {
    final mediaService = ref.watch(mediaServiceProvider);
    return LibraryContentNotifier(mediaService, libraryId);
  },
);

/// State for library content
class LibraryContentState {
  final List<MediaItem> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int totalCount;
  final String sortBy;
  final String sortOrder;
  final String? searchQuery;

  const LibraryContentState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.totalCount = 0,
    this.sortBy = 'SortName',
    this.sortOrder = 'Ascending',
    this.searchQuery,
  });

  LibraryContentState copyWith({
    List<MediaItem>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? totalCount,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) {
    return LibraryContentState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      totalCount: totalCount ?? this.totalCount,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier for library content with pagination
class LibraryContentNotifier extends StateNotifier<LibraryContentState> {
  final MediaService _mediaService;
  final String _libraryId;
  static const int _pageSize = 50;

  LibraryContentNotifier(this._mediaService, this._libraryId)
      : super(const LibraryContentState()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _mediaService.getLibraryItems(
        _libraryId,
        limit: _pageSize,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        searchTerm: state.searchQuery,
      );
      
      state = state.copyWith(
        items: result.items,
        totalCount: result.totalCount,
        hasMore: result.items.length < result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final result = await _mediaService.getLibraryItems(
        _libraryId,
        startIndex: state.items.length,
        limit: _pageSize,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        searchTerm: state.searchQuery,
      );
      
      state = state.copyWith(
        items: [...state.items, ...result.items],
        hasMore: state.items.length + result.items.length < result.totalCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = const LibraryContentState();
    await _loadInitial();
  }

  void setSorting(String sortBy, String sortOrder) {
    state = LibraryContentState(
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: state.searchQuery,
    );
    _loadInitial();
  }

  void setSearch(String query) {
    state = LibraryContentState(
      sortBy: state.sortBy,
      sortOrder: state.sortOrder,
      searchQuery: query.isEmpty ? null : query,
    );
    _loadInitial();
  }
}

/// Provider for seasons of a series
final seasonsProvider = FutureProvider.family<List<MediaItem>, String>((ref, seriesId) async {
  final mediaService = ref.watch(mediaServiceProvider);
  return mediaService.getSeasons(seriesId);
});

/// Provider for episodes of a season
final episodesProvider = FutureProvider.family<List<MediaItem>, String>((ref, seasonId) async {
  final mediaService = ref.watch(mediaServiceProvider);
  return mediaService.getEpisodes(seasonId);
});

/// Provider for similar items
final similarItemsProvider = FutureProvider.family<List<MediaItem>, String>((ref, itemId) async {
  final mediaService = ref.watch(mediaServiceProvider);
  return mediaService.getSimilarItems(itemId);
});

/// Provider for search results from library provider
final searchResultsProvider = Provider<List<MediaItem>>((ref) {
  final libraryState = ref.watch(libraryProvider);
  return libraryState.searchResults;
});

/// Provider for media actions (favorites, watched, etc.)
final mediaActionsProvider = Provider<MediaActions>((ref) {
  final api = ref.watch(jellyfinApiProvider);
  return MediaActions(api);
});

/// Media actions helper class
class MediaActions {
  final JellyfinApi _api;

  MediaActions(this._api);

  Future<void> toggleFavorite(String itemId, bool isFavorite) async {
    await _api.setFavorite(itemId, isFavorite);
  }

  Future<void> toggleWatched(String itemId, bool isWatched) async {
    await _api.setWatched(itemId, isWatched);
  }
}
