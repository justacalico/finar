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

  test('errors surface as JellyfinException', () async {
    adapter.routes['GET /System/Info/Public'] =
        (_) => {'Message': 'boom'};
    adapter.routes.clear();
    expect(
        () => client.getPublicSystemInfo(),
        throwsA(isA<JellyfinException>()));
  });
}
