import 'package:hive_flutter/hive_flutter.dart';
import 'jellyfin_api.dart';
import 'models/user.dart';

/// Stored session for one Jellyfin account (profile)
class SavedProfile {
  final String serverUrl;
  final String userId;
  final String accessToken;
  final String userName;
  final String? primaryImageTag;
  final String? serverId;
  final String? serverName;
  final DateTime? lastUsedAt;

  const SavedProfile({
    required this.serverUrl,
    required this.userId,
    required this.accessToken,
    required this.userName,
    this.primaryImageTag,
    this.serverId,
    this.serverName,
    this.lastUsedAt,
  });

  String get avatarUrl {
    if (primaryImageTag == null || serverUrl.isEmpty) return '';
    return '$serverUrl/Users/$userId/Images/Primary?tag=$primaryImageTag';
  }

  String get displayLetter {
    final t = userName.trim();
    return t.isEmpty ? '?' : t.toUpperCase().substring(0, 1);
  }

  bool isSameProfile(SavedProfile other) =>
      serverUrl == other.serverUrl && userId == other.userId;

  factory SavedProfile.fromJson(Map<String, dynamic> json) {
    return SavedProfile(
      serverUrl: json['serverUrl'] as String,
      userId: json['userId'] as String,
      accessToken: json['accessToken'] as String,
      userName: json['userName'] as String,
      primaryImageTag: json['primaryImageTag'] as String?,
      serverId: json['serverId'] as String?,
      serverName: json['serverName'] as String?,
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.tryParse(json['lastUsedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'userId': userId,
      'accessToken': accessToken,
      'userName': userName,
      'primaryImageTag': primaryImageTag,
      'serverId': serverId,
      'serverName': serverName,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  SavedProfile copyWith({
    String? serverUrl,
    String? userId,
    String? accessToken,
    String? userName,
    String? primaryImageTag,
    String? serverId,
    String? serverName,
    DateTime? lastUsedAt,
  }) {
    return SavedProfile(
      serverUrl: serverUrl ?? this.serverUrl,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      userName: userName ?? this.userName,
      primaryImageTag: primaryImageTag ?? this.primaryImageTag,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

/// Service for handling authentication and session management
class AuthService {
  static const _boxName = 'auth';
  static const _keyCurrentServer = 'current_server';
  static const _keyCurrentUser = 'current_user';
  static const _keyAccessToken = 'access_token';
  static const _keyServers = 'servers';
  static const _keySavedProfiles = 'saved_profiles';

  Box? _authBox;
  bool _initialized = false;
  final JellyfinApi _api;

  AuthService(this._api);

  /// Initialize the auth service
  Future<void> init() async {
    if (_initialized) return;
    _authBox = await Hive.openBox(_boxName);
    _initialized = true;
    await _migrateToSavedProfilesIfNeeded();
  }

  /// Migrate existing single session to saved_profiles so existing users keep one profile
  Future<void> _migrateToSavedProfilesIfNeeded() async {
    final data = _authBox?.get(_keySavedProfiles) as List<dynamic>?;
    if (data != null && data.isNotEmpty) return; // Already migrated
    final serverUrl = _authBox?.get(_keyCurrentServer) as String?;
    final userId = _authBox?.get(_keyCurrentUser) as String?;
    final token = _authBox?.get(_keyAccessToken) as String?;
    if (serverUrl == null || userId == null || token == null) return;
    final servers = savedServers;
    SavedServer? match;
    for (final s in servers) {
      if (s.url == serverUrl) {
        match = s;
        break;
      }
    }
    final userName = match?.lastUserName ?? 'User';
    final profile = SavedProfile(
      serverUrl: serverUrl,
      userId: userId,
      accessToken: token,
      userName: userName,
      serverId: match?.serverId,
      serverName: match?.name,
      lastUsedAt: DateTime.now(),
    );
    await _authBox!.put(
      _keySavedProfiles,
      [profile.toJson()],
    );
  }

  /// Check if user is logged in
  bool get isLoggedIn {
    final token = _authBox?.get(_keyAccessToken) as String?;
    final userId = _authBox?.get(_keyCurrentUser) as String?;
    return token != null && userId != null;
  }

  /// Get current server URL
  String? get currentServerUrl {
    return _authBox?.get(_keyCurrentServer) as String?;
  }

  /// Get current user ID
  String? get currentUserId {
    return _authBox?.get(_keyCurrentUser) as String?;
  }

  /// Get access token
  String? get accessToken {
    return _authBox?.get(_keyAccessToken) as String?;
  }

  /// Get saved servers
  List<SavedServer> get savedServers {
    final data = _authBox?.get(_keyServers) as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => SavedServer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Get saved profiles (multiple Jellyfin accounts).
  /// If list is empty but current session exists, syncs current session into saved_profiles (recovery).
  List<SavedProfile> get savedProfiles {
    final data = _authBox?.get(_keySavedProfiles) as List<dynamic>?;
    List<SavedProfile> profiles = [];
    if (data != null && data.isNotEmpty) {
      profiles = data
          .map((e) => SavedProfile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (profiles.isEmpty &&
        currentServerUrl != null &&
        currentUserId != null &&
        accessToken != null &&
        _authBox != null) {
      final serverUrl = currentServerUrl!;
      final userId = currentUserId!;
      final token = accessToken!;
      SavedServer? match;
      for (final s in savedServers) {
        if (s.url == serverUrl) {
          match = s;
          break;
        }
      }
      final userName = match?.lastUserName ?? 'User';
      final profile = SavedProfile(
        serverUrl: serverUrl,
        userId: userId,
        accessToken: token,
        userName: userName,
        serverId: match?.serverId,
        serverName: match?.name,
        lastUsedAt: DateTime.now(),
      );
      profiles = [profile];
      _authBox!.put(
        _keySavedProfiles,
        profiles.map((p) => p.toJson()).toList(),
      );
    }
    return profiles;
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
    
    await _authBox!.put(
      _keyServers,
      servers.map((s) => s.toJson()).toList(),
    );
  }

  /// Remove a server
  Future<void> removeServer(String url) async {
    final servers = savedServers;
    servers.removeWhere((s) => s.url == url);
    await _authBox!.put(
      _keyServers,
      servers.map((s) => s.toJson()).toList(),
    );
  }

  /// Connect to a server
  Future<bool> connectToServer(String url) async {
    try {
      if (await _api.testConnection(url)) {
        _api.setServerUrl(url);
        await _authBox!.put(_keyCurrentServer, url);
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

  /// Save session data and add/update profile
  Future<void> _saveSession(AuthenticationResult result) async {
    await _authBox!.put(_keyCurrentServer, result.serverUrl);
    await _authBox!.put(_keyCurrentUser, result.user.id);
    await _authBox!.put(_keyAccessToken, result.accessToken);

    // Update saved server with user info
    final server = SavedServer(
      url: result.serverUrl,
      name: result.user.serverName ?? 'Jellyfin',
      serverId: result.serverId,
      lastUserId: result.user.id,
      lastUserName: result.user.name,
    );
    await addServer(server);

    // Add or update saved profile
    final profile = SavedProfile(
      serverUrl: result.serverUrl,
      userId: result.user.id,
      accessToken: result.accessToken,
      userName: result.user.name,
      primaryImageTag: result.user.primaryImageTag,
      serverId: result.serverId,
      serverName: result.user.serverName ?? 'Jellyfin',
      lastUsedAt: DateTime.now(),
    );
    final profiles = savedProfiles;
    final index = profiles.indexWhere((p) => p.isSameProfile(profile));
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    await _authBox!.put(
      _keySavedProfiles,
      profiles.map((p) => p.toJson()).toList(),
    );
  }

  /// Clear current session
  Future<void> clearSession() async {
    await _authBox?.delete(_keyCurrentUser);
    await _authBox?.delete(_keyAccessToken);
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

  /// Set active session from a saved profile (no API logout)
  Future<void> setActiveProfile(SavedProfile profile) async {
    _api.setServerUrl(profile.serverUrl);
    _api.setCredentials(
      accessToken: profile.accessToken,
      userId: profile.userId,
    );
    await _authBox!.put(_keyCurrentServer, profile.serverUrl);
    await _authBox!.put(_keyCurrentUser, profile.userId);
    await _authBox!.put(_keyAccessToken, profile.accessToken);
    // Update lastUsedAt for this profile
    final profiles = savedProfiles;
    final index = profiles.indexWhere((p) => p.isSameProfile(profile));
    if (index >= 0) {
      profiles[index] = profile.copyWith(lastUsedAt: DateTime.now());
      await _authBox!.put(
        _keySavedProfiles,
        profiles.map((p) => p.toJson()).toList(),
      );
    }
  }

  /// Remove a profile from saved list. If it was current, clear session only (no API logout).
  Future<void> removeProfile(SavedProfile profile) async {
    final profiles = savedProfiles;
    final wasCurrent = currentUserId == profile.userId &&
        currentServerUrl == profile.serverUrl;
    profiles.removeWhere((p) => p.isSameProfile(profile));
    await _authBox!.put(
      _keySavedProfiles,
      profiles.map((p) => p.toJson()).toList(),
    );
    if (wasCurrent) {
      await clearSession();
    }
  }

  /// Clear current session only (for 2+ profiles launch: show Who's watching with no active session)
  Future<void> clearCurrentSessionOnly() async {
    await _authBox?.delete(_keyCurrentUser);
    await _authBox?.delete(_keyAccessToken);
    _api.clearCredentials();
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
