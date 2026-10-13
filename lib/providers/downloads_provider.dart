import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/models/models.dart';
import '../core/storage/downloads_store.dart';
import 'core_providers.dart';
import 'session_provider.dart';

final downloadsProvider =
    NotifierProvider<DownloadsNotifier, List<DownloadRecord>>(
        DownloadsNotifier.new);

class DownloadsNotifier extends Notifier<List<DownloadRecord>> {
  final _tokens = <String, CancelToken>{};

  @override
  List<DownloadRecord> build() =>
      ref.watch(downloadsStoreProvider).load();

  Future<void> _persist() =>
      ref.read(downloadsStoreProvider).save(state);

  bool isDownloaded(String itemId) =>
      state.any((r) => r.itemId == itemId && r.status == DownloadStatus.completed);

  Future<void> start(BaseItem item) async {
    final session = ref.read(sessionProvider);
    final client = ref.read(jellyfinClientProvider);
    if (session == null || client == null) return;
    if (state.any((r) =>
        r.itemId == item.id &&
        (r.status == DownloadStatus.downloading ||
            r.status == DownloadStatus.queued ||
            r.status == DownloadStatus.completed))) {
      return;
    }
    final dir = await _downloadsDir();
    final record = DownloadRecord(
      itemId: item.id,
      name: item.name,
      type: item.type,
      subtitle: item.seriesName ?? item.albumArtist,
      serverUrl: session.serverUrl,
      localPath: p.join(dir.path, '${item.id}.bin'),
      status: DownloadStatus.queued,
      imageId: item.id,
    );
    state = [...state, record];
    await _persist();
    await _run(record, item);
  }

  Future<Directory> _downloadsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'finar_downloads'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<void> _run(DownloadRecord record, BaseItem item) async {
    final client = ref.read(jellyfinClientProvider);
    if (client == null) return;
    final token = CancelToken();
    _tokens[record.itemId] = token;
    _replace(record.copyWith(status: DownloadStatus.downloading));
    try {
      final uri = client.streamUrl(item.id, isAudio: item.isAudio);
      await client.dio.downloadUri(
        uri,
        record.localPath,
        cancelToken: token,
        onReceiveProgress: (received, total) {
          final index =
              state.indexWhere((r) => r.itemId == record.itemId);
          if (index == -1) return;
          final next = List<DownloadRecord>.from(state);
          next[index] = next[index].copyWith(
            progress: total > 0 ? received / total : 0,
            totalBytes: total > 0 ? total : received,
          );
          state = next;
        },
      );
      _replace(record.copyWith(
          status: DownloadStatus.completed,
          progress: 1,
          localPath: record.localPath));
    } catch (_) {
      if (token.isCancelled) return;
      _replace(record.copyWith(status: DownloadStatus.failed));
    }
    _tokens.remove(record.itemId);
    await _persist();
  }

  void _replace(DownloadRecord next) {
    state = [
      for (final r in state) r.itemId == next.itemId ? next : r,
    ];
  }

  Future<void> cancel(String itemId) async {
    _tokens[itemId]?.cancel();
    _tokens.remove(itemId);
    await remove(itemId);
  }

  Future<void> remove(String itemId) async {
    final record =
        state.where((r) => r.itemId == itemId).firstOrNull;
    if (record != null) {
      final file = File(record.localPath);
      if (file.existsSync()) file.deleteSync();
    }
    state = state.where((r) => r.itemId != itemId).toList();
    await _persist();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
