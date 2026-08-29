import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/jellyfin_api.dart';
import '../core/api/models/media_item.dart';
import 'auth_provider.dart';
import 'library_provider.dart';

/// Provider for media item detail - cached for 5 minutes
final mediaItemDetailProvider = FutureProvider.family<MediaItem, String>((
  ref,
  itemId,
) async {
  // Keep alive for 5 minutes to avoid re-fetching
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());

  final mediaService = ref.watch(mediaServiceProvider);
  return mediaService.getItemDetails(itemId);
});

/// Provider for album tracks - cached for 5 minutes
final albumTracksProvider = FutureProvider.family<List<MediaItem>, String>((
  ref,
  albumId,
) async {
  // Keep alive for 5 minutes to avoid re-fetching
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());

  final mediaService = ref.watch(mediaServiceProvider);
  return mediaService.getAlbumTracks(albumId);
});

final artistAlbumsProvider = FutureProvider.family<List<MediaItem>, String>((
  ref,
  artistId,
) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());

  final mediaService = ref.watch(mediaServiceProvider);
  return mediaService.getArtistAlbums(artistId);
});

/// Provider for seasons of a series - cached for 5 minutes
final seasonsProvider = FutureProvider.family<List<MediaItem>, String>((
  ref,
  seriesId,
) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());

  final mediaService = ref.watch(mediaServiceProvider);
  return mediaService.getSeasons(seriesId);
});

/// Provider for episodes of a season - cached for 5 minutes
final episodesProvider = FutureProvider.family<List<MediaItem>, String>((
  ref,
  seasonId,
) async {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () => link.close());

  final mediaService = ref.watch(mediaServiceProvider);
  return mediaService.getEpisodes(seasonId);
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

/// Provider to check if an item is in the watchlist
final isInWatchlistProvider = FutureProvider.family<bool, String>((ref, itemId) async {
  final api = ref.watch(jellyfinApiProvider);
  return api.isInWatchlist(itemId);
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
  Future<void> markEpisodeWatched(
    String episodeId,
    String seasonId,
    bool isWatched,
  ) async {
    await _api.setWatched(episodeId, isWatched);
    // Invalidate both the episode detail and episodes list
    _ref.invalidate(mediaItemDetailProvider(episodeId));
    _ref.invalidate(episodesProvider(seasonId));
  }

  /// Toggle watchlist status for an item
  Future<bool> toggleWatchlist(String itemId) async {
    final result = await _api.toggleWatchlist(itemId);
    _ref.invalidate(isInWatchlistProvider(itemId));
    _ref.invalidate(homeDataProvider);
    _ref.read(libraryProvider.notifier).loadHomeData();
    return result;
  }

  /// Add item to watchlist
  Future<void> addToWatchlist(String itemId) async {
    await _api.addToWatchlist(itemId);
    _ref.invalidate(isInWatchlistProvider(itemId));
    _ref.invalidate(homeDataProvider);
    _ref.read(libraryProvider.notifier).loadHomeData();
  }

  /// Remove item from watchlist
  Future<void> removeFromWatchlist(String itemId) async {
    await _api.removeFromWatchlist(itemId);
    _ref.invalidate(isInWatchlistProvider(itemId));
    _ref.invalidate(homeDataProvider);
    _ref.read(libraryProvider.notifier).loadHomeData();
  }
}
