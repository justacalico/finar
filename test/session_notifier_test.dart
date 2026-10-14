import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finar/core/models/models.dart';
import 'package:finar/core/storage/session_store.dart';
import 'package:finar/providers/core_providers.dart';
import 'package:finar/providers/session_provider.dart';

import 'helpers/secure_storage_mock.dart';
import 'helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
  });

  Future<ProviderContainer> makeContainer() async {
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      deviceIdProvider.overrideWith((_) async => 'dev-1'),
      sessionProvider.overrideWith(() => FakeSessionNotifier(null)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  const auth = AuthResult(
      user: JellyfinUser(id: 'u1', name: 'Cal'),
      accessToken: 'tok',
      serverId: 's1');

  test('signIn stores the session', () async {
    final c = await makeContainer();
    await c.read(sessionProvider.notifier).signIn('http://srv', 'Srv', auth);
    final session = c.read(sessionProvider);
    expect(session!.accessToken, 'tok');
    expect(session.user.name, 'Cal');
    final restored =
        await c.read(sessionStoreProvider).loadSession();
    expect(restored!.user.id, 'u1');
  });

  test('restore loads a saved session', () async {
    final c = await makeContainer();
    await c.read(sessionProvider.notifier).signIn('http://srv', 'Srv', auth);
    c.read(sessionProvider.notifier).state = null;
    await c.read(sessionProvider.notifier).restore();
    expect(c.read(sessionProvider)!.accessToken, 'tok');
    expect(c.read(bootstrappedProvider), isTrue);
  });

  test('signOut clears session and pending server', () async {
    final c = await makeContainer();
    await c.read(sessionProvider.notifier).signIn('http://srv', 'Srv', auth);
    c.read(pendingServerProvider.notifier).state = 'http://srv';
    await c.read(sessionProvider.notifier).signOut();
    expect(c.read(sessionProvider), isNull);
    expect(c.read(pendingServerProvider), isNull);
    expect(
        await c.read(sessionStoreProvider).loadSession(), isNull);
  });

  test('profiles accumulate and removal works', () async {
    final c = await makeContainer();
    await c.read(sessionProvider.notifier).signIn('http://srv', 'Srv', auth);
    final profiles = c.read(sessionProvider.notifier).profiles();
    expect(profiles.single.userName, 'Cal');
    await c.read(profilesProvider.notifier).remove(profiles.single);
    expect(c.read(profilesProvider), isEmpty);
  });

  test('signInWithProfile fails without stored token', () async {
    final c = await makeContainer();
    const profile = SavedProfile(
        id: 'x|u1',
        serverUrl: 'http://x',
        serverName: 'X',
        userId: 'u1',
        userName: 'Cal');
    expect(
        await c
            .read(sessionProvider.notifier)
            .signInWithProfile(profile),
        isFalse);
  });

  test('client providers produce configured clients', () async {
    final c = await makeContainer();
    await c.read(sessionProvider.notifier).signIn('http://srv', 'Srv', auth);
    final client = c.read(jellyfinClientProvider);
    expect(client!.serverUrl, 'http://srv');
    expect(client.accessToken, 'tok');
    expect(client.userId, 'u1');
    final unauth = await c
        .read(sessionProvider.notifier)
        .unauthenticatedClient('http://other');
    expect(unauth.accessToken, isNull);
  });

  test('signInWithProfile succeeds when token and server check out',
      () async {
    final c = await makeContainer();
    await c.read(sessionProvider.notifier).signIn('http://srv', 'Srv', auth);
    await c.read(sessionProvider.notifier).signOut();
    const profile = SavedProfile(
        id: 'http://srv|u1',
        serverUrl: 'http://srv',
        serverName: 'Srv',
        userId: 'u1',
        userName: 'Cal');
    final ok = await c
        .read(sessionProvider.notifier)
        .signInWithProfile(profile);
    expect(ok, isTrue);
    expect(c.read(sessionProvider)!.serverUrl, 'http://srv');
  });

  test('authenticatedClient builds from the session', () async {
    final c = await makeContainer();
    await c.read(sessionProvider.notifier).signIn('http://srv', 'Srv', auth);
    final client =
        await c.read(sessionProvider.notifier).authenticatedClient();
    expect(client.accessToken, 'tok');
    expect(client.serverUrl, 'http://srv');
  });

  test('removeProfile deletes it', () async {
    final c = await makeContainer();
    await c.read(sessionProvider.notifier).signIn('http://srv', 'Srv', auth);
    final profile = c.read(sessionProvider.notifier).profiles().single;
    await c.read(sessionProvider.notifier).removeProfile(profile);
    expect(c.read(sessionProvider.notifier).profiles(), isEmpty);
  });

  test('probeServer resolves through clientFor', () async {
    final c = await makeContainer();
    final info = await c
        .read(sessionProvider.notifier)
        .probeServer('http://demo');
    expect(info.serverName, isNotEmpty);
  });

  test('signInWithProfile succeeds when token and server check out',
      () async {
    final c = await makeContainer();
    await c.read(sessionProvider.notifier).signIn('http://srv', 'Srv', auth);
    await c.read(sessionProvider.notifier).signOut();
    const profile = SavedProfile(
        id: 'http://srv|u1',
        serverUrl: 'http://srv',
        serverName: 'Srv',
        userId: 'u1',
        userName: 'Cal');
    final ok = await c
        .read(sessionProvider.notifier)
        .signInWithProfile(profile);
    expect(ok, isTrue);
    expect(c.read(sessionProvider)!.serverUrl, 'http://srv');
  });

  test('authenticatedClient builds from the session', () async {
    final c = await makeContainer();
    await c.read(sessionProvider.notifier).signIn('http://srv', 'Srv', auth);
    final client =
        await c.read(sessionProvider.notifier).authenticatedClient();
    expect(client.accessToken, 'tok');
    expect(client.serverUrl, 'http://srv');
  });

  test('removeProfile deletes it', () async {
    final c = await makeContainer();
    await c.read(sessionProvider.notifier).signIn('http://srv', 'Srv', auth);
    final profile = c.read(sessionProvider.notifier).profiles().single;
    await c.read(sessionProvider.notifier).removeProfile(profile);
    expect(c.read(sessionProvider.notifier).profiles(), isEmpty);
  });

  test('probeServer resolves through clientFor', () async {
    final c = await makeContainer();
    final info =
        await c.read(sessionProvider.notifier).probeServer('http://demo');
    expect(info.serverName, isNotEmpty);
  });
}
