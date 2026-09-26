import 'package:dio/dio.dart';

import 'models.dart';

class JellyfinClient {
  final Dio _dio;
  final String deviceName;
  final String deviceId;
  String clientVersion;

  String? serverUrl;
  String? accessToken;
  String? userId;

  static const clientName = 'Finar';

  JellyfinClient({
    Dio? dio,
    this.deviceName = 'Finar',
    required this.deviceId,
    this.clientVersion = '1.0.0',
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Jellyfin 10.9+ wants Authorization; older servers and Emby
        // still read X-Emby-Authorization. Send both.
        options.headers['Authorization'] = authHeader;
        options.headers['X-Emby-Authorization'] = authHeader;
        handler.next(options);
      },
    ));
  }

  String get authHeader {
    final parts = [
      'MediaBrowser Client="$clientName"',
      'Device="$deviceName"',
      'DeviceId="$deviceId"',
      'Version="${clientVersion.isEmpty ? '1.0.0' : clientVersion}"',
      if (accessToken != null) 'Token="$accessToken"',
    ];
    return parts.join(', ');
  }

  bool get isAuthenticated => accessToken != null && userId != null;

  void setServerUrl(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    serverUrl = u;
    _dio.options.baseUrl = u;
  }

  void setCredentials({required String accessToken, required String userId}) {
    this.accessToken = accessToken;
    this.userId = userId;
  }

  void clearCredentials() {
    accessToken = null;
    userId = null;
  }

  // --- Server ---

  Future<ServerInfo> getServerInfo() async {
    final res = await _dio.get('/System/Info/Public');
    return ServerInfo.fromJson(
        res.data as Map<String, dynamic>, serverUrl ?? '');
  }

  Future<ServerInfo> testConnection(String url) async {
    setServerUrl(url);
    return getServerInfo();
  }

  Future<List<JfUser>> getPublicUsers() async {
    final res = await _dio.get('/Users/Public');
    return (res.data as List<dynamic>)
        .map((e) => JfUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AuthResult> authenticate(String username, String password) async {
    final res = await _dio.post(
      '/Users/AuthenticateByName',
      data: {'Username': username, 'Pw': password},
    );
    final result =
        AuthResult.fromJson(res.data as Map<String, dynamic>);
    setCredentials(
        accessToken: result.accessToken, userId: result.user.id);
    return result;
  }

  Future<String> initiateQuickConnect() async {
    final res = await _dio.get('/QuickConnect/Initiate');
    return res.data['Code'] as String;
  }

  Future<AuthResult?> checkQuickConnect(String secret) async {
    final res = await _dio.get('/QuickConnect/Connect',
        queryParameters: {'secret': secret});
    if (res.data['Authenticated'] != true) return null;
    final token = res.data['AccessToken'] as String;
    final me = await _dio.get('/Users/Me',
        queryParameters: {'api_key': token});
    final user = JfUser.fromJson(me.data as Map<String, dynamic>);
    setCredentials(accessToken: token, userId: user.id);
    return AuthResult(
      user: user,
      accessToken: token,
      serverId: res.data['ServerId'] as String? ?? '',
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post('/Sessions/Logout');
    } finally {
      clearCredentials();
    }
  }

  // --- Library ---

  Future<List<JfLibrary>> getLibraries() async {
    final res = await _dio.get('/Users/$userId/Views');
    return (res.data['Items'] as List<dynamic>)
        .map((e) => JfLibrary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ItemsResult> getItems({
    String? parentId,
    List<String>? includeItemTypes,
    List<String>? excludeItemTypes,
    int? startIndex,
    int? limit,
    String? sortBy,
    String? sortOrder,
    bool? recursive,
    List<String>? fields,
    List<String>? filters,
    String? searchTerm,
    String? ids,
    bool? isFavorite,
    String? genres,
    String? personIds,
    String? mediaTypes,
  }) async {
    final res = await _dio.get(
      '/Users/$userId/Items',
      queryParameters: {
        if (parentId != null) 'ParentId': parentId,
        if (includeItemTypes != null)
          'IncludeItemTypes': includeItemTypes.join(','),
        if (excludeItemTypes != null)
          'ExcludeItemTypes': excludeItemTypes.join(','),
        if (startIndex != null) 'StartIndex': startIndex,
        if (limit != null) 'Limit': limit,
        if (sortBy != null) 'SortBy': sortBy,
        if (sortOrder != null) 'SortOrder': sortOrder,
        if (recursive != null) 'Recursive': recursive,
        if (fields != null) 'Fields': fields.join(','),
        if (filters != null) 'Filters': filters.join(','),
        if (searchTerm != null) 'SearchTerm': searchTerm,
        if (ids != null) 'Ids': ids,
        if (isFavorite != null) 'IsFavorite': isFavorite,
        if (genres != null) 'Genres': genres,
        if (personIds != null) 'PersonIds': personIds,
        if (mediaTypes != null) 'MediaTypes': mediaTypes,
      },
    );
    return parseItemsResult(res.data as Map<String, dynamic>);
  }

  Future<MediaItem> getItem(String itemId) async {
    final res = await _dio.get(
      '/Users/$userId/Items/$itemId',
      queryParameters: const {
        'Fields':
            'Overview,People,Genres,MediaStreams,Chapters,MediaSources',
      },
    );
    return MediaItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<MediaItem>> getSimilar(String itemId, {int limit = 12}) async {
    final res = await _dio.get(
      '/Items/$itemId/Similar',
      queryParameters: {
        'UserId': userId,
        'Limit': limit,
        'Fields': 'Overview',
      },
    );
    return parseItemList(res.data['Items'] as List<dynamic>);
  }

  Future<List<MediaItem>> getResume({int limit = 12}) async {
    final res = await _dio.get(
      '/Users/$userId/Items/Resume',
      queryParameters: {
        'Limit': limit,
        'Recursive': true,
        'MediaTypes': 'Video',
        'Fields': 'Overview',
      },
    );
    return parseItemList(res.data['Items'] as List<dynamic>);
  }

  Future<List<MediaItem>> getLatest({
    String? parentId,
    int limit = 16,
    List<String>? includeItemTypes,
  }) async {
    final res = await _dio.get(
      '/Users/$userId/Items/Latest',
      queryParameters: {
        if (parentId != null) 'ParentId': parentId,
        'Limit': limit,
        'Fields': 'Overview',
        if (includeItemTypes != null)
          'IncludeItemTypes': includeItemTypes.join(','),
      },
    );
    return parseItemList(res.data as List<dynamic>);
  }

  Future<List<MediaItem>> getNextUp({int limit = 12, String? seriesId}) async {
    final res = await _dio.get(
      '/Shows/NextUp',
      queryParameters: {
        'UserId': userId,
        'Limit': limit,
        'Fields': 'Overview',
        if (seriesId != null) 'SeriesId': seriesId,
      },
    );
    return parseItemList(res.data['Items'] as List<dynamic>);
  }

  Future<List<MediaItem>> getSuggestions({int limit = 16}) async {
    final res = await _dio.get(
      '/Users/$userId/Suggestions',
      queryParameters: {'Limit': limit, 'Fields': 'Overview'},
    );
    final items =
        parseItemList(res.data['Items'] as List<dynamic>? ?? []);
    return items.where((i) => !i.isContainer).toList();
  }

  Future<List<Genre>> getGenres({List<String>? includeItemTypes}) async {
    final res = await _dio.get(
      '/Genres',
      queryParameters: {
        'UserId': userId,
        if (includeItemTypes != null)
          'IncludeItemTypes': includeItemTypes.join(','),
        'SortBy': 'SortName',
      },
    );
    return (res.data['Items'] as List<dynamic>)
        .map((e) => Genre.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MediaItem>> getSeasons(String seriesId) async {
    final res = await _dio.get(
      '/Shows/$seriesId/Seasons',
      queryParameters: {'UserId': userId, 'Fields': 'Overview'},
    );
    return parseItemList(res.data['Items'] as List<dynamic>);
  }

  Future<List<MediaItem>> getEpisodes(String seriesId,
      {String? seasonId}) async {
    final res = await _dio.get(
      '/Shows/$seriesId/Episodes',
      queryParameters: {
        'UserId': userId,
        if (seasonId != null) 'SeasonId': seasonId,
        'Fields': 'Overview,MediaSources',
      },
    );
    return parseItemList(res.data['Items'] as List<dynamic>);
  }

  Future<List<SearchHint>> search(String query, {int limit = 24}) async {
    final res = await _dio.get(
      '/Search/Hints',
      queryParameters: {
        'SearchTerm': query,
        'Limit': limit,
        'UserId': userId,
        'IncludeItemTypes':
            'Movie,Series,Episode,Audio,MusicAlbum,MusicArtist,Person',
      },
    );
    return (res.data['SearchHints'] as List<dynamic>)
        .map((e) => SearchHint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- Playback ---

  Future<PlaybackInfo> getPlaybackInfo(
    String itemId, {
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? startTimeTicks,
    int? maxStreamingBitrate,
    String? mediaSourceId,
  }) async {
    final res = await _dio.post(
      '/Items/$itemId/PlaybackInfo',
      queryParameters: {
        'UserId': userId,
        if (audioStreamIndex != null)
          'AudioStreamIndex': audioStreamIndex,
        if (subtitleStreamIndex != null)
          'SubtitleStreamIndex': subtitleStreamIndex,
        if (startTimeTicks != null) 'StartTimeTicks': startTimeTicks,
        if (maxStreamingBitrate != null)
          'MaxStreamingBitrate': maxStreamingBitrate,
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      },
      data: {'DeviceProfile': deviceProfile},
    );
    return PlaybackInfo.fromJson(res.data as Map<String, dynamic>);
  }

  String streamUrl(
    String itemId, {
    String? mediaSourceId,
    String? container,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? startTimeTicks,
  }) {
    final params = <String, String>{
      'api_key': accessToken ?? '',
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (container != null) 'Container': container,
      if (audioStreamIndex != null)
        'AudioStreamIndex': '$audioStreamIndex',
      if (subtitleStreamIndex != null)
        'SubtitleStreamIndex': '$subtitleStreamIndex',
      if (startTimeTicks != null) 'StartTimeTicks': '$startTimeTicks',
      'Static': 'true',
    };
    return '$serverUrl/Videos/$itemId/stream?${Uri(queryParameters: params).query}';
  }

  String hlsUrl(
    String itemId, {
    String? mediaSourceId,
    String? playSessionId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? maxBitrate,
    int? startTimeTicks,
  }) {
    final params = <String, String>{
      'api_key': accessToken ?? '',
      'DeviceId': deviceId,
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (playSessionId != null) 'PlaySessionId': playSessionId,
      if (audioStreamIndex != null)
        'AudioStreamIndex': '$audioStreamIndex',
      if (subtitleStreamIndex != null)
        'SubtitleStreamIndex': '$subtitleStreamIndex',
      if (maxBitrate != null) 'MaxStreamingBitrate': '$maxBitrate',
      if (startTimeTicks != null) 'StartTimeTicks': '$startTimeTicks',
      'TranscodingMaxAudioChannels': '6',
      'SegmentContainer': 'ts',
      'MinSegments': '2',
    };
    return '$serverUrl/Videos/$itemId/master.m3u8?${Uri(queryParameters: params).query}';
  }

  String audioStreamUrl(String itemId) =>
      '$serverUrl/Audio/$itemId/stream?api_key=$accessToken&static=true';

  String subtitleUrl(
          String itemId, String mediaSourceId, int index, String format) =>
      '$serverUrl/Videos/$itemId/$mediaSourceId/Subtitles/$index/Stream.$format?api_key=$accessToken';

  String imageUrl(
    String itemId,
    String type, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
    String? tag,
    int? index,
  }) {
    final params = <String, String>{
      if (maxWidth != null) 'maxWidth': '$maxWidth',
      if (maxHeight != null) 'maxHeight': '$maxHeight',
      if (quality != null) 'quality': '$quality',
      if (tag != null) 'tag': tag,
    };
    final i = index != null ? '/$index' : '';
    return '$serverUrl/Items/$itemId/Images/$type$i?${Uri(queryParameters: params).query}';
  }

  /// Poster for display. Episodes fall back to their series poster.
  String posterUrl(MediaItem item, {int? maxWidth, int quality = 90}) {
    if (item.kind == MediaKind.episode) {
      if (item.seriesId != null && item.seriesPrimaryImageTag != null) {
        return imageUrl(item.seriesId!, 'Primary',
            maxWidth: maxWidth,
            quality: quality,
            tag: item.seriesPrimaryImageTag);
      }
      if (item.imageTags.primary != null) {
        return imageUrl(item.id, 'Primary',
            maxWidth: maxWidth, quality: quality, tag: item.imageTags.primary);
      }
      return '';
    }
    final tag = item.imageTags.primary;
    if (tag == null) return '';
    return imageUrl(item.id, 'Primary',
        maxWidth: maxWidth, quality: quality, tag: tag);
  }

  String thumbUrl(MediaItem item, {int? maxWidth, int quality = 85}) {
    if (item.imageTags.thumb != null) {
      return imageUrl(item.id, 'Thumb',
          maxWidth: maxWidth, quality: quality, tag: item.imageTags.thumb);
    }
    if (item.imageTags.primary != null) {
      return imageUrl(item.id, 'Primary',
          maxWidth: maxWidth, quality: quality, tag: item.imageTags.primary);
    }
    return backdropUrl(item, maxWidth: maxWidth, quality: quality);
  }

  String backdropUrl(MediaItem item,
      {int index = 0, int? maxWidth, int quality = 85}) {
    String? tag;
    var id = item.id;
    if (item.backdropImageTags.isNotEmpty) {
      tag = item
          .backdropImageTags[index.clamp(0, item.backdropImageTags.length - 1)];
    } else if (item.parentBackdropImageTags.isNotEmpty &&
        item.parentBackdropItemId != null) {
      tag = item.parentBackdropImageTags[
          index.clamp(0, item.parentBackdropImageTags.length - 1)];
      id = item.parentBackdropItemId!;
    }
    if (tag == null) return '';
    return imageUrl(id, 'Backdrop',
        maxWidth: maxWidth, quality: quality, tag: tag, index: index);
  }

  String personImageUrl(Person person, {int? maxWidth}) {
    if (person.primaryImageTag == null) return '';
    return imageUrl(person.id, 'Primary',
        maxWidth: maxWidth, tag: person.primaryImageTag);
  }

  String userImageUrl(JfUser user, {int? maxWidth}) {
    if (user.primaryImageTag == null) return '';
    return imageUrl(user.id, 'Primary',
        maxWidth: maxWidth, tag: user.primaryImageTag);
  }

  // --- Playback reporting ---

  Future<void> reportStart(String itemId,
      {String? mediaSourceId,
      String? playSessionId,
      int positionTicks = 0,
      bool isPaused = false}) async {
    await _dio.post('/Sessions/Playing', data: {
      'ItemId': itemId,
      'MediaSourceId': mediaSourceId,
      'PlaySessionId': playSessionId,
      'PositionTicks': positionTicks,
      'IsPaused': isPaused,
      'CanSeek': true,
      'PlayMethod': 'DirectPlay',
    });
  }

  Future<void> reportProgress(String itemId,
      {String? mediaSourceId,
      String? playSessionId,
      required int positionTicks,
      bool isPaused = false}) async {
    await _dio.post('/Sessions/Playing/Progress', data: {
      'ItemId': itemId,
      'MediaSourceId': mediaSourceId,
      'PlaySessionId': playSessionId,
      'PositionTicks': positionTicks,
      'IsPaused': isPaused,
      'CanSeek': true,
      'PlayMethod': 'DirectPlay',
    });
  }

  Future<void> reportStop(String itemId,
      {String? mediaSourceId,
      String? playSessionId,
      required int positionTicks}) async {
    await _dio.post('/Sessions/Playing/Stopped', data: {
      'ItemId': itemId,
      'MediaSourceId': mediaSourceId,
      'PlaySessionId': playSessionId,
      'PositionTicks': positionTicks,
    });
  }

  // --- User data ---

  Future<void> markPlayed(String itemId) =>
      _dio.post('/Users/$userId/PlayedItems/$itemId');

  Future<void> markUnplayed(String itemId) =>
      _dio.delete('/Users/$userId/PlayedItems/$itemId');

  Future<void> setFavorite(String itemId, bool favorite) => favorite
      ? _dio.post('/Users/$userId/FavoriteItems/$itemId')
      : _dio.delete('/Users/$userId/FavoriteItems/$itemId');

  Future<List<MediaItem>> getPlaylists() async =>
      (await getItems(
        includeItemTypes: ['Playlist'],
        recursive: true,
        sortBy: 'SortName',
      ))
          .items;

  Future<MediaItem?> getOrCreateWatchlist() async {
    final playlists = await getPlaylists();
    for (final p in playlists) {
      final n = p.name.toLowerCase();
      if (n == 'watchlist' || n == 'watch list') return p;
    }
    final res = await _dio.post('/Playlists',
        queryParameters: {'Name': 'Watchlist', 'UserId': userId});
    final id = res.data['Id'] as String?;
    if (id == null) return null;
    return (await getItems(ids: id)).items.firstOrNull;
  }

  Future<List<MediaItem>> getPlaylistItems(String playlistId) async {
    final res = await _dio.get(
      '/Playlists/$playlistId/Items',
      queryParameters: {'UserId': userId, 'Fields': 'Overview'},
    );
    return parseItemList(res.data['Items'] as List<dynamic>? ?? []);
  }

  Future<void> addToPlaylist(String playlistId, String itemId) =>
      _dio.post('/Playlists/$playlistId/Items',
          queryParameters: {'Ids': itemId, 'UserId': userId});

  Future<void> removeFromPlaylist(String playlistId, String entryId) =>
      _dio.delete('/Playlists/$playlistId/Items',
          queryParameters: {'EntryIds': entryId});

  // --- Device profile ---

  Map<String, dynamic> get deviceProfile => {
        'Name': clientName,
        'MaxStreamingBitrate': 120000000,
        'MusicStreamingTranscodingBitrate': 384000,
        'DirectPlayProfiles': [
          {
            'Container': 'mp4,m4v,mkv,webm,mov,avi,wmv,ts,m2ts',
            'Type': 'Video',
            'VideoCodec': 'h264,hevc,vp8,vp9,av1,mpeg2video',
            'AudioCodec': 'aac,mp3,opus,flac,vorbis,ac3,eac3,dts,truehd',
          },
          {
            'Container':
                'mp3,flac,opus,aac,m4a,ogg,webm,wav,wma,alac',
            'Type': 'Audio',
          },
        ],
        'TranscodingProfiles': [
          {
            'Container': 'ts',
            'Type': 'Video',
            'AudioCodec': 'aac,mp3',
            'VideoCodec': 'h264',
            'Context': 'Streaming',
            'Protocol': 'hls',
            'MaxAudioChannels': '6',
            'MinSegments': '2',
            'BreakOnNonKeyFrames': true,
          },
          {
            'Container': 'mp3',
            'Type': 'Audio',
            'AudioCodec': 'mp3',
            'Context': 'Streaming',
            'Protocol': 'http',
          },
        ],
        'SubtitleProfiles': [
          {'Format': 'srt', 'Method': 'External'},
          {'Format': 'vtt', 'Method': 'External'},
          {'Format': 'ass', 'Method': 'External'},
          {'Format': 'ssa', 'Method': 'External'},
        ],
        'CodecProfiles': [
          {
            'Type': 'Video',
            'Codec': 'h264',
            'Conditions': [
              {
                'Condition': 'LessThanEqual',
                'Property': 'VideoBitDepth',
                'Value': '10',
              },
            ],
          },
        ],
        'ContainerProfiles': <Map<String, dynamic>>[],
      };
}
