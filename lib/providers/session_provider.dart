import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/jellyfin_client.dart';
import '../core/models/models.dart';
import '../core/storage/session_store.dart';
import 'core_providers.dart';

final sessionProvider =
    NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

final bootstrappedProvider = StateProvider<bool>((ref) => false);

final pendingServerProvider = StateProvider<String?>((ref) => null);

class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() => null;

  Future<void> restore() async {
    state = await ref.read(sessionStoreProvider).loadSession();
    ref.read(bootstrappedProvider.notifier).state = true;
  }

  Future<JellyfinClient> _clientFor(String serverUrl) async {
    final deviceId = await ref.read(deviceIdProvider.future);
    return JellyfinClient(serverUrl: serverUrl, deviceId: deviceId);
  }

  Future<PublicSystemInfo> probeServer(String serverUrl) async {
    final client = await _clientFor(serverUrl);
    return client.getPublicSystemInfo();
  }

  Future<void> signIn(
      String serverUrl, String serverName, AuthResult result) async {
    final session = Session(
      serverUrl: serverUrl,
      serverName: serverName,
      accessToken: result.accessToken,
      user: result.user,
    );
    await ref.read(sessionStoreProvider).saveSession(session);
    state = session;
  }

  Future<JellyfinClient> authenticatedClient() async {
    final session = state;
    if (session == null) {
      throw StateError('not signed in');
    }
    final deviceId = await ref.read(deviceIdProvider.future);
    return JellyfinClient(
      serverUrl: session.serverUrl,
      deviceId: deviceId,
      accessToken: session.accessToken,
      userId: session.user.id,
    );
  }

  Future<JellyfinClient> unauthenticatedClient(String serverUrl) =>
      _clientFor(serverUrl);

  Future<void> signOut() async {
    final store = ref.read(sessionStoreProvider);
    await store.clearSession();
    state = null;
    ref.read(pendingServerProvider.notifier).state = null;
  }

  Future<bool> signInWithProfile(SavedProfile profile) async {
    final token = await ref.read(sessionStoreProvider).profileToken(profile);
    if (token == null) return false;
    final deviceId = await ref.read(deviceIdProvider.future);
    final client = JellyfinClient(
      serverUrl: profile.serverUrl,
      deviceId: deviceId,
      accessToken: token,
      userId: profile.userId,
    );
    try {
      final user = await client.getCurrentUser();
      final session = Session(
        serverUrl: profile.serverUrl,
        serverName: profile.serverName,
        accessToken: token,
        user: user,
      );
      await ref.read(sessionStoreProvider).saveSession(session);
      state = session;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> removeProfile(SavedProfile profile) =>
      ref.read(sessionStoreProvider).removeProfile(profile);

  List<SavedProfile> profiles() =>
      ref.read(sessionStoreProvider).loadProfiles();
}

final profilesProvider =
    NotifierProvider<ProfilesNotifier, List<SavedProfile>>(
        ProfilesNotifier.new);

class ProfilesNotifier extends Notifier<List<SavedProfile>> {
  @override
  List<SavedProfile> build() =>
      ref.watch(sessionStoreProvider).loadProfiles();

  Future<void> refresh() async {
    state = ref.read(sessionStoreProvider).loadProfiles();
  }

  Future<void> remove(SavedProfile profile) async {
    await ref.read(sessionStoreProvider).removeProfile(profile);
    state = ref.read(sessionStoreProvider).loadProfiles();
  }
}

final jellyfinClientProvider = Provider<JellyfinClient?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  final deviceId = ref.watch(deviceIdProvider).valueOrNull ?? 'unknown';
  return JellyfinClient(
    serverUrl: session.serverUrl,
    deviceId: deviceId,
    accessToken: session.accessToken,
    userId: session.user.id,
  );
});
