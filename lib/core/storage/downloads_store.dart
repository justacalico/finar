import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum DownloadStatus { queued, downloading, completed, failed }

class DownloadRecord {
  const DownloadRecord({
    required this.itemId,
    required this.name,
    required this.type,
    required this.serverUrl,
    required this.localPath,
    required this.status,
    this.subtitle,
    this.progress = 0,
    this.totalBytes = 0,
    this.imageId,
  });

  final String itemId;
  final String name;
  final String type;
  final String? subtitle;
  final String serverUrl;
  final String localPath;
  final DownloadStatus status;
  final double progress;
  final int totalBytes;
  final String? imageId;

  DownloadRecord copyWith({
    DownloadStatus? status,
    double? progress,
    int? totalBytes,
    String? localPath,
  }) =>
      DownloadRecord(
        itemId: itemId,
        name: name,
        type: type,
        subtitle: subtitle,
        serverUrl: serverUrl,
        localPath: localPath ?? this.localPath,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        totalBytes: totalBytes ?? this.totalBytes,
        imageId: imageId,
      );

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'name': name,
        'type': type,
        'subtitle': subtitle,
        'serverUrl': serverUrl,
        'localPath': localPath,
        'status': status.name,
        'progress': progress,
        'totalBytes': totalBytes,
        'imageId': imageId,
      };

  factory DownloadRecord.fromJson(Map<String, dynamic> json) => DownloadRecord(
        itemId: json['itemId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        serverUrl: json['serverUrl'] as String? ?? '',
        localPath: json['localPath'] as String? ?? '',
        status: DownloadStatus.values
            .where((s) => s.name == json['status'])
            .firstOrNull ??
            DownloadStatus.queued,
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        totalBytes: json['totalBytes'] as int? ?? 0,
        imageId: json['imageId'] as String?,
      );
}

class DownloadsStore {
  const DownloadsStore(this._prefs);

  final SharedPreferences _prefs;
  static const _kDownloads = 'downloads.records';

  List<DownloadRecord> load() {
    final raw = _prefs.getString(_kDownloads);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(DownloadRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<DownloadRecord> records) =>
      _prefs.setString(
          _kDownloads, jsonEncode(records.map((r) => r.toJson()).toList()));
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
