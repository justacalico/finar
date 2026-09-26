import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/api/models.dart';
import '../core/utils/file_ops_stub.dart'
    if (dart.library.io) '../core/utils/file_ops_io.dart';
import 'providers.dart';

const _manifestKey = 'downloads.v1';

enum DownloadStatus { queued, downloading, done, failed }

/// Status label shown in the downloads list.
extension DownloadStatusLabel on DownloadStatus {
  String get label => switch (this) {
        DownloadStatus.queued => 'Queued',
        DownloadStatus.downloading => 'Downloading',
        DownloadStatus.done => 'Done',
        DownloadStatus.failed => 'Failed',
      };
}

class DownloadEntry {
  final MediaItem item;
  final String? localPath;
  final DownloadStatus status;
  final double progress;
  final String? error;

  const DownloadEntry({
    required this.item,
    this.localPath,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.error,
  });

  DownloadEntry copyWith({
    String? localPath,
    DownloadStatus? status,
    double? progress,
    String? error,
  }) =>
      DownloadEntry(
        item: item,
        localPath: localPath ?? this.localPath,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        error: error,
      );

  Map<String, dynamic> toJson() => {
        'item': item.toJson(),
        'localPath': localPath,
        'status': status.name,
        'progress': progress,
      };

  factory DownloadEntry.fromJson(Map<String, dynamic> j) => DownloadEntry(
        item: MediaItem.fromJson(j['item'] as Map<String, dynamic>),
        localPath: j['localPath'] as String?,
        status: DownloadStatus.values.firstWhere((s) => s.name == j['status'],
            orElse: () => DownloadStatus.failed),
        progress: (j['progress'] as num?)?.toDouble() ?? 0,
      );
}

class DownloadsNotifier extends Notifier<List<DownloadEntry>> {
  final _tokens = <String, CancelToken>{};
  final _dio = Dio();
  Future<String>? _dirFuture;

  @override
  List<DownloadEntry> build() => _load();

  List<DownloadEntry> _load() {
    final raw = ref.read(appStorageProvider).getRaw(_manifestKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final entries = (jsonDecode(raw) as List<dynamic>)
          .map((e) => DownloadEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      // In-flight entries do not survive a restart.
      return [
        for (final e in entries)
          e.status == DownloadStatus.done
              ? e
              : e.copyWith(status: DownloadStatus.failed)
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist() => ref.read(appStorageProvider).setRaw(
      _manifestKey, jsonEncode(state.map((e) => e.toJson()).toList()));

  bool isDownloaded(String itemId) => state.any(
      (e) => e.item.id == itemId && e.status == DownloadStatus.done);

  bool isActive(String itemId) => state.any((e) =>
      e.item.id == itemId &&
      (e.status == DownloadStatus.downloading ||
          e.status == DownloadStatus.queued));

  String? localPathFor(String itemId) {
    for (final e in state) {
      if (e.item.id == itemId && e.status == DownloadStatus.done) {
        return e.localPath;
      }
    }
    return null;
  }

  DownloadEntry? entryFor(String itemId) {
    for (final e in state) {
      if (e.item.id == itemId) return e;
    }
    return null;
  }

  void _update(String itemId, DownloadEntry Function(DownloadEntry) fn) {
    state = [
      for (final e in state) e.item.id == itemId ? fn(e) : e,
    ];
  }

  Future<void> download(MediaItem item) async {
    if (kIsWeb || isDownloaded(item.id) || isActive(item.id)) return;
    final client = ref.read(jellyfinClientProvider);
    _dirFuture ??= downloadsDirectory();
    final dir = await _dirFuture!;
    await ensureDirectory(dir);
    final ext = item.mediaSources.isNotEmpty &&
            item.mediaSources.first.container != null
        ? item.mediaSources.first.container!
        : 'mkv';
    final path = p.join(dir, '${item.id}.$ext');

    state = [
      ...state,
      DownloadEntry(
          item: item,
          localPath: path,
          status: DownloadStatus.downloading),
    ];

    final token = CancelToken();
    _tokens[item.id] = token;

    try {
      await _dio.download(
        client.streamUrl(item.id),
        path,
        cancelToken: token,
        options:
            Options(headers: {'X-Emby-Authorization': client.authHeader}),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _update(
                item.id, (e) => e.copyWith(progress: received / total));
          }
        },
      );
      _update(item.id,
          (e) => e.copyWith(status: DownloadStatus.done, progress: 1));
      await _persist();
    } catch (err) {
      await deleteFileIfExists(path);
      _update(
          item.id,
          (e) => e.copyWith(
              status: DownloadStatus.failed, error: err.toString()));
      await _persist();
    } finally {
      _tokens.remove(item.id);
    }
  }

  Future<void> cancel(String itemId) async {
    _tokens[itemId]?.cancel();
    _tokens.remove(itemId);
    final entry = entryFor(itemId);
    if (entry?.localPath != null) {
      await deleteFileIfExists(entry!.localPath!);
    }
    state = [for (final e in state) if (e.item.id != itemId) e];
    await _persist();
  }

  Future<void> remove(String itemId) => cancel(itemId);
}

final downloadsProvider =
    NotifierProvider<DownloadsNotifier, List<DownloadEntry>>(
        DownloadsNotifier.new);
