import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persisted account for one Jellyfin user on one server.
class SavedAccount {
  final String serverUrl;
  final String serverName;
  final String userId;
  final String userName;
  final String accessToken;
  final String? imageTag;

  const SavedAccount({
    required this.serverUrl,
    required this.serverName,
    required this.userId,
    required this.userName,
    required this.accessToken,
    this.imageTag,
  });

  factory SavedAccount.fromJson(Map<String, dynamic> j) => SavedAccount(
    serverUrl: j['serverUrl'] as String,
    serverName: j['serverName'] as String? ?? '',
    userId: j['userId'] as String,
    userName: j['userName'] as String? ?? '',
    accessToken: j['accessToken'] as String,
    imageTag: j['imageTag'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'serverUrl': serverUrl,
    'serverName': serverName,
    'userId': userId,
    'userName': userName,
    'accessToken': accessToken,
    'imageTag': imageTag,
  };

  String get key => '$serverUrl::$userId';
}

/// SharedPreferences-backed storage for accounts, the active session
/// pointer, and app settings.
class AppStorage {
  static const _accountsKey = 'accounts.v1';
  static const _activeKey = 'activeAccount.v1';
  static const _settingsKey = 'settings.v1';
  static const _deviceIdKey = 'deviceId.v1';

  final SharedPreferences _prefs;

  AppStorage(this._prefs);

  List<SavedAccount> accounts() {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => SavedAccount.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAccount(SavedAccount account) async {
    final all = accounts();
    all.removeWhere((a) => a.key == account.key);
    all.add(account);
    await _prefs.setString(
      _accountsKey,
      jsonEncode(all.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> removeAccount(String key) async {
    final all = accounts()..removeWhere((a) => a.key == key);
    await _prefs.setString(
      _accountsKey,
      jsonEncode(all.map((a) => a.toJson()).toList()),
    );
    if (activeAccountKey() == key) {
      await _prefs.remove(_activeKey);
    }
  }

  String? activeAccountKey() => _prefs.getString(_activeKey);

  SavedAccount? activeAccount() {
    final key = activeAccountKey();
    if (key == null) return null;
    for (final a in accounts()) {
      if (a.key == key) return a;
    }
    return null;
  }

  Future<void> setActiveAccount(String? key) async {
    if (key == null) {
      await _prefs.remove(_activeKey);
    } else {
      await _prefs.setString(_activeKey, key);
    }
  }

  Map<String, dynamic> settings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> saveSettings(Map<String, dynamic> settings) =>
      _prefs.setString(_settingsKey, jsonEncode(settings));

  String deviceId() => _prefs.getString(_deviceIdKey) ?? '';

  Future<void> setDeviceId(String id) => _prefs.setString(_deviceIdKey, id);

  /// Generic string storage for feature manifests (downloads, etc).
  String? getRaw(String key) => _prefs.getString(key);

  Future<void> setRaw(String key, String value) => _prefs.setString(key, value);
}
