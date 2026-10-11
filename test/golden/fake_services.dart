import 'package:finar/core/api/auth_service.dart';
import 'package:finar/core/api/jellyfin_api.dart';
import 'package:finar/core/api/media_service.dart';
import 'package:finar/core/api/models/library.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/services/download_service.dart';
import 'package:finar/providers/auth_provider.dart';
import 'package:finar/providers/download_provider.dart';
import 'package:finar/providers/player_provider.dart';

import 'golden_fixtures.dart';

class FakeJellyfinApi extends JellyfinApi {
  @override
  String? get serverUrl => goldenServerUrl;

  @override
  Future<List<Library>> getLibraries() async => goldenLibraries;

  @override
  Future<MediaItem> getItem(String itemId) async =>
      goldenMovie(itemId, 'Dune: Part Two');

  @override
  Future<bool> isInWatchlist(String itemId) async => false;
}

class FakeMediaService extends MediaService {
  FakeMediaService() : super(JellyfinApi());

  @override
  Future<HomeData> getHomeData() async => goldenHomeData;

  @override
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
    return LibraryContent(
      items: goldenMovies,
      totalCount: goldenMovies.length,
      hasMore: false,
    );
  }

  @override
  Future<MediaItem> getItemDetails(String itemId) async =>
      goldenMovie(itemId, 'Dune: Part Two');

  @override
  Future<List<MediaItem>> getSeasons(String seriesId) async => const [];

  @override
  Future<List<MediaItem>> getEpisodes(String seasonId) async => goldenEpisodes;

  @override
  Future<List<MediaItem>> getSeasonEpisodes(
    String seriesId,
    String seasonId,
  ) async =>
      goldenEpisodes;

  @override
  Future<List<MediaItem>> getSimilarItems(
    String itemId, {
    int limit = 12,
  }) async =>
      goldenMovies.sublist(1);

  @override
  Future<List<MediaItem>> getAlbumTracks(String albumId) async => goldenTracks;

  @override
  Future<List<MediaItem>> getArtistAlbums(String artistId) async => goldenAlbums;

  @override
  Future<LibraryContent> getMusicLibraryContent(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    return LibraryContent(
      items: goldenAlbums,
      totalCount: goldenAlbums.length,
      hasMore: false,
    );
  }

  @override
  Future<LibraryContent> getMusicArtists(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    return LibraryContent(
      items: goldenArtists,
      totalCount: goldenArtists.length,
      hasMore: false,
    );
  }

  @override
  Future<LibraryContent> getMusicTracks(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    return LibraryContent(
      items: goldenTracks,
      totalCount: goldenTracks.length,
      hasMore: false,
    );
  }

  @override
  Future<SearchResults> search(String query) async => const SearchResults(
    movies: [
      SearchHint(
        itemId: 'movie-1',
        name: 'Dune: Part Two',
        type: 'Movie',
        productionYear: 2024,
      ),
    ],
    series: [
      SearchHint(
        itemId: 'series-1',
        name: 'Dune: Prophecy',
        type: 'Series',
        productionYear: 2024,
      ),
    ],
    episodes: [],
    music: [],
    all: [
      SearchHint(
        itemId: 'movie-1',
        name: 'Dune: Part Two',
        type: 'Movie',
        productionYear: 2024,
      ),
      SearchHint(
        itemId: 'series-1',
        name: 'Dune: Prophecy',
        type: 'Series',
        productionYear: 2024,
      ),
    ],
  );
}

class FakeAuthService extends AuthService {
  FakeAuthService({this.profiles = const []}) : super(JellyfinApi());

  final List<SavedProfile> profiles;

  @override
  Future<void> init() async {}

  @override
  List<SavedProfile> get savedProfiles => profiles;

  @override
  Future<bool> connectToServer(String url) async => true;

  @override
  Future<void> removeProfile(SavedProfile profile) async {}
}

class GoldenAuthNotifier extends AuthNotifier {
  GoldenAuthNotifier(
    super.authService,
    super.api,
    AuthState seed,
  ) {
    state = seed;
  }

  @override
  Future<void> initialize() async {}
}

class FakeDownloadService extends DownloadService {
  FakeDownloadService({List<DownloadTask> downloads = const []})
    : _downloads = downloads,
      super(JellyfinApi());

  final List<DownloadTask> _downloads;

  @override
  Future<void> init() async {}

  @override
  List<DownloadTask> get downloads => _downloads;

  @override
  Stream<DownloadTask> get progressStream => const Stream<DownloadTask>.empty();

  @override
  void dispose() {}
}

class FakeDownloadNotifier extends DownloadNotifier {
  FakeDownloadNotifier({List<DownloadTask> downloads = const []})
    : super(FakeDownloadService(downloads: downloads));
}

class GoldenPlayerNotifier extends PlayerNotifier {
  GoldenPlayerNotifier(
    super.mediaService,
    super.downloadService,
    PlayerState seed,
  ) : super.uninitialized() {
    state = seed;
  }
}
