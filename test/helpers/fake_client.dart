import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/models/models.dart';

class FakeJellyfinClient extends JellyfinClient {
  FakeJellyfinClient()
      : super(serverUrl: 'http://test.local', deviceId: 'test-device');

  PublicSystemInfo systemInfo = const PublicSystemInfo(
      serverName: 'Test Server', version: '10.9.11', id: 'srv1');
  List<BaseItem> libraries = [];
  Map<String, BaseItem> items = {};
  List<BaseItem> resume = [];
  List<BaseItem> nextUp = [];
  Map<String, List<BaseItem>> latest = {};
  Map<String, List<BaseItem>> similar = {};
  Map<String, List<BaseItem>> seasons = {};
  Map<String, List<BaseItem>> episodes = {};
  Map<String, List<BaseItem>> children = {};
  List<BaseItem> searchResults = [];
  List<BaseItem> favorites = [];
  List<BaseItem> genreItems = [];
  AuthResult? authResult;
  bool quickConnectAvailable = true;
  int favoriteCalls = 0;
  int playedCalls = 0;
  final List<String> playbackEvents = [];

  @override
  Future<PublicSystemInfo> getPublicSystemInfo() async => systemInfo;

  @override
  Future<AuthResult> authenticateByName(
      String username, String password) async {
    final result = authResult;
    if (result == null) {
      throw const JellyfinException('bad login', statusCode: 401);
    }
    return result;
  }

  @override
  Future<bool> quickConnectEnabled() async => quickConnectAvailable;

  @override
  Future<QuickConnectResult> quickConnectInitiate() async =>
      const QuickConnectResult(code: 'AB12CD', secret: 'sec');

  @override
  Future<ItemsResult> getUserViews() async =>
      ItemsResult(items: libraries, totalRecordCount: libraries.length);

  @override
  Future<BaseItem> getItem(String id) async {
    final item = items[id];
    if (item == null) {
      throw const JellyfinException('not found', statusCode: 404);
    }
    return item;
  }

  @override
  Future<ItemsResult> getItems({
    String? parentId,
    List<String>? includeItemTypes,
    List<String>? sortBy,
    String sortOrder = 'Ascending',
    List<String>? filters,
    String? searchTerm,
    int? limit,
    int startIndex = 0,
    bool recursive = true,
    List<String>? fields,
    String? genres,
    String? artistIds,
    String? excludeItemTypes,
  }) async {
    List<BaseItem> source;
    if (searchTerm != null && searchTerm.isNotEmpty) {
      source = searchResults;
    } else if (filters?.contains('IsFavorite') ?? false) {
      source = favorites;
    } else if (includeItemTypes?.contains('Genre') ?? false) {
      source = genreItems;
    } else if (parentId != null) {
      source = children[parentId] ?? const [];
    } else {
      source = items.values.toList();
    }
    final sliced = source.skip(startIndex).take(limit ?? 60).toList();
    return ItemsResult(
        items: sliced,
        totalRecordCount: source.length,
        startIndex: startIndex);
  }

  @override
  Future<ItemsResult> getResumeItems({int limit = 20}) async =>
      ItemsResult(items: resume, totalRecordCount: resume.length);

  @override
  Future<ItemsResult> getLatestMedia(
          {String? parentId, int limit = 16}) async =>
      ItemsResult(
          items: latest[parentId] ?? const [],
          totalRecordCount: (latest[parentId] ?? const []).length);

  @override
  Future<ItemsResult> getNextUp(
          {String? seriesId, int limit = 24}) async =>
      ItemsResult(items: nextUp, totalRecordCount: nextUp.length);

  @override
  Future<ItemsResult> getSimilar(String itemId, {int limit = 12}) async =>
      ItemsResult(
          items: similar[itemId] ?? const [],
          totalRecordCount: (similar[itemId] ?? const []).length);

  @override
  Future<ItemsResult> getSeasons(String seriesId) async => ItemsResult(
      items: seasons[seriesId] ?? const [],
      totalRecordCount: (seasons[seriesId] ?? const []).length);

  @override
  Future<ItemsResult> getEpisodes(String seriesId,
          {String? seasonId}) async =>
      ItemsResult(
          items: episodes['$seriesId|${seasonId ?? ''}'] ?? const [],
          totalRecordCount:
              (episodes['$seriesId|${seasonId ?? ''}'] ?? const []).length);

  @override
  Future<UserData> setFavorite(String itemId, bool favorite) async {
    favoriteCalls++;
    return UserData(isFavorite: favorite);
  }

  @override
  Future<UserData> setPlayed(String itemId, bool played) async {
    playedCalls++;
    return UserData(played: played);
  }

  @override
  Future<void> reportPlaybackStart(BaseItem item,
      {int positionTicks = 0}) async {
    playbackEvents.add('start:${item.id}');
  }

  @override
  Future<void> reportPlaybackProgress(BaseItem item,
      {required int positionTicks, bool isPaused = false}) async {
    playbackEvents.add('progress:${item.id}');
  }

  @override
  Future<void> reportPlaybackStopped(BaseItem item,
      {required int positionTicks}) async {
    playbackEvents.add('stop:${item.id}');
  }

  @override
  Uri? primaryImageUrl(BaseItem item,
          {int? maxWidth, int? maxHeight}) =>
      item.primaryImageTag == null
          ? null
          : Uri.parse('$serverUrl/Items/${item.id}/Images/Primary');

  @override
  Uri? backdropImageUrl(BaseItem item, {int? maxWidth}) =>
      Uri.parse('$serverUrl/Items/${item.effectiveBackdropId}/Images/Backdrop');

  @override
  Uri? userImageUrl(JellyfinUser user, {int? maxWidth}) =>
      Uri.parse('$serverUrl/Users/${user.id}/Images/Primary');

  @override
  Uri streamUrl(String itemId, {bool isAudio = false}) =>
      Uri.parse('$serverUrl/stream/$itemId');
}

BaseItem makeItem({
  String id = 'item1',
  String name = 'Item',
  String type = 'Movie',
  int? year = 2024,
  int? runTimeTicks = 72000000000,
  double? rating = 7.5,
  String? overview = 'A story.',
  List<String> genres = const [],
  String? imageTag = 'tag',
  String? backdropTag = 'bd',
  String? seriesName,
  String? seriesId,
  String? albumArtist,
  int? indexNumber,
  int? parentIndexNumber,
  bool played = false,
  bool favorite = false,
  int positionTicks = 0,
  String? collectionType,
  bool isFolder = false,
  List<Person> people = const [],
  int? childCount,
}) =>
    BaseItem(
      id: id,
      name: name,
      type: type,
      serverId: 'srv1',
      overview: overview,
      productionYear: year,
      runTimeTicks: runTimeTicks,
      communityRating: rating,
      officialRating: 'PG-13',
      genres: genres,
      imageTags: {'Primary': ?imageTag},
      backdropImageTags:
          backdropTag == null ? const [] : [backdropTag],
      seriesName: seriesName,
      seriesId: seriesId,
      albumArtist: albumArtist,
      indexNumber: indexNumber,
      parentIndexNumber: parentIndexNumber,
      collectionType: collectionType,
      isFolder: isFolder,
      people: people,
      childCount: childCount,
      userData: UserData(
          played: played,
          isFavorite: favorite,
          playbackPositionTicks: positionTicks),
      mediaSources: const [
        MediaSource(
          id: 'ms1',
          container: 'mkv',
          mediaStreams: [
            MediaStream(
                index: 0, type: 'Video', codec: 'h264'),
            MediaStream(
                index: 1,
                type: 'Audio',
                codec: 'aac',
                language: 'eng',
                displayTitle: 'English'),
            MediaStream(
                index: 2,
                type: 'Subtitle',
                codec: 'srt',
                language: 'eng',
                displayTitle: 'English'),
          ],
        ),
      ],
    );
