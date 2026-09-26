import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';
import '../core/storage/app_storage.dart';
import 'providers.dart';

sealed class SessionState {
  const SessionState();
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

/// No active session. Carries saved accounts so the user picker can
/// offer one-tap sign in.
class SignedOut extends SessionState {
  final List<SavedAccount> accounts;
  final String? lastServerUrl;
  const SignedOut({this.accounts = const [], this.lastServerUrl});
}

class SignedIn extends SessionState {
  final SavedAccount account;
  final List<JfLibrary> libraries;
  const SignedIn({required this.account, this.libraries = const []});
}

class SessionNotifier extends Notifier<SessionState> {
  AppStorage get _storage => ref.read(appStorageProvider);

  @override
  SessionState build() {
    Future.microtask(_restore);
    return const SessionLoading();
  }

  Future<void> _restore() async {
    final account = _storage.activeAccount();
    if (account == null) {
      state = SignedOut(accounts: _storage.accounts());
      return;
    }
    await _applyAccount(account);
  }

  Future<void> _applyAccount(SavedAccount account) async {
    final client = ref.read(jellyfinClientProvider);
    client.setServerUrl(account.serverUrl);
    client.setCredentials(
        accessToken: account.accessToken, userId: account.userId);
    await _storage.setActiveAccount(account.key);
    state = SignedIn(account: account);
    await refreshLibraries();
  }

  Future<void> refreshLibraries() async {
    final current = state;
    if (current is! SignedIn) return;
    try {
      final libs = await ref.read(jellyfinClientProvider).getLibraries();
      state = SignedIn(account: current.account, libraries: libs);
    } catch (_) {
      // Keep the session; a failed refresh just leaves libraries empty.
      state = current;
    }
  }

  /// Sign in with username/password against [serverUrl].
  /// Throws on failure so the UI can show the error.
  Future<void> signIn({
    required String serverUrl,
    required String serverName,
    required String username,
    required String password,
    String? imageTag,
  }) async {
    final client = ref.read(jellyfinClientProvider);
    client.setServerUrl(serverUrl);
    final result = await client.authenticate(username, password);
    final account = SavedAccount(
      serverUrl: client.serverUrl!,
      serverName: serverName,
      userId: result.user.id,
      userName: result.user.name,
      accessToken: result.accessToken,
      imageTag: imageTag ?? result.user.primaryImageTag,
    );
    await _storage.saveAccount(account);
    await _applyAccount(account);
  }

  /// Switch to an already-saved account.
  Future<void> switchAccount(SavedAccount account) async {
    await _applyAccount(account);
  }

  Future<void> removeAccount(SavedAccount account) async {
    await _storage.removeAccount(account.key);
    final current = state;
    if (current is SignedIn && current.account.key == account.key) {
      ref.read(jellyfinClientProvider).clearCredentials();
      state = SignedOut(accounts: _storage.accounts());
    } else if (current is SignedOut) {
      state = SignedOut(accounts: _storage.accounts());
    }
  }

  Future<void> signOut() async {
    final current = state;
    if (current is SignedIn) {
      try {
        await ref.read(jellyfinClientProvider).logout();
      } catch (_) {}
      await _storage.removeAccount(current.account.key);
      await _storage.setActiveAccount(null);
    }
    ref.read(jellyfinClientProvider).clearCredentials();
    state = SignedOut(accounts: _storage.accounts());
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);
