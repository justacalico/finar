import 'package:hive/hive.dart';

part 'user.g.dart';

/// Helper to safely parse int from JSON (handles String and num)
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? serverId;

  @HiveField(3)
  final String? serverName;

  @HiveField(4)
  final String? primaryImageTag;

  @HiveField(5)
  final bool hasPassword;

  @HiveField(6)
  final bool hasConfiguredPassword;

  @HiveField(7)
  final bool hasConfiguredEasyPassword;

  @HiveField(8)
  final DateTime? lastLoginDate;

  @HiveField(9)
  final DateTime? lastActivityDate;

  @HiveField(10)
  final UserPolicy? policy;

  @HiveField(11)
  final UserConfiguration? configuration;

  const User({
    required this.id,
    required this.name,
    this.serverId,
    this.serverName,
    this.primaryImageTag,
    this.hasPassword = false,
    this.hasConfiguredPassword = false,
    this.hasConfiguredEasyPassword = false,
    this.lastLoginDate,
    this.lastActivityDate,
    this.policy,
    this.configuration,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['Id'] as String,
      name: json['Name'] as String,
      serverId: json['ServerId'] as String?,
      serverName: json['ServerName'] as String?,
      primaryImageTag: json['PrimaryImageTag'] as String?,
      hasPassword: json['HasPassword'] as bool? ?? false,
      hasConfiguredPassword: json['HasConfiguredPassword'] as bool? ?? false,
      hasConfiguredEasyPassword: json['HasConfiguredEasyPassword'] as bool? ?? false,
      lastLoginDate: json['LastLoginDate'] != null
          ? DateTime.tryParse(json['LastLoginDate'] as String)
          : null,
      lastActivityDate: json['LastActivityDate'] != null
          ? DateTime.tryParse(json['LastActivityDate'] as String)
          : null,
      policy: json['Policy'] != null
          ? UserPolicy.fromJson(json['Policy'] as Map<String, dynamic>)
          : null,
      configuration: json['Configuration'] != null
          ? UserConfiguration.fromJson(json['Configuration'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'ServerId': serverId,
      'ServerName': serverName,
      'PrimaryImageTag': primaryImageTag,
      'HasPassword': hasPassword,
      'HasConfiguredPassword': hasConfiguredPassword,
      'HasConfiguredEasyPassword': hasConfiguredEasyPassword,
      'LastLoginDate': lastLoginDate?.toIso8601String(),
      'LastActivityDate': lastActivityDate?.toIso8601String(),
      'Policy': policy?.toJson(),
      'Configuration': configuration?.toJson(),
    };
  }

  String getAvatarUrl(String baseUrl) {
    if (primaryImageTag == null) return '';
    return '$baseUrl/Users/$id/Images/Primary?tag=$primaryImageTag';
  }
}

@HiveType(typeId: 1)
class UserPolicy {
  @HiveField(0)
  final bool isAdministrator;

  @HiveField(1)
  final bool isHidden;

  @HiveField(2)
  final bool isDisabled;

  @HiveField(3)
  final bool enableAllDevices;

  @HiveField(4)
  final bool enableAllFolders;

  @HiveField(5)
  final bool enableAllChannels;

  @HiveField(6)
  final List<String>? enabledFolders;

  @HiveField(7)
  final int? maxParentalRating;

  const UserPolicy({
    this.isAdministrator = false,
    this.isHidden = false,
    this.isDisabled = false,
    this.enableAllDevices = true,
    this.enableAllFolders = true,
    this.enableAllChannels = true,
    this.enabledFolders,
    this.maxParentalRating,
  });

  factory UserPolicy.fromJson(Map<String, dynamic> json) {
    return UserPolicy(
      isAdministrator: json['IsAdministrator'] as bool? ?? false,
      isHidden: json['IsHidden'] as bool? ?? false,
      isDisabled: json['IsDisabled'] as bool? ?? false,
      enableAllDevices: json['EnableAllDevices'] as bool? ?? true,
      enableAllFolders: json['EnableAllFolders'] as bool? ?? true,
      enableAllChannels: json['EnableAllChannels'] as bool? ?? true,
      enabledFolders: (json['EnabledFolders'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      maxParentalRating: _parseInt(json['MaxParentalRating']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'IsAdministrator': isAdministrator,
      'IsHidden': isHidden,
      'IsDisabled': isDisabled,
      'EnableAllDevices': enableAllDevices,
      'EnableAllFolders': enableAllFolders,
      'EnableAllChannels': enableAllChannels,
      'EnabledFolders': enabledFolders,
      'MaxParentalRating': maxParentalRating,
    };
  }
}

@HiveType(typeId: 2)
class UserConfiguration {
  @HiveField(0)
  final String? audioLanguagePreference;

  @HiveField(1)
  final bool playDefaultAudioTrack;

  @HiveField(2)
  final String? subtitleLanguagePreference;

  @HiveField(3)
  final bool displayMissingEpisodes;

  @HiveField(4)
  final String? subtitleMode;

  @HiveField(5)
  final bool enableLocalPassword;

  @HiveField(6)
  final bool hidePlayedInLatest;

  @HiveField(7)
  final bool rememberAudioSelections;

  @HiveField(8)
  final bool rememberSubtitleSelections;

  const UserConfiguration({
    this.audioLanguagePreference,
    this.playDefaultAudioTrack = true,
    this.subtitleLanguagePreference,
    this.displayMissingEpisodes = false,
    this.subtitleMode,
    this.enableLocalPassword = false,
    this.hidePlayedInLatest = false,
    this.rememberAudioSelections = true,
    this.rememberSubtitleSelections = true,
  });

  factory UserConfiguration.fromJson(Map<String, dynamic> json) {
    return UserConfiguration(
      audioLanguagePreference: json['AudioLanguagePreference'] as String?,
      playDefaultAudioTrack: json['PlayDefaultAudioTrack'] as bool? ?? true,
      subtitleLanguagePreference: json['SubtitleLanguagePreference'] as String?,
      displayMissingEpisodes: json['DisplayMissingEpisodes'] as bool? ?? false,
      subtitleMode: json['SubtitleMode'] as String?,
      enableLocalPassword: json['EnableLocalPassword'] as bool? ?? false,
      hidePlayedInLatest: json['HidePlayedInLatest'] as bool? ?? false,
      rememberAudioSelections: json['RememberAudioSelections'] as bool? ?? true,
      rememberSubtitleSelections: json['RememberSubtitleSelections'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AudioLanguagePreference': audioLanguagePreference,
      'PlayDefaultAudioTrack': playDefaultAudioTrack,
      'SubtitleLanguagePreference': subtitleLanguagePreference,
      'DisplayMissingEpisodes': displayMissingEpisodes,
      'SubtitleMode': subtitleMode,
      'EnableLocalPassword': enableLocalPassword,
      'HidePlayedInLatest': hidePlayedInLatest,
      'RememberAudioSelections': rememberAudioSelections,
      'RememberSubtitleSelections': rememberSubtitleSelections,
    };
  }
}

@HiveType(typeId: 3)
class AuthenticationResult {
  @HiveField(0)
  final User user;

  @HiveField(1)
  final String accessToken;

  @HiveField(2)
  final String serverId;

  @HiveField(3)
  final String serverUrl;

  const AuthenticationResult({
    required this.user,
    required this.accessToken,
    required this.serverId,
    required this.serverUrl,
  });

  factory AuthenticationResult.fromJson(Map<String, dynamic> json, String serverUrl) {
    return AuthenticationResult(
      user: User.fromJson(json['User'] as Map<String, dynamic>),
      accessToken: json['AccessToken'] as String,
      serverId: json['ServerId'] as String,
      serverUrl: serverUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'User': user.toJson(),
      'AccessToken': accessToken,
      'ServerId': serverId,
      'ServerUrl': serverUrl,
    };
  }
}
