import 'package:hive_flutter/hive_flutter.dart';
import 'jellyfin_api.dart';
import 'models/user.dart';

/// Service for handling authentication and session management
class AuthService {
  static const _boxName = 'auth';
  static const _keyCurrentServer = 'current_server';
  static const _keyCurrentUser = 'current_user';
  static const _keyAccessToken = 'access_token';
  static const _keyServers = 'servers';

  late Box _authBox;
  final JellyfinApi _api;

  AuthService(this._api);

  /// Initialize the auth service
  Future<void> init() async {
    await Hive.initFlutter();
    _authBox = await Hive.openBox(_boxName);
  }

  /// Check if user is logged in
  bool get isLoggedIn {
    final token = _authBox.get(_keyAccessToken) as String?;
    final userId = _authBox.get(_keyCurrentUser) as String?;
    return token != null && userId != null;
  }

  /// Get current server URL
  String? get currentServerUrl {
    return _authBox.get(_keyCurrentServer) as String?;
  }

  /// Get current user ID
  String? get currentUserId {
    return _authBox.get(_keyCurrentUser) as String?;
  }

  /// Get access token
  String? get accessToken {
    return _authBox.get(_keyAccessToken) as String?;
  }

  /// Get saved servers
  List<SavedServer> get savedServers {
    final data = _authBox.get(_keyServers) as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => SavedServer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Add a new server
  Future<void> addServer(SavedServer server) async {
    final servers = savedServers;
    final existingIndex = servers.indexWhere((s) => s.url == server.url);
    
    if (existingIndex >= 0) {
      servers[existingIndex] = server;
    } else {
      servers.add(server);
    }
    
    await _authBox.put(
      _keyServers,
      servers.map((s) => s.toJson()).toList(),
    );
  }

  /// Remove a server
  Future<void> removeServer(String url) async {
    final servers = savedServers;
    servers.removeWhere((s) => s.url == url);
    await _authBox.put(
      _keyServers,
      servers.map((s) => s.toJson()).toList(),
    );
  }

  /// Connect to a server
  Future<bool> connectToServer(String url) async {
    try {
      if (await _api.testConnection(url)) {
        _api.setServerUrl(url);
        await _authBox.put(_keyCurrentServer, url);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Login with username and password
  Future<AuthenticationResult> login({
    required String username,
    required String password,
  }) async {
    final result = await _api.authenticate(
      username: username,
      password: password,
    );

    await _saveSession(result);
    return result;
  }

  /// Login with quick connect
  Future<String> initiateQuickConnect() async {
    return await _api.initiateQuickConnect();
  }

  /// Check quick connect status
  Future<AuthenticationResult?> checkQuickConnect(String secret) async {
    final result = await _api.checkQuickConnect(secret);
    if (result != null) {
      await _saveSession(result);
    }
    return result;
  }

  /// Restore session from storage
  Future<bool> restoreSession() async {
    final serverUrl = currentServerUrl;
    final userId = currentUserId;
    final token = accessToken;

    if (serverUrl == null || userId == null || token == null) {
      return false;
    }

    try {
      _api.setServerUrl(serverUrl);
      _api.setCredentials(accessToken: token, userId: userId);
      
      // Verify the session is still valid
      await _api.getCurrentUser();
      return true;
    } catch (_) {
      await clearSession();
      return false;
    }
  }

  /// Save session data
  Future<void> _saveSession(AuthenticationResult result) async {
    await _authBox.put(_keyCurrentServer, result.serverUrl);
    await _authBox.put(_keyCurrentUser, result.user.id);
    await _authBox.put(_keyAccessToken, result.accessToken);

    // Update saved server with user info
    final server = SavedServer(
      url: result.serverUrl,
      name: result.user.serverName ?? 'Jellyfin',
      serverId: result.serverId,
      lastUserId: result.user.id,
      lastUserName: result.user.name,
    );
    await addServer(server);
  }

  /// Clear current session
  Future<void> clearSession() async {
    await _authBox.delete(_keyCurrentUser);
    await _authBox.delete(_keyAccessToken);
    _api.clearCredentials();
  }

  /// Logout completely
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Ignore errors during logout
    }
    await clearSession();
  }

  /// Switch to a different user on the same server
  Future<AuthenticationResult> switchUser({
    required String username,
    required String password,
  }) async {
    await clearSession();
    return await login(username: username, password: password);
  }
}

/// Saved server information
class SavedServer {
  final String url;
  final String name;
  final String? serverId;
  final String? lastUserId;
  final String? lastUserName;
  final DateTime? lastConnected;

  const SavedServer({
    required this.url,
    required this.name,
    this.serverId,
    this.lastUserId,
    this.lastUserName,
    this.lastConnected,
  });

  factory SavedServer.fromJson(Map<String, dynamic> json) {
    return SavedServer(
      url: json['url'] as String,
      name: json['name'] as String,
      serverId: json['serverId'] as String?,
      lastUserId: json['lastUserId'] as String?,
      lastUserName: json['lastUserName'] as String?,
      lastConnected: json['lastConnected'] != null
          ? DateTime.tryParse(json['lastConnected'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'name': name,
      'serverId': serverId,
      'lastUserId': lastUserId,
      'lastUserName': lastUserName,
      'lastConnected': lastConnected?.toIso8601String(),
    };
  }

  SavedServer copyWith({
    String? url,
    String? name,
    String? serverId,
    String? lastUserId,
    String? lastUserName,
    DateTime? lastConnected,
  }) {
    return SavedServer(
      url: url ?? this.url,
      name: name ?? this.name,
      serverId: serverId ?? this.serverId,
      lastUserId: lastUserId ?? this.lastUserId,
      lastUserName: lastUserName ?? this.lastUserName,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }
}
