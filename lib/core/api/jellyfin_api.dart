import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'models/user.dart';
import 'models/media_item.dart';
import 'models/library.dart';
import 'models/playback_info.dart';

/// Main Jellyfin API client
class JellyfinApi {
  late final Dio _dio;
  final String _clientName = 'Finar';
  final String _clientVersion = '1.0.0';
  final String _deviceName;
  final String _deviceId;

  String? _serverUrl;
  String? _accessToken;
  String? _userId;

  JellyfinApi({
    String? deviceName,
    String? deviceId,
  })  : _deviceName = deviceName ?? _getDefaultDeviceName(),
        _deviceId = deviceId ?? const Uuid().v4() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-Emby-Authorization'] = _buildAuthHeader();
        return handler.next(options);
      },
      onError: (error, handler) {
        // Only log non-401 errors in debug mode (401 is expected for auth checks)
        if (kDebugMode && error.response?.statusCode != 401) {
          print('Jellyfin API Error: ${error.response?.statusCode} - ${error.message}');
        }
        return handler.next(error);
      },
    ));
  }

  static String _getDefaultDeviceName() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'Finar Client';
    }
  }

  String _buildAuthHeader() {
    final parts = [
      'MediaBrowser Client="$_clientName"',
      'Device="$_deviceName"',
      'DeviceId="$_deviceId"',
      'Version="$_clientVersion"',
    ];

    if (_accessToken != null) {
      parts.add('Token="$_accessToken"');
    }

    return parts.join(', ');
  }

  /// Configure server URL
  void setServerUrl(String url) {
    _serverUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _dio.options.baseUrl = _serverUrl!;
  }

  /// Set authentication credentials
  void setCredentials({
    required String accessToken,
    required String userId,
  }) {
    _accessToken = accessToken;
    _userId = userId;
  }

  /// Clear authentication
  void clearCredentials() {
    _accessToken = null;
    _userId = null;
  }

  /// Get server info
  Future<ServerInfo> getServerInfo() async {
    final response = await _dio.get('/System/Info/Public');
    return ServerInfo.fromJson(response.data as Map<String, dynamic>, _serverUrl!);
  }

  /// Test connection to server
  Future<bool> testConnection(String serverUrl) async {
    try {
      setServerUrl(serverUrl);
      await _dio.get('/System/Info/Public');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get public users for login
  Future<List<User>> getPublicUsers() async {
    final response = await _dio.get('/Users/Public');
    return (response.data as List<dynamic>)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Authenticate with username and password
  Future<AuthenticationResult> authenticate({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      '/Users/AuthenticateByName',
      data: {
        'Username': username,
        'Pw': password,
      },
    );

    final result = AuthenticationResult.fromJson(
      response.data as Map<String, dynamic>,
      _serverUrl!,
    );

    setCredentials(
      accessToken: result.accessToken,
      userId: result.user.id,
    );

    return result;
  }

  /// Authenticate with quick connect
  Future<String> initiateQuickConnect() async {
    final response = await _dio.get('/QuickConnect/Initiate');
    return response.data['Code'] as String;
  }

  /// Check quick connect status
  Future<AuthenticationResult?> checkQuickConnect(String secret) async {
    final response = await _dio.get('/QuickConnect/Connect', queryParameters: {
      'secret': secret,
    });

    if (response.data['Authenticated'] == true) {
      final accessToken = response.data['AccessToken'] as String;
      final userResponse = await _dio.get(
        '/Users/Me',
        options: Options(headers: {
          'X-Emby-Token': accessToken,
        }),
      );

      final user = User.fromJson(userResponse.data as Map<String, dynamic>);
      
      setCredentials(
        accessToken: accessToken,
        userId: user.id,
      );

      return AuthenticationResult(
        user: user,
        accessToken: accessToken,
        serverId: response.data['ServerId'] as String? ?? '',
        serverUrl: _serverUrl!,
      );
    }

    return null;
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _dio.post('/Sessions/Logout');
    } finally {
      clearCredentials();
    }
  }

  /// Get current user info
  Future<User> getCurrentUser() async {
    final response = await _dio.get('/Users/$_userId');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get user libraries
  Future<List<Library>> getLibraries() async {
    final response = await _dio.get('/Users/$_userId/Views');
    return (response.data['Items'] as List<dynamic>)
        .map((e) => Library.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get items from a library or folder
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
    String? years,
    String? personIds,
    String? studioIds,
  }) async {
    final queryParams = <String, dynamic>{
      if (parentId != null) 'parentId': parentId,
      if (includeItemTypes != null) 'IncludeItemTypes': includeItemTypes.join(','),
      if (excludeItemTypes != null) 'ExcludeItemTypes': excludeItemTypes.join(','),
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
      if (years != null) 'Years': years,
      if (personIds != null) 'PersonIds': personIds,
      if (studioIds != null) 'StudioIds': studioIds,
    };

    final response = await _dio.get(
      '/Users/$_userId/Items',
      queryParameters: queryParams,
    );

    return ItemsResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get a single item by ID
  Future<MediaItem> getItem(String itemId) async {
    final response = await _dio.get(
      '/Users/$_userId/Items/$itemId',
      queryParameters: {
        'Fields': 'Overview,People,Genres,MediaStreams,Chapters,Path,MediaSources',
      },
    );
    return MediaItem.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get similar items
  Future<List<MediaItem>> getSimilarItems(String itemId, {int limit = 12}) async {
    final response = await _dio.get(
      '/Items/$itemId/Similar',
      queryParameters: {
        'UserId': _userId,
        'Limit': limit,
        'Fields': 'Overview',
      },
    );
    return (response.data['Items'] as List<dynamic>)
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get continue watching items
  Future<List<MediaItem>> getContinueWatching({int limit = 12}) async {
    final response = await _dio.get(
      '/Users/$_userId/Items/Resume',
      queryParameters: {
        'Limit': limit,
        'Recursive': true,
        'MediaTypes': 'Video',
        'Fields': 'Overview',
      },
    );
    return (response.data['Items'] as List<dynamic>)
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get recently added items
  Future<List<MediaItem>> getRecentlyAdded({
    String? parentId,
    int limit = 16,
    List<String>? includeItemTypes,
  }) async {
    final response = await _dio.get(
      '/Users/$_userId/Items/Latest',
      queryParameters: {
        if (parentId != null) 'ParentId': parentId,
        'Limit': limit,
        'Fields': 'Overview',
        if (includeItemTypes != null) 'IncludeItemTypes': includeItemTypes.join(','),
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get next up episodes
  Future<List<MediaItem>> getNextUp({int limit = 12}) async {
    final response = await _dio.get(
      '/Shows/NextUp',
      queryParameters: {
        'UserId': _userId,
        'Limit': limit,
        'Fields': 'Overview',
      },
    );
    return (response.data['Items'] as List<dynamic>)
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get favorite items
  Future<List<MediaItem>> getFavorites({
    List<String>? includeItemTypes,
    int? limit,
  }) async {
    final result = await getItems(
      isFavorite: true,
      includeItemTypes: includeItemTypes,
      limit: limit,
      recursive: true,
      sortBy: 'SortName',
      sortOrder: 'Ascending',
      fields: ['Overview'],
    );
    return result.items;
  }

  /// Get seasons for a series
  Future<List<MediaItem>> getSeasons(String seriesId) async {
    final response = await _dio.get(
      '/Shows/$seriesId/Seasons',
      queryParameters: {
        'UserId': _userId,
        'Fields': 'Overview',
      },
    );
    return (response.data['Items'] as List<dynamic>)
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get episodes for a season
  Future<List<MediaItem>> getEpisodes(String seriesId, {String? seasonId}) async {
    final response = await _dio.get(
      '/Shows/$seriesId/Episodes',
      queryParameters: {
        'UserId': _userId,
        if (seasonId != null) 'SeasonId': seasonId,
        'Fields': 'Overview,MediaSources',
      },
    );
    return (response.data['Items'] as List<dynamic>)
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Search for items
  Future<List<SearchHint>> search(String query, {int limit = 20}) async {
    final response = await _dio.get(
      '/Search/Hints',
      queryParameters: {
        'SearchTerm': query,
        'Limit': limit,
        'UserId': _userId,
        'IncludeItemTypes': 'Movie,Series,Episode,Audio,MusicAlbum,MusicArtist',
      },
    );
    return (response.data['SearchHints'] as List<dynamic>)
        .map((e) => SearchHint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get playback info for an item
  Future<PlaybackInfo> getPlaybackInfo(
    String itemId, {
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? startTimeTicks,
    int? maxStreamingBitrate,
    String? mediaSourceId,
  }) async {
    final response = await _dio.post(
      '/Items/$itemId/PlaybackInfo',
      queryParameters: {
        'UserId': _userId,
        if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex,
        if (subtitleStreamIndex != null) 'SubtitleStreamIndex': subtitleStreamIndex,
        if (startTimeTicks != null) 'StartTimeTicks': startTimeTicks,
        if (maxStreamingBitrate != null) 'MaxStreamingBitrate': maxStreamingBitrate,
        if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      },
      data: {
        'DeviceProfile': _getDeviceProfile(),
      },
    );
    return PlaybackInfo.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get direct stream URL for an item
  String getStreamUrl(
    String itemId, {
    String? mediaSourceId,
    String? container,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? startTimeTicks,
    bool? static,
  }) {
    final params = <String, String>{
      'api_key': _accessToken ?? '',
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (container != null) 'Container': container,
      if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex.toString(),
      if (subtitleStreamIndex != null) 'SubtitleStreamIndex': subtitleStreamIndex.toString(),
      if (startTimeTicks != null) 'StartTimeTicks': startTimeTicks.toString(),
      if (static != null) 'Static': static.toString(),
    };

    return '$_serverUrl/Videos/$itemId/stream?${Uri(queryParameters: params).query}';
  }

  /// Get HLS stream URL for transcoding
  String getHlsStreamUrl(
    String itemId, {
    String? mediaSourceId,
    String? playSessionId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? maxVideoBitrate,
    int? maxAudioBitrate,
    int? maxWidth,
    int? maxHeight,
    String? videoCodec,
    String? audioCodec,
    int? startTimeTicks,
  }) {
    final params = <String, String>{
      'api_key': _accessToken ?? '',
      'DeviceId': _deviceId,
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (playSessionId != null) 'PlaySessionId': playSessionId,
      if (audioStreamIndex != null) 'AudioStreamIndex': audioStreamIndex.toString(),
      if (subtitleStreamIndex != null) 'SubtitleStreamIndex': subtitleStreamIndex.toString(),
      if (maxVideoBitrate != null) 'VideoBitrate': maxVideoBitrate.toString(),
      if (maxAudioBitrate != null) 'AudioBitrate': maxAudioBitrate.toString(),
      if (maxWidth != null) 'MaxWidth': maxWidth.toString(),
      if (maxHeight != null) 'MaxHeight': maxHeight.toString(),
      if (videoCodec != null) 'VideoCodec': videoCodec,
      if (audioCodec != null) 'AudioCodec': audioCodec,
      if (startTimeTicks != null) 'StartTimeTicks': startTimeTicks.toString(),
      'TranscodingMaxAudioChannels': '6',
      'SegmentContainer': 'ts',
      'MinSegments': '2',
    };

    return '$_serverUrl/Videos/$itemId/master.m3u8?${Uri(queryParameters: params).query}';
  }

  /// Report playback start
  Future<void> reportPlaybackStart(PlaybackStartInfo info) async {
    await _dio.post('/Sessions/Playing', data: info.toJson());
  }

  /// Report playback progress
  Future<void> reportPlaybackProgress(PlaybackProgressInfo info) async {
    await _dio.post('/Sessions/Playing/Progress', data: info.toJson());
  }

  /// Report playback stopped
  Future<void> reportPlaybackStopped(PlaybackStopInfo info) async {
    await _dio.post('/Sessions/Playing/Stopped', data: info.toJson());
  }

  /// Mark item as played
  Future<void> markPlayed(String itemId) async {
    await _dio.post('/Users/$_userId/PlayedItems/$itemId');
  }

  /// Mark item as unplayed
  Future<void> markUnplayed(String itemId) async {
    await _dio.delete('/Users/$_userId/PlayedItems/$itemId');
  }

  /// Add item to favorites
  Future<void> addFavorite(String itemId) async {
    await _dio.post('/Users/$_userId/FavoriteItems/$itemId');
  }

  /// Remove item from favorites
  Future<void> removeFavorite(String itemId) async {
    await _dio.delete('/Users/$_userId/FavoriteItems/$itemId');
  }

  /// Set favorite status
  Future<void> setFavorite(String itemId, bool isFavorite) async {
    if (isFavorite) {
      await addFavorite(itemId);
    } else {
      await removeFavorite(itemId);
    }
  }

  /// Set watched status
  Future<void> setWatched(String itemId, bool isWatched) async {
    if (isWatched) {
      await markPlayed(itemId);
    } else {
      await markUnplayed(itemId);
    }
  }

  /// Get external subtitle URL
  String getSubtitleUrl(
    String itemId,
    String mediaSourceId,
    int subtitleIndex,
    String format,
  ) {
    return '$_serverUrl/Videos/$itemId/$mediaSourceId/Subtitles/$subtitleIndex/Stream.$format?api_key=$_accessToken';
  }

  /// Get image URL for an item
  String getImageUrl(
    String itemId,
    String imageType, {
    int? width,
    int? height,
    int? quality,
    String? tag,
    int? index,
  }) {
    final params = <String, String>{
      if (width != null) 'maxWidth': width.toString(),
      if (height != null) 'maxHeight': height.toString(),
      if (quality != null) 'quality': quality.toString(),
      if (tag != null) 'tag': tag,
    };

    final indexSuffix = index != null ? '/$index' : '';
    return '$_serverUrl/Items/$itemId/Images/$imageType$indexSuffix?${Uri(queryParameters: params).query}';
  }

  /// Get person image URL
  String getPersonImageUrl(String personId, {int? width, int? height, String? tag}) {
    final params = <String, String>{
      if (width != null) 'maxWidth': width.toString(),
      if (height != null) 'maxHeight': height.toString(),
      if (tag != null) 'tag': tag,
    };
    return '$_serverUrl/Items/$personId/Images/Primary?${Uri(queryParameters: params).query}';
  }

  // Getters
  String? get serverUrl => _serverUrl;
  String? get userId => _userId;
  String? get accessToken => _accessToken;
  String get deviceId => _deviceId;
  bool get isAuthenticated => _accessToken != null && _userId != null;

  /// Device profile for transcoding decisions
  Map<String, dynamic> _getDeviceProfile() {
    return {
      'Name': _clientName,
      'MaxStreamingBitrate': 120000000,
      'MusicStreamingTranscodingBitrate': 384000,
      'DirectPlayProfiles': [
        {
          'Container': 'mp4,m4v,mkv,webm',
          'Type': 'Video',
          'VideoCodec': 'h264,hevc,vp8,vp9,av1',
          'AudioCodec': 'aac,mp3,opus,flac,vorbis',
        },
        {
          'Container': 'mp3,flac,opus,aac,m4a,webm',
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
      'ContainerProfiles': <Map<String, dynamic>>[],
      'CodecProfiles': [
        {
          'Type': 'Video',
          'Codec': 'h264',
          'Conditions': [
            {
              'Condition': 'LessThanEqual',
              'Property': 'VideoBitDepth',
              'Value': '8',
            },
          ],
        },
      ],
      'SubtitleProfiles': [
        {'Format': 'srt', 'Method': 'External'},
        {'Format': 'ass', 'Method': 'External'},
        {'Format': 'ssa', 'Method': 'External'},
        {'Format': 'vtt', 'Method': 'External'},
        {'Format': 'sub', 'Method': 'External'},
        {'Format': 'smi', 'Method': 'External'},
        {'Format': 'pgssub', 'Method': 'Embed'},
        {'Format': 'dvdsub', 'Method': 'Embed'},
      ],
    };
  }
}

/// Result of items query
class ItemsResult {
  final List<MediaItem> items;
  final int totalCount;
  final int startIndex;

  const ItemsResult({
    required this.items,
    required this.totalCount,
    required this.startIndex,
  });

  factory ItemsResult.fromJson(Map<String, dynamic> json) {
    return ItemsResult(
      items: (json['Items'] as List<dynamic>)
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['TotalRecordCount'] as int? ?? 0,
      startIndex: json['StartIndex'] as int? ?? 0,
    );
  }
}
