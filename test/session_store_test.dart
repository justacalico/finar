import 'package:finar/core/models/models.dart';
import 'package:finar/core/storage/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/secure_storage_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
  });

  Session makeSession() => const Session(
        serverUrl: 'http://srv',
        serverName: 'Srv',
        accessToken: 'tok1',
        user: JellyfinUser(
            id: 'u1', name: 'Cal', primaryImageTag: 'img'),
      );

  test('session round trips through stores', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = SessionStore(prefs, const FlutterSecureStorage());
    expect(await store.loadSession(), isNull);
    await store.saveSession(makeSession());
    final restored = await store.loadSession();
    expect(restored, isNotNull);
    expect(restored!.serverUrl, 'http://srv');
    expect(restored.accessToken, 'tok1');
    expect(restored.user.id, 'u1');
  });

  test('clear removes everything', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = SessionStore(prefs, const FlutterSecureStorage());
    await store.saveSession(makeSession());
    await store.clearSession();
    expect(await store.loadSession(), isNull);
  });

  test('profiles accumulate and dedupe', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = SessionStore(prefs, const FlutterSecureStorage());
    await store.saveSession(makeSession());
    await store.saveSession(makeSession());
    final profiles = store.loadProfiles();
    expect(profiles.length, 1);
    expect(profiles.single.userName, 'Cal');
    expect(await store.profileToken(profiles.single), 'tok1');
  });

  test('removeProfile drops record and token', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = SessionStore(prefs, const FlutterSecureStorage());
    await store.saveSession(makeSession());
    final profile = store.loadProfiles().single;
    await store.removeProfile(profile);
    expect(store.loadProfiles(), isEmpty);
    expect(await store.profileToken(profile), isNull);
  });

  test('clearAll wipes prefs and tokens', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = SessionStore(prefs, const FlutterSecureStorage());
    await store.saveSession(makeSession());
    final profile = store.loadProfiles().single;
    await store.clearAll();
    expect(prefs.getKeys(), isEmpty);
    expect(store.loadProfiles(), isEmpty);
    expect(await store.loadSession(), isNull);
    expect(await store.profileToken(profile), isNull);
  });

  test('deviceId persists once generated', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = SessionStore(prefs, const FlutterSecureStorage());
    final id = await store.deviceId();
    expect(id, isNotEmpty);
    expect(await store.deviceId(), id);
  });
}
