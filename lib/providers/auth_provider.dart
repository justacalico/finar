import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

/// Helper to convert exceptions to user-friendly messages
String _getErrorMessage(dynamic error) {
  if (kDebugMode) {
    print('Auth error: $error');
  }
  
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your server URL and network connection.';
      case DioExceptionType.connectionError:
        return 'Could not connect to server. Please check the URL and ensure the server is running.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Invalid username or password.';
        } else if (statusCode == 403) {
          return 'Access denied. Your account may be disabled.';
        } else if (statusCode == 404) {
          return 'Server not found. Please check the URL.';
        } else if (statusCode != null && statusCode >= 500) {
          return 'Server error. Please try again later.';
        }
        return 'Server returned an error (${statusCode ?? 'unknown'}).';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        if (error.error.toString().contains('XMLHttpRequest')) {
          return 'Network request blocked. This may be a CORS issue - the server may need to allow requests from this origin.';
        }
        if (error.error.toString().contains('SocketException') ||
            error.error.toString().contains('Connection refused')) {
          return 'Could not connect to server. Please verify the server is running and accessible.';
        }
        return 'Network error. Please check your connection.';
      default:
        return 'Connection error. Please try again.';
    }
  }
  
  final errorString = error.toString().toLowerCase();
  if (errorString.contains('socketexception') || 
      errorString.contains('connection refused')) {
    return 'Could not connect to server. Please check the URL.';
  }
  if (errorString.contains('handshake') || 
      errorString.contains('certificate')) {
    return 'SSL/TLS error. The server certificate may be invalid.';
  }
  if (errorString.contains('timeout')) {
    return 'Connection timed out. Please try again.';
  }
  if (errorString.contains('cors') || 
      errorString.contains('xmlhttprequest')) {
    return 'Cross-origin request blocked. Please check server CORS settings.';
  }
  
  return 'An error occurred. Please try again.';
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final JellyfinApi _api;

  AuthNotifier(this._authService, this._api) : super(const AuthState.initial());

  /// Initialize auth state. With 2+ profiles, do not restore; show Who's watching.
  Future<void> initialize() async {
    state = const AuthState.loading();
    try {
      await _authService.init();
      final profiles = _authService.savedProfiles;
      if (profiles.length >= 2) {
        await _authService.clearCurrentSessionOnly();
        state = const AuthState.unauthenticated();
        return;
      }
      if (profiles.length == 1) {
        await _authService.setActiveProfile(profiles.first);
      }
      final restored = await _authService.restoreSession();
      if (restored) {
        final user = await _api.getCurrentUser();
        state = AuthState.authenticated(user: user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      // If restore fails, just show login screen instead of error
      state = const AuthState.unauthenticated();
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
        state = const AuthState.error('Could not connect to server. Please check the URL.');
        return false;
      }
    } catch (e) {
      state = AuthState.error(_getErrorMessage(e));
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
        try {
          final connected = await _authService.connectToServer(serverUrl);
          if (!connected) {
            state = const AuthState.error('Could not connect to server. Please check the URL and ensure the server is running.');
            return false;
          }
        } catch (e) {
          state = AuthState.error(_getErrorMessage(e));
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
      state = AuthState.error(_getErrorMessage(e));
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

  /// Select a saved profile and set as active session.
  /// On failure (e.g. expired token), reverts to previous session so the user is not logged out.
  Future<bool> selectProfile(SavedProfile profile) async {
    final previousUser = state is _AuthAuthenticated ? (state as _AuthAuthenticated).user : null;
    SavedProfile? previousProfile;
    if (previousUser != null) {
      try {
        previousProfile = _authService.savedProfiles
            .firstWhere((p) => p.userId == previousUser.id);
      } catch (_) {
        previousProfile = null;
      }
    }

    state = const AuthState.loading();
    try {
      await _authService.setActiveProfile(profile);
      final user = await _api.getCurrentUser();
      state = AuthState.authenticated(user: user);
      return true;
    } catch (e) {
      if (previousProfile != null) {
        await _authService.setActiveProfile(previousProfile);
        state = AuthState.authenticated(user: previousUser!);
      } else {
        state = AuthState.error(_getErrorMessage(e));
      }
      return false;
    }
  }

  /// Remove a profile from the list. If it was current, state becomes unauthenticated or another profile.
  Future<void> removeProfile(SavedProfile profile) async {
    await _authService.removeProfile(profile);
    final currentUserId = _authService.currentUserId;
    final currentServerUrl = _authService.currentServerUrl;
    if (currentUserId == null || currentServerUrl == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final user = await _api.getCurrentUser();
      state = AuthState.authenticated(user: user);
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Clear current session but keep saved profiles (e.g. after Add profile login to show Who's watching).
  Future<void> clearCurrentSessionForProfilePicker() async {
    await _authService.clearCurrentSessionOnly();
    state = const AuthState.unauthenticated();
  }
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
  @override
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

/// Saved profiles (multiple Jellyfin accounts) for Who's watching.
/// Depends on authProvider so the list is recomputed after init (avoids showing
/// empty list when opening Who's watching from Switch profile).
final savedProfilesProvider = Provider<List<SavedProfile>>((ref) {
  ref.watch(authProvider);
  final authService = ref.watch(authServiceProvider);
  return authService.savedProfiles;
});
