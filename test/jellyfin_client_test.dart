import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/api/models.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordedRequest {
  final String method;
  final String path;
  final Map<String, dynamic> query;
  final dynamic body;
  final Map<String, dynamic> headers;

  RecordedRequest(
      this.method, this.path, this.query, this.body, this.headers);
}

class FakeAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  final Map<String, dynamic> responses;
  int? failWithStatus;

  FakeAdapter(this.responses);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    String? body;
    if (requestStream != null) {
      final bytes = await requestStream.fold<List<int>>(
          [], (a, b) => a..addAll(b));
      body = utf8.decode(bytes);
    }
    requests.add(RecordedRequest(options.method, options.path,
        options.queryParameters, body, options.headers));

    if (failWithStatus != null) {
      return ResponseBody.fromString(
          'error', failWithStatus!,
          statusMessage: 'Error', headers: {});
    }

    dynamic data = responses[options.path];
    if (data == null) {
      for (final e in responses.entries) {
        if (options.path.startsWith(e.key)) {
          data = e.value;
          break;
        }
      }
    }
    return ResponseBody.fromString(
        jsonEncode(data ?? {}), 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }
}

JellyfinClient clientWith(FakeAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return JellyfinClient(dio: dio, deviceId: 'dev1', deviceName: 'Test')
    ..setServerUrl('http://server:8096');
}

void main() {
  group('server url and auth header', () {
    test('normalizes url and adds scheme', () {
      final c = JellyfinClient(deviceId: 'd')
        ..setServerUrl('192.168.1.5:8096/');
      expect(c.serverUrl, 'http://192.168.1.5:8096');
    });

    test('auth header includes token only when set', () {
      final c = JellyfinClient(
          deviceId: 'd', deviceName: 'Dev', clientVersion: '9.9');
      expect(c.authHeader, isNot(contains('Token')));
      c.setCredentials(accessToken: 'tok', userId: 'u');
      expect(c.authHeader, contains('Token="tok"'));
      expect(c.authHeader, contains('DeviceId="d"'));
      expect(c.authHeader, contains('Version="9.9"'));
      expect(c.isAuthenticated, isTrue);
      c.clearCredentials();
      expect(c.isAuthenticated, isFalse);
    });
  });

  group('endpoints', () {
    test('testConnection parses server info', () async {
      final adapter = FakeAdapter({
        '/System/Info/Public': {
          'Id': 'srv',
          'ServerName': 'My Server',
          'Version': '10.9.0'
        },
      });
      final c = clientWith(adapter);
      final info = await c.testConnection('http://server:8096');
      expect(info.name, 'My Server');
      expect(info.serverUrl, 'http://server:8096');
    });

    test('authenticate posts credentials and stores token', () async {
      final adapter = FakeAdapter({
        '/Users/AuthenticateByName': {
          'User': {'Id': 'u1', 'Name': 'Cal'},
          'AccessToken': 'abc123',
          'ServerId': 'srv',
        },
      });
      final c = clientWith(adapter);
      final result = await c.authenticate('cal', 'pw');
      expect(result.accessToken, 'abc123');
      expect(c.accessToken, 'abc123');
      expect(c.userId, 'u1');
      final sent = adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.body, contains('cal'));
      expect(sent.body, contains('pw'));
    });

    test('requests send Authorization and X-Emby-Authorization',
        () async {
      final adapter = FakeAdapter({'/System/Info/Public': {}});
      final c = clientWith(adapter)
        ..setCredentials(accessToken: 'tok', userId: 'u1');
      await c.getServerInfo();
      final headers = adapter.requests.single.headers;
      expect(headers['Authorization'],
          contains('MediaBrowser Client="Finar"'));
      expect(headers['Authorization'], contains('Token="tok"'));
      expect(headers['X-Emby-Authorization'],
          contains('Token="tok"'));
    });

    test('getItems maps query params', () async {
      final adapter = FakeAdapter({
        '/Users/u1/Items': {'Items': [], 'TotalRecordCount': 0},
      });
      final c = clientWith(adapter)
        ..setCredentials(accessToken: 't', userId: 'u1');
      await c.getItems(
          parentId: 'lib1',
          includeItemTypes: ['Movie'],
          limit: 10,
          startIndex: 20,
          sortBy: 'SortName',
          recursive: true,
          searchTerm: 'alien',
          isFavorite: true,
          genres: 'Drama');
      final q = adapter.requests.single.query;
      expect(q['ParentId'], 'lib1');
      expect(q['IncludeItemTypes'], 'Movie');
      expect(q['Limit'], 10);
      expect(q['StartIndex'], 20);
      expect(q['SearchTerm'], 'alien');
      expect(q['IsFavorite'], true);
      expect(q['Genres'], 'Drama');
    });

    test('getLibraries parses views', () async {
      final adapter = FakeAdapter({
        '/Users/u1/Views': {
          'Items': [
            {'Id': 'l1', 'Name': 'Movies', 'CollectionType': 'movies'},
            {'Id': 'l2', 'Name': 'Music', 'CollectionType': 'music'},
          ]
        },
      });
      final c = clientWith(adapter)
        ..setCredentials(accessToken: 't', userId: 'u1');
      final libs = await c.getLibraries();
      expect(libs.length, 2);
      expect(libs[1].isMusic, isTrue);
    });

    test('search maps hints', () async {
      final adapter = FakeAdapter({
        '/Search/Hints': {
          'SearchHints': [
            {'ItemId': 'i1', 'Name': 'Alien', 'Type': 'Movie'}
          ]
        },
      });
      final c = clientWith(adapter)
        ..setCredentials(accessToken: 't', userId: 'u1');
      final hints = await c.search('ali');
      expect(hints.single.name, 'Alien');
      expect(adapter.requests.single.query['SearchTerm'], 'ali');
    });


    test('getPublicUsers parses the user list', () async {
      final adapter = FakeAdapter({
        '/Users/Public': [
          {'Id': 'u1', 'Name': 'Cal', 'HasPassword': true},
          {'Id': 'u2', 'Name': 'Guest'},
        ],
      });
      final c = clientWith(adapter);
      final users = await c.getPublicUsers();
      expect(users.length, 2);
      expect(users.first.hasPassword, isTrue);
    });

    test('userImageUrl builds with tag and width', () {
      final c = clientWith(FakeAdapter({}));
      final u = JfUser(id: 'u1', name: 'Cal', primaryImageTag: 'tag');
      expect(c.userImageUrl(u, maxWidth: 100),
          contains('/Items/u1/Images/Primary'));
      expect(c.userImageUrl(u, maxWidth: 100), contains('maxWidth=100'));
      expect(c.userImageUrl(const JfUser(id: 'u2', name: 'G')),
          isEmpty);
    });

    test('mark played/favorite use right verbs', () async {
      final adapter = FakeAdapter({});
      final c = clientWith(adapter)
        ..setCredentials(accessToken: 't', userId: 'u1');
      await c.markPlayed('i1');
      await c.markUnplayed('i1');
      await c.setFavorite('i1', true);
      await c.setFavorite('i1', false);
      expect(adapter.requests[0].method, 'POST');
      expect(adapter.requests[0].path, '/Users/u1/PlayedItems/i1');
      expect(adapter.requests[1].method, 'DELETE');
      expect(adapter.requests[2].method, 'POST');
      expect(adapter.requests[2].path,
          '/Users/u1/FavoriteItems/i1');
      expect(adapter.requests[3].method, 'DELETE');
    });

    test('playback reporting posts position', () async {
      final adapter = FakeAdapter({});
      final c = clientWith(adapter)
        ..setCredentials(accessToken: 't', userId: 'u1');
      await c.reportStart('i1', positionTicks: 500);
      await c.reportProgress('i1', positionTicks: 900, isPaused: true);
      await c.reportStop('i1', positionTicks: 900);
      expect(adapter.requests[0].path, '/Sessions/Playing');
      expect(adapter.requests[1].path,
          '/Sessions/Playing/Progress');
      expect(adapter.requests[2].path,
          '/Sessions/Playing/Stopped');
      expect(adapter.requests[1].body, contains('900'));
    });
  });

  group('url builders', () {
    test('image urls carry params', () {
      final c = clientWith(FakeAdapter({}))
        ..setCredentials(accessToken: 't', userId: 'u1');
      final url = c.imageUrl('i1', 'Primary',
          maxWidth: 300, quality: 80, tag: 'x');
      expect(url, startsWith('http://server:8096/Items/i1/Images/Primary'));
      expect(url, contains('maxWidth=300'));
      expect(url, contains('tag=x'));
    });

    test('poster falls back to series art for episodes', () {
      final c = clientWith(FakeAdapter({}))
        ..setCredentials(accessToken: 't', userId: 'u1');
      final ep = MediaItem.fromJson({
        'Id': 'e1',
        'Name': 'Ep',
        'Type': 'Episode',
        'SeriesId': 's1',
        'SeriesPrimaryImageTag': 'seriestag',
      });
      expect(c.posterUrl(ep), contains('/Items/s1/Images/Primary'));
    });

    test('stream urls embed token and params', () {
      final c = clientWith(FakeAdapter({}))
        ..setCredentials(accessToken: 'tok', userId: 'u1');
      final url = c.streamUrl('i1',
          mediaSourceId: 'ms', startTimeTicks: 42);
      expect(url, contains('api_key=tok'));
      expect(url, contains('MediaSourceId=ms'));
      expect(url, contains('StartTimeTicks=42'));
      final hls = c.hlsUrl('i1', playSessionId: 'p', maxBitrate: 4000);
      expect(hls, contains('master.m3u8'));
      expect(hls, contains('PlaySessionId=p'));
    });

    test('backdrop prefers own tags then parent', () {
      final c = clientWith(FakeAdapter({}))
        ..setCredentials(accessToken: 't', userId: 'u1');
      final own = MediaItem.fromJson({
        'Id': 'i1',
        'Name': 'x',
        'BackdropImageTags': ['b1']
      });
      expect(c.backdropUrl(own), contains('/Items/i1/Images/Backdrop'));
      final child = MediaItem.fromJson({
        'Id': 'i2',
        'Name': 'x',
        'ParentBackdropItemId': 'p9',
        'ParentBackdropImageTags': ['pb']
      });
      expect(c.backdropUrl(child), contains('/Items/p9/Images/Backdrop'));
      final none = MediaItem.fromJson({'Id': 'i3', 'Name': 'x'});
      expect(c.backdropUrl(none), isEmpty);
    });
  });
}
