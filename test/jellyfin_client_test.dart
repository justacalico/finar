import 'package:dio/dio.dart';
import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/dio_adapter.dart';

void main() {
  late FakeAdapter adapter;
  late JellyfinClient client;

  setUp(() {
    adapter = FakeAdapter({
      'GET /System/Info/Public': (_) => {
            'ServerName': 'Demo',
            'Version': '10.9.11',
            'Id': 'srv1',
            'ProductName': 'Jellyfin Server',
          },
      'POST /Users/AuthenticateByName': (_) => {
            'AccessToken': 'tok',
            'ServerId': 'srv1',
            'User': {'Id': 'u1', 'Name': 'Cal'}
          },
      'GET /Users/Me': (_) => {'Id': 'u1', 'Name': 'Cal'},
      'GET /Users/u1/Views': (_) => {
            'Items': [
              {'Id': 'l1', 'Name': 'Movies', 'Type': 'CollectionFolder'}
            ],
            'TotalRecordCount': 1
          },
      'GET /QuickConnect/Enabled': (_) => true,
      'POST /QuickConnect/Initiate': (_) =>
          {'Code': 'CODE', 'Secret': 'SEC'},
      'GET /QuickConnect/Connect': (_) => {'Authenticated': true},
      'POST /Users/AuthenticateWithQuickConnect': (_) => {
            'AccessToken': 'qtok',
            'ServerId': 'srv1',
            'User': {'Id': 'u1', 'Name': 'Cal'}
          },
      'POST /Users/u1/FavoriteItems/i1': (_) =>
          {'UserData': {'IsFavorite': true}},
      'DELETE /Users/u1/FavoriteItems/i1': (_) =>
          {'UserData': {'IsFavorite': false}},
      'POST /Users/u1/PlayedItems/i1': (_) =>
          {'UserData': {'Played': true}},
      'DELETE /Users/u1/PlayedItems/i1': (_) => 204,
      'POST /Sessions/Playing': (_) => 204,
      'POST /Sessions/Playing/Progress': (_) => 204,
      'POST /Sessions/Playing/Stopped': (_) => 204,
      'POST /Sessions/Logout': (_) => 204,
    });
    client = JellyfinClient(
      serverUrl: 'http://srv.local',
      deviceId: 'dev1',
      accessToken: 'tok',
      userId: 'u1',
      dio: Dio()..httpClientAdapter = adapter,
    );
  });

  test('fetches public system info', () async {
    final info = await client.getPublicSystemInfo();
    expect(info.serverName, 'Demo');
    expect(info.version, '10.9.11');
  });

  test('authenticates by name', () async {
    final result = await client.authenticateByName('cal', 'pw');
    expect(result.accessToken, 'tok');
    expect(result.user.name, 'Cal');
  });

  test('quick connect round trip', () async {
    expect(await client.quickConnectEnabled(), isTrue);
    final init = await client.quickConnectInitiate();
    expect(init.code, 'CODE');
    expect(await client.quickConnectCheck('SEC'), isTrue);
    final auth = await client.authenticateWithQuickConnect('SEC');
    expect(auth.accessToken, 'qtok');
  });

  test('fetches views and current user', () async {
    final views = await client.getUserViews();
    expect(views.items.single.name, 'Movies');
    expect((await client.getCurrentUser()).id, 'u1');
  });

  test('favorite and played mutations parse user data', () async {
    expect((await client.setFavorite('i1', true)).isFavorite, isTrue);
    expect((await client.setFavorite('i1', false)).isFavorite, isFalse);
    expect((await client.setPlayed('i1', true)).played, isTrue);
    expect((await client.setPlayed('i1', false)).played, isFalse);
  });

  test('playback reporting posts', () async {
    final item = const BaseItem(id: 'i1', name: 'x', type: 'Movie');
    await client.reportPlaybackStart(item);
    await client.reportPlaybackProgress(item, positionTicks: 1);
    await client.reportPlaybackStopped(item, positionTicks: 2);
    await client.logout();
    expect(adapter.calls, containsAll([
      'POST /Sessions/Playing',
      'POST /Sessions/Playing/Progress',
      'POST /Sessions/Playing/Stopped',
      'POST /Sessions/Logout',
    ]));
  });

  test('auth header includes client and token', () async {
    await client.getPublicSystemInfo();
    final auth = adapter;
    expect(auth.calls.isNotEmpty, isTrue);
  });

  test('image urls carry parameters', () {
    final uri = client.imageUrl('i1', 'Primary', maxWidth: 300, tag: 't');
    expect(uri.path, '/Items/i1/Images/Primary');
    expect(uri.queryParameters['maxWidth'], '300');
    expect(uri.queryParameters['tag'], 't');
    expect(uri.queryParameters['quality'], '90');
  });

  test('stream urls differ for audio and video', () {
    expect(client.streamUrl('i1').path, '/Videos/i1/stream');
    expect(client.streamUrl('i1', isAudio: true).path,
        '/Audio/i1/universal');
    expect(client.streamUrl('i1').queryParameters['api_key'], 'tok');
  });

  test('children, seasons and episodes parse', () async {
    client.dio.httpClientAdapter = FakeAdapter({
      'GET /Users/u1/Items': (o) => {
            'Items': [itemJson(id: 'c1', type: 'Movie')],
            'TotalRecordCount': 1,
          },
      'GET /Shows/s1/Seasons': (o) => {
            'Items': [itemJson(id: 'sea1', type: 'Season')],
          },
      'GET /Shows/s1/Episodes': (o) => {
            'Items': [itemJson(id: 'e1', type: 'Episode')],
          },
    });
    final kids = await client.getItems(parentId: 'x');
    expect(kids.items.single.id, 'c1');
    expect((await client.getSeasons('s1')).items.single.type, 'Season');
    expect((await client.getEpisodes('s1', seasonId: 'sea1'))
        .items
        .single
        .type, 'Episode');
  });

  test('next up, similar, latest and resume endpoints', () async {
    client.dio.httpClientAdapter = FakeAdapter({
      'GET /Shows/NextUp': (_) => {
            'Items': [itemJson(id: 'n1', type: 'Episode')],
          },
      'GET /Items/a1/Similar': (_) => {
            'Items': [itemJson(id: 's2')],
          },
      'GET /Users/u1/Items/Latest': (_) =>
          [itemJson(id: 'l1'), itemJson(id: 'l2')],
      'GET /Users/u1/Items/Resume': (_) => {
            'Items': [itemJson(id: 'r1')],
          },
    });
    expect((await client.getNextUp()).items.single.id, 'n1');
    expect((await client.getSimilar('a1')).items.single.id, 's2');
    expect((await client.getLatestMedia(parentId: 'lib')).items.length, 2);
    expect((await client.getResumeItems()).items.single.id, 'r1');
  });

  test('quickConnectCheck reports authentication', () async {
    var calls = 0;
    client.dio.httpClientAdapter = FakeAdapter({
      'GET /QuickConnect/Connect': (_) {
        calls++;
        return {
          'Code': 'ABC',
          'Secret': 's',
          'Authenticated': calls > 1,
        };
      },
    });
    expect(await client.quickConnectCheck('s'), isFalse);
    expect(await client.quickConnectCheck('s'), isTrue);
  });

  test('image urls return null without tags', () {
    expect(
        client.primaryImageUrl(BaseItem.fromJson(itemJson())),
        isNull);
    expect(
        client.backdropImageUrl(BaseItem.fromJson(itemJson())),
        isNull);
    expect(
        client
            .userImageUrl(const JellyfinUser(id: 'u', name: 'n')),
        isNull);
  });

  test('setPlayed posts playstate', () async {
    String? path;
    client.dio.httpClientAdapter = FakeAdapter({
      'POST /Users/u1/PlayedItems/i1': (o) {
        path = o.path;
        return userDataJson();
      },
    });
    final d = await client.setPlayed('i1', true);
    expect(d.played, isTrue);
    expect(path, contains('PlayedItems'));
  });

  test('getItem, logout and user image variants', () async {
    client.dio.httpClientAdapter = FakeAdapter({
      'GET /Users/u1/Items/i9': (_) => itemJson(id: 'i9'),
      'POST /Sessions/Logout': (_) => 204,
    });
    expect((await client.getItem('i9')).id, 'i9');
    await client.logout();
    final user = JellyfinUser.fromJson(
        {'Id': 'u', 'Name': 'n', 'PrimaryImageTag': 't'});
    expect(client.userImageUrl(user, maxWidth: 64).toString(),
        contains('tag=t'));
  });

  test('image url params and un-favorite path', () async {
    client.dio.httpClientAdapter = FakeAdapter({
      'DELETE /Users/u1/FavoriteItems/i1': (_) =>
          {'UserData': {'IsFavorite': false}},
      'DELETE /Users/u1/PlayedItems/i2': (_) => 204,
    });
    final fav = await client.setFavorite('i1', false);
    expect(fav.isFavorite, isFalse);
    final played = await client.setPlayed('i2', false);
    expect(played.played, isFalse);
    final item = BaseItem.fromJson({
      'Id': 'x',
      'Name': 'n',
      'Type': 'Movie',
      'ImageTags': {'Primary': 'pt'},
      'BackdropImageTags': ['bt'],
    });
    final u = client.primaryImageUrl(item, maxWidth: 300)!;
    expect(u.toString(), contains('quality=90'));
    expect(u.toString(), contains('maxWidth=300'));
    expect(u.toString(), contains('tag=pt'));
    expect(client.backdropImageUrl(item).toString(), contains('bt'));
  });

  test('playback position variants', () async {
    client.dio.httpClientAdapter = FakeAdapter({
      'POST /Sessions/Playing': (_) => 204,
      'POST /Sessions/Playing/Progress': (_) => 204,
      'POST /Sessions/Playing/Stopped': (_) => 204,
    });
    final item = BaseItem.fromJson(itemJson());
    await client.reportPlaybackStart(item, positionTicks: 5);
    await client.reportPlaybackProgress(item,
        positionTicks: 10, isPaused: true);
    await client.reportPlaybackStopped(item, positionTicks: 15);
    final fresh = client.dio.httpClientAdapter as FakeAdapter;
    expect(
        fresh.calls.where((c) => c.contains('/Sessions/')).length, 3);
  });

  test('trailing slash server url and auth header branch', () {
    final c = JellyfinClient(
        serverUrl: 'http://s/', deviceId: 'd', accessToken: 't');
    expect(c.streamUrl('x', isAudio: false).toString(),
        'http://s/Videos/x/stream?api_key=t&static=true');
    final img = c.imageUrl('x', 'Primary',
        maxHeight: 200, tag: 't');
    expect(img.toString(), contains('maxHeight=200'));
    expect(img.toString(), contains('tag=t'));
  });

  test('getItems forwards all query params', () async {
    RequestOptions? seen;
    client.dio.httpClientAdapter = FakeAdapter({
      'GET /Users/u1/Items': (o) {
        seen = o;
        return {'Items': [], 'TotalRecordCount': 0};
      },
    });
    await client.getItems(
        parentId: 'lib',
        includeItemTypes: const ['Movie'],
        sortBy: const ['DateCreated'],
        sortOrder: 'Descending',
        filters: const ['IsUnplayed'],
        searchTerm: 'dune',
        limit: 10,
        startIndex: 20,
        genres: 'Sci-Fi',
        artistIds: 'a1',
        excludeItemTypes: 'Trailer');
    final uri = seen!.uri;
    expect(uri.queryParameters['ParentId'], 'lib');
    expect(uri.queryParameters['IncludeItemTypes'], 'Movie');
    expect(uri.queryParameters['Genres'], 'Sci-Fi');
    expect(uri.queryParameters['Filters'], 'IsUnplayed');
    expect(uri.queryParameters['SortOrder'], 'Descending');
  });

  test('error bodies map to JellyfinException message', () async {
    client.dio.httpClientAdapter = FakeAdapter({
      'GET /Users/u1/Views': (_) => (400, {'Message': 'bad request'}),
      'DELETE /Users/u1/PlayedItems/i1': (_) => 500,
      'DELETE /Users/u1/FavoriteItems/i1': (_) => 404,
    });
    try {
      await client.getUserViews();
      fail('expected');
    } on JellyfinException catch (e) {
      expect(e.statusCode, 400);
      expect(e.message, 'bad request');
    }
    await expectLater(client.setPlayed('i1', false),
        throwsA(isA<JellyfinException>()));
    await expectLater(client.setFavorite('i1', false),
        throwsA(isA<JellyfinException>()));
  });

  test('getNextUp forwards seriesId', () async {
    RequestOptions? seen;
    client.dio.httpClientAdapter = FakeAdapter({
      'GET /Shows/NextUp': (o) {
        seen = o;
        return {'Items': []};
      },
    });
    await client.getNextUp(seriesId: 's1');
    expect(seen!.uri.queryParameters['SeriesId'], 's1');
  });

  test('post error maps message from body', () async {
    client.dio.httpClientAdapter = FakeAdapter({
      'POST /Users/AuthenticateByName': (_) =>
          (401, {'Message': 'Invalid user'}),
    });
    try {
      await client.authenticateByName('a', 'b');
      fail('expected');
    } on JellyfinException catch (e) {
      expect(e.statusCode, 401);
      expect(e.message, 'Invalid user');
      expect(e.isAuthError, isTrue);
    }
  });

  test('post error without body falls back to message', () async {
    client.dio.httpClientAdapter = FakeAdapter({
      'POST /Sessions/Logout': (_) => 500,
    });
    await expectLater(
        client.logout(), throwsA(isA<JellyfinException>()));
  });

  test('userImageUrl on trailing-slash server', () {
    final c = JellyfinClient(serverUrl: 'http://s/', deviceId: 'd');
    final user = JellyfinUser.fromJson(
        {'Id': 'u', 'Name': 'n', 'PrimaryImageTag': 't'});
    expect(
        c.userImageUrl(user, maxWidth: 40).toString(),
        contains('http://s/Users/u/Images/Primary'));
  });

  test('errors surface as JellyfinException', () async {
    adapter.routes['GET /System/Info/Public'] =
        (_) => {'Message': 'boom'};
    adapter.routes.clear();
    expect(
        () => client.getPublicSystemInfo(),
        throwsA(isA<JellyfinException>()));
  });
}

Map<String, dynamic> itemJson({String id = 'x', String type = 'Movie'}) =>
    {'Id': id, 'Name': 'Item $id', 'Type': type};

Map<String, dynamic> userDataJson() => {
      'UserData': {'IsFavorite': false, 'Played': true}
    };
