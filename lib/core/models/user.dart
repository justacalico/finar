class JellyfinUser {
  const JellyfinUser({
    required this.id,
    required this.name,
    this.primaryImageTag,
    this.isAdministrator = false,
  });

  final String id;
  final String name;
  final String? primaryImageTag;
  final bool isAdministrator;

  factory JellyfinUser.fromJson(Map<String, dynamic> json) {
    final policy = json['Policy'];
    return JellyfinUser(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      primaryImageTag: json['PrimaryImageTag'] as String?,
      isAdministrator:
          policy is Map<String, dynamic> && policy['IsAdministrator'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'Id': id,
        'Name': name,
        'PrimaryImageTag': primaryImageTag,
        'Policy': {'IsAdministrator': isAdministrator},
      };
}

class AuthResult {
  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.serverId,
    this.sessionId,
  });

  final JellyfinUser user;
  final String accessToken;
  final String serverId;
  final String? sessionId;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        user: JellyfinUser.fromJson(
            json['User'] as Map<String, dynamic>? ?? const {}),
        accessToken: json['AccessToken'] as String? ?? '',
        serverId: json['ServerId'] as String? ?? '',
        sessionId: json['SessionId'] as String?,
      );
}

class PublicSystemInfo {
  const PublicSystemInfo({
    required this.serverName,
    required this.version,
    required this.id,
    this.productName = 'Jellyfin Server',
  });

  final String serverName;
  final String version;
  final String id;
  final String productName;

  factory PublicSystemInfo.fromJson(Map<String, dynamic> json) =>
      PublicSystemInfo(
        serverName: json['ServerName'] as String? ?? '',
        version: json['Version'] as String? ?? '',
        id: json['Id'] as String? ?? '',
        productName: json['ProductName'] as String? ?? 'Jellyfin Server',
      );
}

class QuickConnectResult {
  const QuickConnectResult({required this.code, required this.secret});

  final String code;
  final String secret;

  factory QuickConnectResult.fromJson(Map<String, dynamic> json) =>
      QuickConnectResult(
        code: json['Code'] as String? ?? '',
        secret: json['Secret'] as String? ?? '',
      );
}
