import 'package:dio/dio.dart';

import '../constants.dart';
import '../models/models.dart';

class JellyfinException implements Exception {
  const JellyfinException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isAuthError => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'JellyfinException($statusCode): $message';
}

class JellyfinClient {
  JellyfinClient({
    required this.serverUrl,
    required this.deviceId,
    this.accessToken,
    this.userId,
    Dio? dio,
  }) : dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ));

  final String serverUrl;
  final String deviceId;
  final String? accessToken;
  final String? userId;
  final Dio dio;

  String get _authHeader {
    final parts = [
      'MediaBrowser Client="$kAppName"',
      'Device="Finar"',
      'DeviceId="$deviceId"',
      'Version="$kAppVersion"',
    ];
    if (accessToken != null) parts.add('Token="$accessToken"');
    return parts.join(', ');
  }

  Options _opts([Map<String, String>? headers]) => Options(headers: {
        'X-Emby-Authorization': _authHeader,
        if (accessToken != null) 'X-Emby-Token': accessToken,
        ...?headers,
      });

  Uri _u(String path, [Map<String, dynamic>? query]) {
    final base = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    final q = <String, dynamic>{
      if (accessToken != null) 'api_key': accessToken,
      ...?query,
    };
    return Uri.parse('$base$path').replace(
        queryParameters: q.map((k, v) => MapEntry(k, v.toString())));
  }

  Future<T> _get<T>(
      String path, T Function(dynamic data) parse,
      [Map<String, dynamic>? query]) async {
    try {
      final res = await dio.getUri(_u(path, query), options: _opts());
      return parse(res.data);
    } on DioException catch (e) {
      throw JellyfinException(
        e.response?.data is Map<String, dynamic>
            ? (e.response!.data['Message']?.toString() ?? e.message ?? 'error')
            : e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<T> _post<T>(String path, T Function(dynamic data) parse,
      {Object? body, Map<String, dynamic>? query}) async {
    try {
      final res =
          await dio.postUri(_u(path, query), data: body, options: _opts());
      return parse(res.data);
    } on DioException catch (e) {
      throw JellyfinException(
        e.response?.data is Map<String, dynamic>
            ? (e.response!.data['Message']?.toString() ?? e.message ?? 'error')
            : e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> _delete(String path) async {
    try {
      await dio.deleteUri(_u(path), options: _opts());
    } on DioException catch (e) {
      throw JellyfinException(e.message ?? 'Network error',
          statusCode: e.response?.statusCode);
    }
  }

  Future<PublicSystemInfo> getPublicSystemInfo() =>
      _get('/System/Info/Public',
          (d) => PublicSystemInfo.fromJson(d as Map<String, dynamic>));

  Future<AuthResult> authenticateByName(String username, String password) =>
      _post('/Users/AuthenticateByName',
          (d) => AuthResult.fromJson(d as Map<String, dynamic>),
          body: {'Username': username, 'Pw': password});

  Future<bool> quickConnectEnabled() async {
    try {
      final res = await dio.getUri(_u('/QuickConnect/Enabled'),
          options: _opts());
      return res.data == true || res.data.toString() == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<QuickConnectResult> quickConnectInitiate() =>
      _post('/QuickConnect/Initiate',
          (d) => QuickConnectResult.fromJson(d as Map<String, dynamic>),
          body: const {});

  Future<bool> quickConnectCheck(String secret) async {
    final res = await _get(
        '/QuickConnect/Connect', (d) => d as Map<String, dynamic>,
        {'secret': secret});
    return res['Authenticated'] == true;
  }

  Future<AuthResult> authenticateWithQuickConnect(String secret) =>
      _post('/Users/AuthenticateWithQuickConnect',
          (d) => AuthResult.fromJson(d as Map<String, dynamic>),
          body: {'Secret': secret});

  Future<JellyfinUser> getCurrentUser() =>
      _get('/Users/Me', (d) => JellyfinUser.fromJson(d as Map<String, dynamic>));

  Future<ItemsResult> getUserViews() =>
      _get('/Users/$userId/Views',
          (d) => ItemsResult.fromJson(d as Map<String, dynamic>),
          {'IncludeExternalContent': false});

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
  }) =>
      _get(
        '/Users/$userId/Items',
        (d) => ItemsResult.fromJson(d as Map<String, dynamic>),
        {
          'ParentId': ?parentId,
          'IncludeItemTypes': ?includeItemTypes?.join(','),
          'ExcludeItemTypes': ?excludeItemTypes,
          'SortBy': ?sortBy?.join(','),
          'SortOrder': sortOrder,
          'Filters': ?filters?.join(','),
          if (searchTerm != null && searchTerm.isNotEmpty)
            'SearchTerm': searchTerm,
          'Limit': ?limit,
          'StartIndex': startIndex,
          'Recursive': recursive,
          'Fields': (fields ??
                  ['PrimaryImageAspectRatio', 'Overview', 'MediaSources', 'Genres'])
              .join(','),
          if (genres != null && genres.isNotEmpty) 'Genres': genres,
          'ArtistIds': ?artistIds,
          'EnableImageTypes': 'Primary,Backdrop,Logo,Thumb',
          'ImageTypeLimit': 1,
        },
      );

  Future<BaseItem> getItem(String id) => _get(
        '/Users/$userId/Items/$id',
        (d) => BaseItem.fromJson(d as Map<String, dynamic>),
        {'Fields': 'PrimaryImageAspectRatio,Overview,MediaSources,Genres,People,MediaStreams'},
      );

  Future<ItemsResult> getResumeItems({int limit = 20}) => _get(
        '/Users/$userId/Items/Resume',
        (d) => ItemsResult.fromJson(d as Map<String, dynamic>),
        {
          'Limit': limit,
          'MediaTypes': 'Video,Audio',
          'Fields': 'PrimaryImageAspectRatio,Overview,MediaSources',
        },
      );

  Future<ItemsResult> getLatestMedia({String? parentId, int limit = 16}) =>
      _get(
        '/Users/$userId/Items/Latest',
        (d) => ItemsResult.fromJson(
            {'Items': d, 'TotalRecordCount': (d as List).length}),
        {
          'ParentId': ?parentId,
          'Limit': limit,
          'Fields': 'PrimaryImageAspectRatio,Overview',
        },
      );

  Future<ItemsResult> getNextUp({String? seriesId, int limit = 24}) => _get(
        '/Shows/NextUp',
        (d) => ItemsResult.fromJson(d as Map<String, dynamic>),
        {
          'UserId': userId,
          'SeriesId': ?seriesId,
          'Limit': limit,
          'Fields': 'PrimaryImageAspectRatio,Overview',
        },
      );

  Future<ItemsResult> getSimilar(String itemId, {int limit = 12}) => _get(
        '/Items/$itemId/Similar',
        (d) => ItemsResult.fromJson(d as Map<String, dynamic>),
        {
          'UserId': userId,
          'Limit': limit,
          'Fields': 'PrimaryImageAspectRatio,Overview',
        },
      );

  Future<ItemsResult> getSeasons(String seriesId) => _get(
        '/Shows/$seriesId/Seasons',
        (d) => ItemsResult.fromJson(d as Map<String, dynamic>),
        {'UserId': userId, 'Fields': 'PrimaryImageAspectRatio,Overview'},
      );

  Future<ItemsResult> getEpisodes(String seriesId, {String? seasonId}) =>
      _get(
        '/Shows/$seriesId/Episodes',
        (d) => ItemsResult.fromJson(d as Map<String, dynamic>),
        {
          'UserId': userId,
          'SeasonId': ?seasonId,
          'Fields': 'PrimaryImageAspectRatio,Overview,MediaSources',
        },
      );

  Future<UserData> setFavorite(String itemId, bool favorite) async {
    if (favorite) {
      return _post(
          '/Users/$userId/FavoriteItems/$itemId',
          (d) => UserData.fromJson(
              (d as Map<String, dynamic>)['UserData'] as Map<String, dynamic>? ?? d),
          body: const {});
    }
    try {
      final res = await dio.deleteUri(
          _u('/Users/$userId/FavoriteItems/$itemId'),
          options: _opts());
      final d = res.data as Map<String, dynamic>;
      return UserData.fromJson(
          d['UserData'] as Map<String, dynamic>? ?? const {});
    } on DioException catch (e) {
      throw JellyfinException(e.message ?? 'error',
          statusCode: e.response?.statusCode);
    }
  }

  Future<UserData> setPlayed(String itemId, bool played) async {
    UserData parse(dynamic d) => UserData.fromJson(
        (d as Map<String, dynamic>)['UserData'] as Map<String, dynamic>? ??
            d);
    if (played) {
      return _post('/Users/$userId/PlayedItems/$itemId', parse,
          body: const {});
    }
    await _delete('/Users/$userId/PlayedItems/$itemId');
    return const UserData();
  }

  Future<void> reportPlaybackStart(BaseItem item, {int positionTicks = 0}) =>
      _post('/Sessions/Playing', (_) {},
          body: {
            'ItemId': item.id,
            'PositionTicks': positionTicks,
            'IsPaused': false,
            'CanSeek': true,
            'PlayMethod': 'DirectPlay',
          });

  Future<void> reportPlaybackProgress(BaseItem item,
      {required int positionTicks, bool isPaused = false}) =>
      _post('/Sessions/Playing/Progress', (_) {},
          body: {
            'ItemId': item.id,
            'PositionTicks': positionTicks,
            'IsPaused': isPaused,
            'CanSeek': true,
            'PlayMethod': 'DirectPlay',
          });

  Future<void> reportPlaybackStopped(BaseItem item,
          {required int positionTicks}) =>
      _post('/Sessions/Playing/Stopped', (_) {},
          body: {'ItemId': item.id, 'PositionTicks': positionTicks});

  Future<void> logout() => _post('/Sessions/Logout', (_) {}, body: const {});

  Uri imageUrl(String itemId, String type,
      {int? maxWidth, int? maxHeight, int quality = 90, String? tag}) {
    final params = <String, String>{
      if (maxWidth != null) 'maxWidth': '$maxWidth',
      if (maxHeight != null) 'maxHeight': '$maxHeight',
      'quality': '$quality',
      'tag': ?tag,
    };
    final base = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return Uri.parse('$base/Items/$itemId/Images/$type')
        .replace(queryParameters: params);
  }

  Uri? primaryImageUrl(BaseItem item,
      {int? maxWidth, int? maxHeight}) {
    if (item.primaryImageTag == null) return null;
    return imageUrl(item.id, 'Primary',
        maxWidth: maxWidth, maxHeight: maxHeight,
        tag: item.primaryImageTag);
  }

  Uri? backdropImageUrl(BaseItem item, {int? maxWidth}) {
    if (item.backdropImageTag == null &&
        item.parentBackdropItemId == null) {
      return null;
    }
    return imageUrl(item.effectiveBackdropId, 'Backdrop',
        maxWidth: maxWidth, tag: item.backdropImageTag);
  }

  Uri? userImageUrl(JellyfinUser user, {int? maxWidth}) {
    if (user.primaryImageTag == null) return null;
    final base = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return Uri.parse('$base/Users/${user.id}/Images/Primary').replace(
        queryParameters: {
          'tag': user.primaryImageTag!,
          if (maxWidth != null) 'maxWidth': '$maxWidth',
        });
  }

  Uri streamUrl(String itemId, {bool isAudio = false}) {
    if (isAudio) {
      return _u('/Audio/$itemId/universal',
          {'container': 'opus,mp3,aac,m4a,flac,webma,webm,wav,ogg'});
    }
    return _u('/Videos/$itemId/stream', {'static': 'true'});
  }
}
