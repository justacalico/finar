import 'jellyfin_api.dart';
import 'models/media_item.dart';
import 'models/library.dart';
import 'models/playback_info.dart';

/// Service for media-related operations
class MediaService {
  final JellyfinApi _api;

  MediaService(this._api);

  /// Get home screen data
  Future<HomeData> getHomeData() async {
    final results = await Future.wait([
      _api.getContinueWatching(limit: 12),
      _api.getNextUp(limit: 12),
      _api.getRecentlyAdded(limit: 20),
      _api.getRecentlyReleased(limit: 16),
      _api.getTopRated(limit: 16),
      _api.getRecommended(limit: 16),
      _api.getFavorites(limit: 16),
      _api.getRecentlyAdded(limit: 12, includeItemTypes: ['Movie']),
      _api.getRecentlyAdded(limit: 12, includeItemTypes: ['Series']),
      _api.getLibraries(),
    ]);

    return HomeData(
      continueWatching: results[0] as List<MediaItem>,
      nextUp: results[1] as List<MediaItem>,
      recentlyAdded: results[2] as List<MediaItem>,
      recentlyReleased: results[3] as List<MediaItem>,
      topRated: results[4] as List<MediaItem>,
      recommended: results[5] as List<MediaItem>,
      favorites: results[6] as List<MediaItem>,
      recentlyAddedMovies: results[7] as List<MediaItem>,
      recentlyAddedShows: results[8] as List<MediaItem>,
      libraries: results[9] as List<Library>,
    );
  }

  /// Get library content
  Future<LibraryContent> getLibraryContent(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    List<String>? genres,
    List<int>? years,
    String? searchTerm,
  }) async {
    final result = await _api.getItems(
      parentId: libraryId,
      startIndex: startIndex,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
      recursive: true,
      fields: ['Overview', 'PrimaryImageAspectRatio'],
      genres: genres?.join(','),
      years: years?.join(','),
      searchTerm: searchTerm,
      // Exclude non-browsable items: folders, seasons, episodes, individual audio tracks, and artists
      // Music libraries will show only albums
      excludeItemTypes: [
        'Folder',
        'CollectionFolder',
        'UserView',
        'Playlist',
        'Season',
        'Episode',
        'Audio',
        'MusicArtist',
      ],
    );

    return LibraryContent(
      items: result.items,
      totalCount: result.totalCount,
      hasMore: result.startIndex + result.items.length < result.totalCount,
    );
  }

  /// Get movie details
  Future<MovieDetails> getMovieDetails(String movieId) async {
    final results = await Future.wait([
      _api.getItem(movieId),
      _api.getSimilarItems(movieId, limit: 12),
    ]);

    return MovieDetails(
      movie: results[0] as MediaItem,
      similar: results[1] as List<MediaItem>,
    );
  }

  /// Get series details with seasons
  Future<SeriesDetails> getSeriesDetails(String seriesId) async {
    final results = await Future.wait([
      _api.getItem(seriesId),
      _api.getSeasons(seriesId),
      _api.getSimilarItems(seriesId, limit: 12),
      _api.getNextUp(limit: 1),
    ]);

    final series = results[0] as MediaItem;
    final seasons = results[1] as List<MediaItem>;
    final similar = results[2] as List<MediaItem>;
    final nextUpList = results[3] as List<MediaItem>;

    // Find the next up episode for this series
    MediaItem? nextUp;
    for (final item in nextUpList) {
      if (item.seriesId == seriesId) {
        nextUp = item;
        break;
      }
    }

    return SeriesDetails(
      series: series,
      seasons: seasons,
      similar: similar,
      nextUp: nextUp,
    );
  }

  /// Get next up episode for a specific series
  Future<MediaItem?> getNextUpForSeries(String seriesId) async {
    final nextUpList = await _api.getNextUp(limit: 1, seriesId: seriesId);
    return nextUpList.isNotEmpty ? nextUpList.first : null;
  }

  /// Get the next episode after the current one
  /// Returns null if no next episode exists (end of season/series)
  Future<MediaItem?> getNextEpisode(MediaItem currentEpisode) async {
    if (currentEpisode.seriesId == null || currentEpisode.seasonId == null) {
      return null;
    }

    // Get all episodes in the current season
    final episodes = await _api.getEpisodes(
      currentEpisode.seriesId!,
      seasonId: currentEpisode.seasonId!,
    );

    // Find current episode index
    final currentIndex = episodes.indexWhere((e) => e.id == currentEpisode.id);
    if (currentIndex == -1) return null;

    // If there's a next episode in the same season
    if (currentIndex < episodes.length - 1) {
      return episodes[currentIndex + 1];
    }

    // Try to get next season's first episode
    final seasons = await _api.getSeasons(currentEpisode.seriesId!);
    final currentSeasonNumber = currentEpisode.parentIndexNumber ?? 0;
    
    // Find next season
    final nextSeason = seasons.where(
      (s) => (s.indexNumber ?? 0) > currentSeasonNumber
    ).toList();
    
    if (nextSeason.isNotEmpty) {
      // Sort by season number and get first
      nextSeason.sort((a, b) => 
        (a.indexNumber ?? 0).compareTo(b.indexNumber ?? 0)
      );
      
      final nextSeasonEpisodes = await _api.getEpisodes(
        currentEpisode.seriesId!,
        seasonId: nextSeason.first.id,
      );
      
      if (nextSeasonEpisodes.isNotEmpty) {
        return nextSeasonEpisodes.first;
      }
    }

    return null;
  }

  /// Get local trailers for an item
  Future<List<MediaItem>> getLocalTrailers(String itemId) async {
    return await _api.getLocalTrailers(itemId);
  }

  /// Get season episodes
  Future<List<MediaItem>> getSeasonEpisodes(
    String seriesId,
    String seasonId,
  ) async {
    return await _api.getEpisodes(seriesId, seasonId: seasonId);
  }

  /// Get playback info and stream URL
  Future<StreamInfo> getStreamInfo(
    String itemId, {
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? startTimeTicks,
  }) async {
    final playbackInfo = await _api.getPlaybackInfo(
      itemId,
      audioStreamIndex: audioStreamIndex,
      subtitleStreamIndex: subtitleStreamIndex,
      startTimeTicks: startTimeTicks,
    );

    final source = playbackInfo.directPlaySource;
    if (source == null) {
      throw Exception('No playable media source found');
    }

    String streamUrl;
    bool isTranscoding = false;

    if (source.supportsDirectPlay == true ||
        source.supportsDirectStream == true) {
      // Direct play/stream
      streamUrl = _api.getStreamUrl(
        itemId,
        mediaSourceId: source.id,
        container: source.container,
        audioStreamIndex: audioStreamIndex ?? source.defaultAudioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
        startTimeTicks: startTimeTicks,
        static: true,
      );
    } else {
      // Transcoding required
      isTranscoding = true;
      streamUrl = _api.getHlsStreamUrl(
        itemId,
        mediaSourceId: source.id,
        playSessionId: playbackInfo.playSessionId,
        audioStreamIndex: audioStreamIndex ?? source.defaultAudioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
        startTimeTicks: startTimeTicks,
      );
    }

    return StreamInfo(
      url: streamUrl,
      mediaSource: source,
      playSessionId: playbackInfo.playSessionId,
      isTranscoding: isTranscoding,
      audioStreams: source.audioStreams,
      subtitleStreams: source.subtitleStreams,
      defaultAudioIndex: source.defaultAudioStreamIndex,
      defaultSubtitleIndex: source.defaultSubtitleStreamIndex,
    );
  }

  /// Get subtitle URL
  String getSubtitleUrl(
    String itemId,
    String mediaSourceId,
    int subtitleIndex, {
    String format = 'vtt',
  }) {
    return _api.getSubtitleUrl(itemId, mediaSourceId, subtitleIndex, format);
  }

  /// Report playback started
  Future<void> reportPlaybackStarted(
    String itemId, {
    String? mediaSourceId,
    String? playSessionId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? positionTicks,
    String playMethod = 'DirectPlay',
  }) async {
    await _api.reportPlaybackStart(
      PlaybackStartInfo(
        itemId: itemId,
        mediaSourceId: mediaSourceId,
        playSessionId: playSessionId,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
        positionTicks: positionTicks,
        playMethod: playMethod,
        canSeek: true,
      ),
    );
  }

  /// Report playback progress
  Future<void> reportPlaybackProgress(
    String itemId, {
    String? mediaSourceId,
    String? playSessionId,
    required int positionTicks,
    bool isPaused = false,
    bool isMuted = false,
    int? volumeLevel,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    String playMethod = 'DirectPlay',
  }) async {
    await _api.reportPlaybackProgress(
      PlaybackProgressInfo(
        itemId: itemId,
        mediaSourceId: mediaSourceId,
        playSessionId: playSessionId,
        positionTicks: positionTicks,
        isPaused: isPaused,
        isMuted: isMuted,
        volumeLevel: volumeLevel,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
        playMethod: playMethod,
        canSeek: true,
      ),
    );
  }

  /// Report playback stopped
  Future<void> reportPlaybackStopped(
    String itemId, {
    String? mediaSourceId,
    String? playSessionId,
    required int positionTicks,
  }) async {
    await _api.reportPlaybackStopped(
      PlaybackStopInfo(
        itemId: itemId,
        mediaSourceId: mediaSourceId,
        playSessionId: playSessionId,
        positionTicks: positionTicks,
      ),
    );
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String itemId, bool currentState) async {
    if (currentState) {
      await _api.removeFavorite(itemId);
      return false;
    } else {
      await _api.addFavorite(itemId);
      return true;
    }
  }

  /// Mark item as played
  Future<void> markPlayed(String itemId) async {
    await _api.markPlayed(itemId);
  }

  /// Mark item as unplayed
  Future<void> markUnplayed(String itemId) async {
    await _api.markUnplayed(itemId);
  }

  /// Search for content
  Future<SearchResults> search(String query) async {
    final hints = await _api.search(query);

    return SearchResults(
      movies: hints.where((h) => h.type == 'Movie').toList(),
      series: hints.where((h) => h.type == 'Series').toList(),
      episodes: hints.where((h) => h.type == 'Episode').toList(),
      music: hints
          .where(
            (h) =>
                h.type == 'Audio' ||
                h.type == 'MusicAlbum' ||
                h.type == 'MusicArtist',
          )
          .toList(),
      all: hints,
    );
  }

  /// Get image URL helper
  String getImageUrl(
    String itemId,
    String imageType, {
    int? width,
    int? height,
    int? quality,
    String? tag,
    int? index,
  }) {
    return _api.getImageUrl(
      itemId,
      imageType,
      width: width,
      height: height,
      quality: quality,
      tag: tag,
      index: index,
    );
  }

  /// Get item details
  Future<MediaItem> getItemDetails(String itemId) async {
    return await _api.getItem(itemId);
  }

  /// Get library items with pagination (wrapper for getLibraryContent)
  Future<LibraryContent> getLibraryItems(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    return await getLibraryContent(
      libraryId,
      startIndex: startIndex,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchTerm: searchTerm,
    );
  }

  /// Get seasons for a series
  Future<List<MediaItem>> getSeasons(String seriesId) async {
    return await _api.getSeasons(seriesId);
  }

  /// Get episodes for a season
  Future<List<MediaItem>> getEpisodes(String seasonId) async {
    // Note: The Jellyfin API needs seriesId too, but we can get it from the season
    // For now, we pass seasonId as both seriesId and seasonId - the API will filter by seasonId
    return await _api.getEpisodes(seasonId, seasonId: seasonId);
  }

  /// Get similar items
  Future<List<MediaItem>> getSimilarItems(
    String itemId, {
    int limit = 12,
  }) async {
    return await _api.getSimilarItems(itemId, limit: limit);
  }

  /// Get album tracks
  Future<List<MediaItem>> getAlbumTracks(String albumId) async {
    return await _api.getAlbumTracks(albumId);
  }

  /// Get library content (albums for music, regular items otherwise)
  Future<LibraryContent> getMusicLibraryContent(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    final result = await _api.getAlbums(
      parentId: libraryId,
      startIndex: startIndex,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchTerm: searchTerm,
    );

    return LibraryContent(
      items: result.items,
      totalCount: result.totalCount,
      hasMore: result.startIndex + result.items.length < result.totalCount,
    );
  }

  /// Get artists from a music library
  Future<LibraryContent> getMusicArtists(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    final result = await _api.getArtists(
      parentId: libraryId,
      startIndex: startIndex,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchTerm: searchTerm,
    );

    return LibraryContent(
      items: result.items,
      totalCount: result.totalCount,
      hasMore: result.startIndex + result.items.length < result.totalCount,
    );
  }

  /// Get tracks from a music library
  Future<LibraryContent> getMusicTracks(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    final result = await _api.getTracks(
      parentId: libraryId,
      startIndex: startIndex,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchTerm: searchTerm,
    );

    return LibraryContent(
      items: result.items,
      totalCount: result.totalCount,
      hasMore: result.startIndex + result.items.length < result.totalCount,
    );
  }

  /// Server URL
  String? get serverUrl => _api.serverUrl;
}

/// Home screen data
class HomeData {
  final List<MediaItem> continueWatching;
  final List<MediaItem> nextUp;
  final List<MediaItem> recentlyAdded;
  final List<MediaItem> recentlyReleased;
  final List<MediaItem> topRated;
  final List<MediaItem> recommended;
  final List<MediaItem> favorites;
  final List<MediaItem> recentlyAddedMovies;
  final List<MediaItem> recentlyAddedShows;
  final List<Library> libraries;

  const HomeData({
    required this.continueWatching,
    required this.nextUp,
    required this.recentlyAdded,
    required this.recentlyReleased,
    required this.topRated,
    required this.recommended,
    required this.favorites,
    required this.recentlyAddedMovies,
    required this.recentlyAddedShows,
    required this.libraries,
  });
}

/// Library content result
class LibraryContent {
  final List<MediaItem> items;
  final int totalCount;
  final bool hasMore;

  const LibraryContent({
    required this.items,
    required this.totalCount,
    required this.hasMore,
  });
}

/// Movie details
class MovieDetails {
  final MediaItem movie;
  final List<MediaItem> similar;

  const MovieDetails({required this.movie, required this.similar});
}

/// Series details with seasons
class SeriesDetails {
  final MediaItem series;
  final List<MediaItem> seasons;
  final List<MediaItem> similar;
  final MediaItem? nextUp;

  const SeriesDetails({
    required this.series,
    required this.seasons,
    required this.similar,
    this.nextUp,
  });
}

/// Stream information for playback
class StreamInfo {
  final String url;
  final MediaSourceData mediaSource;
  final String? playSessionId;
  final bool isTranscoding;
  final List<MediaStreamData> audioStreams;
  final List<MediaStreamData> subtitleStreams;
  final int? defaultAudioIndex;
  final int? defaultSubtitleIndex;

  const StreamInfo({
    required this.url,
    required this.mediaSource,
    this.playSessionId,
    this.isTranscoding = false,
    this.audioStreams = const [],
    this.subtitleStreams = const [],
    this.defaultAudioIndex,
    this.defaultSubtitleIndex,
  });
}

/// Search results grouped by type
class SearchResults {
  final List<SearchHint> movies;
  final List<SearchHint> series;
  final List<SearchHint> episodes;
  final List<SearchHint> music;
  final List<SearchHint> all;

  const SearchResults({
    required this.movies,
    required this.series,
    required this.episodes,
    required this.music,
    required this.all,
  });

  bool get isEmpty => all.isEmpty;
  bool get isNotEmpty => all.isNotEmpty;
}
