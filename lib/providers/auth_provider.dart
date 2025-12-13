import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/jellyfin_api.dart';
import '../core/api/auth_service.dart';
import '../core/api/models/user.dart';

/// Jellyfin API instance provider
final jellyfinApiProvider = Provider<JellyfinApi>((ref) {
  return JellyfinApi();
});

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.watch(jellyfinApiProvider);
  return AuthService(api);
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final JellyfinApi _api;

  AuthNotifier(this._authService, this._api) : super(const AuthState.initial());

  /// Initialize auth state
  Future<void> initialize() async {
    state = const AuthState.loading();
    try {
      await _authService.init();
      final restored = await _authService.restoreSession();
      if (restored) {
        final user = await _api.getCurrentUser();
        state = AuthState.authenticated(user: user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Connect to server
  Future<bool> connectToServer(String url) async {
    state = const AuthState.loading();
    try {
      final connected = await _authService.connectToServer(url);
      if (connected) {
        state = const AuthState.serverConnected();
        return true;
      } else {
        state = const AuthState.error('Failed to connect to server');
        return false;
      }
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Restore session from storage (alias for initialize)
  Future<void> restoreSession() async {
    await initialize();
  }

  /// Login with credentials
  Future<bool> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async {
    state = const AuthState.loading();
    try {
      // Ensure auth service is initialized
      await _authService.init();
      
      // Connect to server first if URL provided
      if (serverUrl != null && serverUrl.isNotEmpty) {
        final connected = await _authService.connectToServer(serverUrl);
        if (!connected) {
          state = const AuthState.error('Failed to connect to server');
          return false;
        }
      }
      
      final result = await _authService.login(
        username: username,
        password: password,
      );
      state = AuthState.authenticated(user: result.user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Initiate quick connect
  Future<String?> initiateQuickConnect() async {
    try {
      return await _authService.initiateQuickConnect();
    } catch (_) {
      return null;
    }
  }

  /// Check quick connect status
  Future<bool> checkQuickConnect(String secret) async {
    try {
      final result = await _authService.checkQuickConnect(secret);
      if (result != null) {
        state = AuthState.authenticated(user: result.user);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = const AuthState.loading();
    try {
      await _authService.logout();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Get saved servers
  List<SavedServer> get savedServers => _authService.savedServers;

  /// Get server URL
  String? get serverUrl => _api.serverUrl;
}

/// Auth state
abstract class AuthState {
  const AuthState();

  const factory AuthState.initial() = _AuthInitial;
  const factory AuthState.loading() = _AuthLoading;
  const factory AuthState.unauthenticated() = _AuthUnauthenticated;
  const factory AuthState.serverConnected() = _AuthServerConnected;
  const factory AuthState.authenticated({required User user}) = _AuthAuthenticated;
  const factory AuthState.error(String message) = _AuthError;

  bool get isLoading => this is _AuthLoading || this is _AuthInitial;
  bool get isAuthenticated => this is _AuthAuthenticated;
  bool get isUnauthenticated => this is _AuthUnauthenticated;
  bool get isServerConnected => this is _AuthServerConnected;
  bool get hasError => this is _AuthError;

  User? get user => this is _AuthAuthenticated ? (this as _AuthAuthenticated).user : null;
  String? get errorMessage => this is _AuthError ? (this as _AuthError).message : null;
}

class _AuthInitial extends AuthState {
  const _AuthInitial();
}

class _AuthLoading extends AuthState {
  const _AuthLoading();
}

class _AuthUnauthenticated extends AuthState {
  const _AuthUnauthenticated();
}

class _AuthServerConnected extends AuthState {
  const _AuthServerConnected();
}

class _AuthAuthenticated extends AuthState {
  final User user;
  const _AuthAuthenticated({required this.user});
}

class _AuthError extends AuthState {
  final String message;
  const _AuthError(this.message);
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final api = ref.watch(jellyfinApiProvider);
  return AuthNotifier(authService, api);
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});
