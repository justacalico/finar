import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/jellyfin_api.dart';
import '../core/api/media_service.dart';
import '../core/api/models/media_item.dart';
import 'auth_provider.dart';
import 'library_provider.dart';

/// Enum for music content tabs
enum MusicTab { albums, tracks, artists }

/// Provider for music library content with tabs
final musicLibraryProvider =
    StateNotifierProvider.family<
      MusicLibraryNotifier,
      MusicLibraryState,
      String
    >((ref, libraryId) {
      final mediaService = ref.watch(mediaServiceProvider);
      final api = ref.watch(jellyfinApiProvider);
      return MusicLibraryNotifier(mediaService, api, libraryId);
    });

/// State for music library content
class MusicLibraryState {
  final MusicTab currentTab;

  // Albums
  final List<MediaItem> albums;
  final bool albumsLoading;
  final bool albumsHasMore;
  final int albumsTotal;

  // Tracks
  final List<MediaItem> tracks;
  final bool tracksLoading;
  final bool tracksHasMore;
  final int tracksTotal;

  // Artists
  final List<MediaItem> artists;
  final bool artistsLoading;
  final bool artistsHasMore;
  final int artistsTotal;

  // Common
  final String? error;
  final String sortBy;
  final String sortOrder;
  final String? searchQuery;

  const MusicLibraryState({
    this.currentTab = MusicTab.albums,
    this.albums = const [],
    this.albumsLoading = false,
    this.albumsHasMore = true,
    this.albumsTotal = 0,
    this.tracks = const [],
    this.tracksLoading = false,
    this.tracksHasMore = true,
    this.tracksTotal = 0,
    this.artists = const [],
    this.artistsLoading = false,
    this.artistsHasMore = true,
    this.artistsTotal = 0,
    this.error,
    this.sortBy = 'SortName',
    this.sortOrder = 'Ascending',
    this.searchQuery,
  });

  MusicLibraryState copyWith({
    MusicTab? currentTab,
    List<MediaItem>? albums,
    bool? albumsLoading,
    bool? albumsHasMore,
    int? albumsTotal,
    List<MediaItem>? tracks,
    bool? tracksLoading,
    bool? tracksHasMore,
    int? tracksTotal,
    List<MediaItem>? artists,
    bool? artistsLoading,
    bool? artistsHasMore,
    int? artistsTotal,
    String? error,
    String? sortBy,
    String? sortOrder,
    String? searchQuery,
  }) {
    return MusicLibraryState(
      currentTab: currentTab ?? this.currentTab,
      albums: albums ?? this.albums,
      albumsLoading: albumsLoading ?? this.albumsLoading,
      albumsHasMore: albumsHasMore ?? this.albumsHasMore,
      albumsTotal: albumsTotal ?? this.albumsTotal,
      tracks: tracks ?? this.tracks,
      tracksLoading: tracksLoading ?? this.tracksLoading,
      tracksHasMore: tracksHasMore ?? this.tracksHasMore,
      tracksTotal: tracksTotal ?? this.tracksTotal,
      artists: artists ?? this.artists,
      artistsLoading: artistsLoading ?? this.artistsLoading,
      artistsHasMore: artistsHasMore ?? this.artistsHasMore,
      artistsTotal: artistsTotal ?? this.artistsTotal,
      error: error,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get isLoading {
    switch (currentTab) {
      case MusicTab.albums:
        return albumsLoading;
      case MusicTab.tracks:
        return tracksLoading;
      case MusicTab.artists:
        return artistsLoading;
    }
  }

  bool get hasMore {
    switch (currentTab) {
      case MusicTab.albums:
        return albumsHasMore;
      case MusicTab.tracks:
        return tracksHasMore;
      case MusicTab.artists:
        return artistsHasMore;
    }
  }

  List<MediaItem> get currentItems {
    switch (currentTab) {
      case MusicTab.albums:
        return albums;
      case MusicTab.tracks:
        return tracks;
      case MusicTab.artists:
        return artists;
    }
  }

  int get currentTotal {
    switch (currentTab) {
      case MusicTab.albums:
        return albumsTotal;
      case MusicTab.tracks:
        return tracksTotal;
      case MusicTab.artists:
        return artistsTotal;
    }
  }
}

/// Notifier for music library content
class MusicLibraryNotifier extends StateNotifier<MusicLibraryState> {
  final MediaService _mediaService;
  final JellyfinApi _api;
  final String _libraryId;
  static const int _pageSize = 50;

  MusicLibraryNotifier(this._mediaService, this._api, this._libraryId)
    : super(const MusicLibraryState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load all tabs in parallel for better performance
    await Future.wait([
      _loadAlbums(refresh: true),
      _loadTracks(refresh: true),
      _loadArtists(refresh: true),
    ]);
  }

  void setTab(MusicTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  Future<void> _loadAlbums({bool refresh = false}) async {
    if (state.albumsLoading) return;

    final startIndex = refresh ? 0 : state.albums.length;
    state = state.copyWith(albumsLoading: true, error: null);

    try {
      final result = await _mediaService.getMusicLibraryContent(
        _libraryId,
        startIndex: startIndex,
        limit: _pageSize,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        searchTerm: state.searchQuery,
      );

      state = state.copyWith(
        albums: refresh ? result.items : [...state.albums, ...result.items],
        albumsTotal: result.totalCount,
        albumsHasMore:
            (refresh
                ? result.items.length
                : state.albums.length + result.items.length) <
            result.totalCount,
        albumsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(albumsLoading: false, error: e.toString());
    }
  }

  Future<void> _loadTracks({bool refresh = false}) async {
    if (state.tracksLoading) return;

    final startIndex = refresh ? 0 : state.tracks.length;
    state = state.copyWith(tracksLoading: true, error: null);

    try {
      final result = await _mediaService.getMusicTracks(
        _libraryId,
        startIndex: startIndex,
        limit: _pageSize,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        searchTerm: state.searchQuery,
      );

      state = state.copyWith(
        tracks: refresh ? result.items : [...state.tracks, ...result.items],
        tracksTotal: result.totalCount,
        tracksHasMore:
            (refresh
                ? result.items.length
                : state.tracks.length + result.items.length) <
            result.totalCount,
        tracksLoading: false,
      );
    } catch (e) {
      state = state.copyWith(tracksLoading: false, error: e.toString());
    }
  }

  Future<void> _loadArtists({bool refresh = false}) async {
    if (state.artistsLoading) return;

    final startIndex = refresh ? 0 : state.artists.length;
    state = state.copyWith(artistsLoading: true, error: null);

    try {
      final result = await _mediaService.getMusicArtists(
        _libraryId,
        startIndex: startIndex,
        limit: _pageSize,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        searchTerm: state.searchQuery,
      );

      state = state.copyWith(
        artists: refresh ? result.items : [...state.artists, ...result.items],
        artistsTotal: result.totalCount,
        artistsHasMore:
            (refresh
                ? result.items.length
                : state.artists.length + result.items.length) <
            result.totalCount,
        artistsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(artistsLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    switch (state.currentTab) {
      case MusicTab.albums:
        if (!state.albumsHasMore) return;
        await _loadAlbums();
        break;
      case MusicTab.tracks:
        if (!state.tracksHasMore) return;
        await _loadTracks();
        break;
      case MusicTab.artists:
        if (!state.artistsHasMore) return;
        await _loadArtists();
        break;
    }
  }

  Future<void> refresh() async {
    switch (state.currentTab) {
      case MusicTab.albums:
        await _loadAlbums(refresh: true);
        break;
      case MusicTab.tracks:
        await _loadTracks(refresh: true);
        break;
      case MusicTab.artists:
        await _loadArtists(refresh: true);
        break;
    }
  }

  Future<void> refreshAll() async {
    await _loadInitialData();
  }

  void setSorting(String sortBy, String sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    refreshAll();
  }

  void setSearch(String? query) {
    state = state.copyWith(searchQuery: query?.isEmpty == true ? null : query);
    refreshAll();
  }
}
