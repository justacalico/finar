import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/models/models.dart';
import 'package:finar/core/storage/downloads_store.dart';
import 'package:finar/core/storage/session_store.dart';
import 'package:finar/core/utils/version_utils.dart';
import 'package:finar/providers/core_providers.dart';
import 'package:finar/providers/downloads_provider.dart';
import 'package:finar/providers/item_actions.dart';
import 'package:finar/providers/library_providers.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:finar/providers/session_provider.dart';

import 'helpers/fake_client.dart';
import 'helpers/path_provider_mock.dart';
import 'helpers/secure_storage_mock.dart';
import 'helpers/dio_adapter.dart';
import 'helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('JellyfinException formatting and auth check', () {
    const e = JellyfinException('bad', statusCode: 401);
    expect(e.isAuthError, isTrue);
    expect(e.toString(), contains('401'));
    expect(const JellyfinException('x').isAuthError, isFalse);
  });

  test('Version equality, hash and isNewerThan', () {
    final a = Version.tryParse('1.2.3')!;
    final b = Version.tryParse('v1.2.3')!;
    expect(a == b, isTrue);
    expect(a.hashCode, b.hashCode);
    expect('$a', '1.2.3');
    expect(Version.tryParse('1.3.0')!.isNewerThan(a), isTrue);
    expect(a.isNewerThan(Version.tryParse('1.3.0')!), isFalse);
  });

  test('MediaStream helpers and labels', () {
    const video = MediaStream(index: 0, type: 'Video');
    expect(video.isVideo, isTrue);
    expect(video.label, 'Track 0');
    const named = MediaStream(
        index: 3, type: 'Audio', language: 'eng', codec: 'aac');
    expect(named.label, 'eng aac');
    const titled =
        MediaStream(index: 1, type: 'Subtitle', displayTitle: 'SDH');
    expect(titled.label, 'SDH');
  });

  test('JellyfinUser toJson round trip', () {
    const user = JellyfinUser(
        id: 'u', name: 'Cal', primaryImageTag: 't', isAdministrator: true);
    final json = user.toJson();
    expect(json['Policy']['IsAdministrator'], isTrue);
    expect(json['PrimaryImageTag'], 't');
  });

  test('corrupt profiles storage returns empty list', () async {
    SharedPreferences.setMockInitialValues(
        {'session.profiles': 'not json'});
    final prefs = await SharedPreferences.getInstance();
    final store =
        SessionStore(prefs, const FlutterSecureStorage());
    expect(store.loadProfiles(), isEmpty);
  });

  test('sharedPrefsProvider throws when not overridden', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(() => c.read(sharedPrefsProvider), throwsUnimplementedError);
  });

  test('deviceIdProvider and stores build from real prefs', () async {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);
    final id = await c.read(deviceIdProvider.future);
    expect(id, isNotEmpty);
    expect(c.read(downloadsStoreProvider).load(), isEmpty);
    expect(c.read(profilesProvider), isEmpty);
    expect(c.read(sessionProvider), isNull);
  });

  test('real SessionNotifier builds unauthenticated client', () async {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
    ]);
    addTearDown(c.dispose);
    final notifier = c.read(sessionProvider.notifier);
    expect(c.read(sessionProvider), isNull);
    final client = await notifier.unauthenticatedClient('http://x');
    expect(client.serverUrl, 'http://x');
    expect(() => notifier.authenticatedClient(),
        throwsA(isA<StateError>()));
  });

  test('signInWithProfile succeeds through clientFor', () async {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      sessionProvider.overrideWith(() => FakeSessionNotifier(null)),
    ]);
    addTearDown(c.dispose);
    final notifier = c.read(sessionProvider.notifier);
    await notifier.signIn('http://x', 'X', const AuthResult(
        user: JellyfinUser(id: 'u1', name: 'Cal'),
        accessToken: 'tok',
        serverId: 's1'));
    await notifier.signOut();
    const profile = SavedProfile(
        id: 'http://x|u1',
        serverUrl: 'http://x',
        serverName: 'X',
        userId: 'u1',
        userName: 'Cal');
    expect(await notifier.signInWithProfile(profile), isTrue);
    expect(c.read(sessionProvider)!.serverUrl, 'http://x');
    await c.read(profilesProvider.notifier).refresh();
    expect(c.read(profilesProvider), isNotEmpty);
  });

  test('itemActions setPlayed throws signed out', () async {
    SharedPreferences.setMockInitialValues({});
    final result = await TestHarness.create(signedIn: false);
    final c = ProviderContainer(overrides: result.overrides);
    addTearDown(c.dispose);
    expect(() => c.read(itemActionsProvider).setPlayed('x', true),
        throwsA(isA<StateError>()));
  });

  test('itemProvider throws when signed out', () async {
    SharedPreferences.setMockInitialValues({});
    final result = await TestHarness.create(signedIn: false);
    final c = ProviderContainer(overrides: result.overrides);
    addTearDown(c.dispose);
    await expectLater(c.read(itemProvider('x').future),
        throwsA(isA<StateError>()));
  });

  test('LibraryQuery copyWith and equality', () {
    const q = LibraryQuery(parentId: 'p');
    expect(q, const LibraryQuery(parentId: 'p'));
    expect(q.copyWith(sortBy: 'Name').sortBy, 'Name');
    expect(q.copyWith(descending: true).descending, isTrue);
    expect(q.copyWith(genre: () => 'Drama').genre, 'Drama');
    expect(q.copyWith(genre: () => null).genre, isNull);
    expect(q.copyWith(filter: LibraryFilter.unplayed).filter,
        LibraryFilter.unplayed);
    expect(q.hashCode, const LibraryQuery(parentId: 'p').hashCode);
    expect(q == const LibraryQuery(parentId: 'other'), isFalse);
  });

  test('download failure marks record failed, cancel removes it',
      () async {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    mockPathProvider();
    final client = FakeJellyfinClient();
    client.dio.httpClientAdapter = FakeAdapter({});
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(
          await SharedPreferences.getInstance()),
      jellyfinClientProvider.overrideWithValue(client),
      sessionProvider
          .overrideWith(() => FakeSessionNotifier(testSession())),
    ]);
    addTearDown(c.dispose);
    await c.read(downloadsProvider.notifier).start(makeItem(id: 'x'));
    await pumpEventQueue();
    final r = c.read(downloadsProvider).single;
    expect(r.status, DownloadStatus.failed);
    await c.read(downloadsProvider.notifier).cancel('x');
    await pumpEventQueue();
    expect(c.read(downloadsProvider), isEmpty);
  });

  test('player state follows backend streams', () async {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    final result = await TestHarness.create();
    final c = ProviderContainer(overrides: [
      ...result.overrides,
      sessionProvider
          .overrideWith(() => FakeSessionNotifier(testSession())),
    ]);
    addTearDown(c.dispose);
    await c
        .read(playerProvider.notifier)
        .playItem(makeItem(id: 'a', type: 'Audio'));
    result.harness.backend.emitBuffering(true);
    result.harness.backend.emitPosition(const Duration(seconds: 9));
    result.harness.backend.emitRate(1.25);
    await pumpEventQueue();
    final state = c.read(playerProvider);
    expect(state.buffering, isTrue);
    expect(state.position, const Duration(seconds: 9));
    expect(state.rate, 1.25);
    await c.read(playerProvider.notifier).stop();
    expect(c.read(playerProvider).item, isNull);
  });
}
