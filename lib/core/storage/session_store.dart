import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

class SavedProfile {
  const SavedProfile({
    required this.id,
    required this.serverUrl,
    required this.serverName,
    required this.userId,
    required this.userName,
    this.imageTag,
  });

  final String id;
  final String serverUrl;
  final String serverName;
  final String userId;
  final String userName;
  final String? imageTag;

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverUrl': serverUrl,
        'serverName': serverName,
        'userId': userId,
        'userName': userName,
        'imageTag': imageTag,
      };

  factory SavedProfile.fromJson(Map<String, dynamic> json) => SavedProfile(
        id: json['id'] as String? ?? '',
        serverUrl: json['serverUrl'] as String? ?? '',
        serverName: json['serverName'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        imageTag: json['imageTag'] as String?,
      );

  static String idFor(String serverUrl, String userId) =>
      '$serverUrl|$userId';
}

class Session {
  const Session({
    required this.serverUrl,
    required this.serverName,
    required this.accessToken,
    required this.user,
  });

  final String serverUrl;
  final String serverName;
  final String accessToken;
  final JellyfinUser user;
}

class SessionStore {
  SessionStore(this._prefs, this._secure);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  static const _kDeviceId = 'session.deviceId';
  static const _kServerUrl = 'session.serverUrl';
  static const _kServerName = 'session.serverName';
  static const _kUserId = 'session.userId';
  static const _kUserName = 'session.userName';
  static const _kUserImage = 'session.userImageTag';
  static const _kToken = 'session.accessToken';
  static const _kProfiles = 'session.profiles';
  static String _tokenKey(String profileId) => 'token.$profileId';

  Future<String> deviceId() async {
    final existing = _prefs.getString(_kDeviceId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await _prefs.setString(_kDeviceId, id);
    return id;
  }

  Future<void> saveSession(Session session) async {
    await _prefs.setString(_kServerUrl, session.serverUrl);
    await _prefs.setString(_kServerName, session.serverName);
    await _prefs.setString(_kUserId, session.user.id);
    await _prefs.setString(_kUserName, session.user.name);
    if (session.user.primaryImageTag != null) {
      await _prefs.setString(_kUserImage, session.user.primaryImageTag!);
    } else {
      await _prefs.remove(_kUserImage);
    }
    await _secure.write(key: _kToken, value: session.accessToken);
    await saveProfile(session);
  }

  Future<Session?> loadSession() async {
    final serverUrl = _prefs.getString(_kServerUrl);
    final userId = _prefs.getString(_kUserId);
    final userName = _prefs.getString(_kUserName);
    final token = await _secure.read(key: _kToken);
    if (serverUrl == null || userId == null || token == null) return null;
    return Session(
      serverUrl: serverUrl,
      serverName: _prefs.getString(_kServerName) ?? '',
      accessToken: token,
      user: JellyfinUser(
        id: userId,
        name: userName ?? '',
        primaryImageTag: _prefs.getString(_kUserImage),
      ),
    );
  }

  Future<void> clearSession() async {
    await _prefs.remove(_kServerUrl);
    await _prefs.remove(_kServerName);
    await _prefs.remove(_kUserId);
    await _prefs.remove(_kUserName);
    await _prefs.remove(_kUserImage);
    await _secure.delete(key: _kToken);
  }

  Future<void> saveProfile(Session session) async {
    final profiles = loadProfiles();
    final id = SavedProfile.idFor(session.serverUrl, session.user.id);
    profiles.removeWhere((p) => p.id == id);
    profiles.add(SavedProfile(
      id: id,
      serverUrl: session.serverUrl,
      serverName: session.serverName,
      userId: session.user.id,
      userName: session.user.name,
      imageTag: session.user.primaryImageTag,
    ));
    await _prefs.setString(
        _kProfiles, jsonEncode(profiles.map((p) => p.toJson()).toList()));
    await _secure.write(
        key: _tokenKey(id), value: session.accessToken);
  }

  List<SavedProfile> loadProfiles() {
    final raw = _prefs.getString(_kProfiles);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(SavedProfile.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> profileToken(SavedProfile profile) =>
      _secure.read(key: _tokenKey(profile.id));

  Future<void> removeProfile(SavedProfile profile) async {
    final profiles = loadProfiles()..removeWhere((p) => p.id == profile.id);
    await _prefs.setString(
        _kProfiles, jsonEncode(profiles.map((p) => p.toJson()).toList()));
    await _secure.delete(key: _tokenKey(profile.id));
  }
}
