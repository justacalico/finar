import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/jellyfin_api.dart';
import '../core/api/media_service.dart';
import '../core/api/models/media_item.dart';
import '../core/api/models/library.dart';
import 'auth_provider.dart';
import 'library_provider.dart';

/// Provider for media item detail
final mediaItemDetailProvider = FutureProvider.family<MediaItem, String>((ref, itemId) async {
  final mediaService = ref.watch(mediaServiceProvider);
  return mediaService.getItemDetails(itemId);
});

/// Provider for album tracks
final albumTracksProvider = FutureProvider.family<List<MediaItem>, String>((ref, albumId) async {
  final mediaService = ref.watch(mediaServiceProvider);
  return mediaService.getAlbumTracks(albumId);
});

/// Provider for library content with pagination
final libraryContentProvider = StateNotifierProvider.family<LibraryContentNotifier, LibraryContentState, String>(
  (ref, libraryId) {
    final mediaService = ref.watch(mediaServiceProvider);
    final api = ref.watch(jellyfinApiProvider);
    return LibraryContentNotifier(mediaService, api, libraryId);
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
  final bool isMusicLibrary;

  const LibraryContentState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.totalCount = 0,
    this.sortBy = 'SortName',
    this.sortOrder = 'Ascending',
    this.searchQuery,
    this.isMusicLibrary = false,
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
    bool? isMusicLibrary,
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
      isMusicLibrary: isMusicLibrary ?? this.isMusicLibrary,
    );
  }
}

/// Notifier for library content with pagination
class LibraryContentNotifier extends StateNotifier<LibraryContentState> {
  final MediaService _mediaService;
  final JellyfinApi _api;
  final String _libraryId;
  static const int _pageSize = 50;
  bool _isMusicLibrary = false;

  LibraryContentNotifier(this._mediaService, this._api, this._libraryId)
      : super(const LibraryContentState()) {
    _detectLibraryTypeAndLoad();
  }

  Future<void> _detectLibraryTypeAndLoad() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // First, get the library info to check its type
      final libraries = await _api.getLibraries();
      final library = libraries.firstWhere(
        (lib) => lib.id == _libraryId,
        orElse: () => Library(id: _libraryId, name: 'Library'),
      );
      
      // Check for music library - Jellyfin uses "music" as the collection type
      _isMusicLibrary = library.collectionType?.toLowerCase() == 'music';
      print('Library: ${library.name}, collectionType: ${library.collectionType}, isMusicLibrary: $_isMusicLibrary');
      state = state.copyWith(isMusicLibrary: _isMusicLibrary);
      
      await _loadInitial();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final LibraryContent result;
      
      if (_isMusicLibrary) {
        // For music libraries, load albums instead of tracks
        result = await _mediaService.getMusicLibraryContent(
          _libraryId,
          limit: _pageSize,
          sortBy: state.sortBy,
          sortOrder: state.sortOrder,
          searchTerm: state.searchQuery,
        );
      } else {
        result = await _mediaService.getLibraryItems(
          _libraryId,
          limit: _pageSize,
          sortBy: state.sortBy,
          sortOrder: state.sortOrder,
          searchTerm: state.searchQuery,
        );
      }
      
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
      final LibraryContent result;
      
      if (_isMusicLibrary) {
        result = await _mediaService.getMusicLibraryContent(
          _libraryId,
          startIndex: state.items.length,
          limit: _pageSize,
          sortBy: state.sortBy,
          sortOrder: state.sortOrder,
          searchTerm: state.searchQuery,
        );
      } else {
        result = await _mediaService.getLibraryItems(
          _libraryId,
          startIndex: state.items.length,
          limit: _pageSize,
          sortBy: state.sortBy,
          sortOrder: state.sortOrder,
          searchTerm: state.searchQuery,
        );
      }
      
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
    state = LibraryContentState(isMusicLibrary: _isMusicLibrary);
    await _loadInitial();
  }

  void setSorting(String sortBy, String sortOrder) {
    state = LibraryContentState(
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchQuery: state.searchQuery,
      isMusicLibrary: _isMusicLibrary,
    );
    _loadInitial();
  }

  void setSearch(String query) {
    state = LibraryContentState(
      sortBy: state.sortBy,
      sortOrder: state.sortOrder,
      searchQuery: query.isEmpty ? null : query,
      isMusicLibrary: _isMusicLibrary,
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
  return MediaActions(api, ref);
});

/// Media actions helper class
class MediaActions {
  final JellyfinApi _api;
  final Ref _ref;

  MediaActions(this._api, this._ref);

  Future<void> toggleFavorite(String itemId, bool isFavorite) async {
    await _api.setFavorite(itemId, isFavorite);
    // Invalidate the item detail provider to refresh the UI
    _ref.invalidate(mediaItemDetailProvider(itemId));
  }

  Future<void> toggleWatched(String itemId, bool isWatched) async {
    await _api.setWatched(itemId, isWatched);
    // Invalidate the item detail provider to refresh the UI
    _ref.invalidate(mediaItemDetailProvider(itemId));
  }

  /// Mark an episode as watched and refresh relevant providers
  Future<void> markEpisodeWatched(String episodeId, String seasonId, bool isWatched) async {
    await _api.setWatched(episodeId, isWatched);
    // Invalidate both the episode detail and episodes list
    _ref.invalidate(mediaItemDetailProvider(episodeId));
    _ref.invalidate(episodesProvider(seasonId));
  }
}
