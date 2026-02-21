import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/download_service.dart';
import '../core/api/models/media_item.dart';
import 'auth_provider.dart';

/// Download service provider
final downloadServiceProvider = Provider<DownloadService>((ref) {
  final api = ref.watch(jellyfinApiProvider);
  return DownloadService(api);
});

/// Download state
class DownloadState {
  final List<DownloadTask> downloads;
  final bool isInitialized;
  final String? error;

  const DownloadState({
    this.downloads = const [],
    this.isInitialized = false,
    this.error,
  });

  DownloadState copyWith({
    List<DownloadTask>? downloads,
    bool? isInitialized,
    String? error,
  }) {
    return DownloadState(
      downloads: downloads ?? this.downloads,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }

  /// Get downloads by status
  List<DownloadTask> get completedDownloads =>
      downloads.where((d) => d.status == DownloadStatus.completed).toList();

  List<DownloadTask> get activeDownloads =>
      downloads.where((d) => d.isActive).toList();

  List<DownloadTask> get failedDownloads =>
      downloads.where((d) => d.status == DownloadStatus.failed).toList();

  List<DownloadTask> get pausedDownloads =>
      downloads.where((d) => d.status == DownloadStatus.paused).toList();

  /// Check if item is downloaded
  bool isItemDownloaded(String itemId) {
    return downloads.any((d) => d.itemId == itemId && d.status == DownloadStatus.completed);
  }

  /// Get download task for item
  DownloadTask? getTaskForItem(String itemId) {
    try {
      return downloads.firstWhere((d) => d.itemId == itemId);
    } catch (_) {
      return null;
    }
  }
}

/// Download notifier
class DownloadNotifier extends StateNotifier<DownloadState> {
  final DownloadService _service;
  StreamSubscription<DownloadTask>? _progressSubscription;

  DownloadNotifier(this._service) : super(const DownloadState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _service.init();
      
      // Listen to progress updates
      _progressSubscription = _service.progressStream.listen(_onProgressUpdate);
      
      // Load initial downloads
      state = state.copyWith(
        downloads: _service.downloads,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isInitialized: true,
      );
    }
  }

  void _onProgressUpdate(DownloadTask task) {
    final downloads = List<DownloadTask>.from(state.downloads);
    final index = downloads.indexWhere((d) => d.id == task.id);
    
    if (index >= 0) {
      downloads[index] = task;
    } else {
      downloads.insert(0, task);
    }
    
    state = state.copyWith(downloads: downloads);
  }

  /// Start downloading an item
  Future<void> downloadItem(MediaItem item) async {
    try {
      await _service.downloadItem(item);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Pause a download
  Future<void> pauseDownload(String taskId) async {
    await _service.pauseDownload(taskId);
  }

  /// Resume a download
  Future<void> resumeDownload(String taskId) async {
    await _service.resumeDownload(taskId);
  }

  /// Cancel a download
  Future<void> cancelDownload(String taskId) async {
    await _service.cancelDownload(taskId);
    _refreshDownloads();
  }

  /// Delete a download
  Future<void> deleteDownload(String taskId) async {
    await _service.deleteDownload(taskId);
    _refreshDownloads();
  }

  /// Delete all downloads
  Future<void> deleteAllDownloads() async {
    await _service.deleteAllDownloads();
    _refreshDownloads();
  }

  /// Get local path for item
  String? getLocalPath(String itemId) {
    return _service.getLocalPath(itemId);
  }

  void _refreshDownloads() {
    state = state.copyWith(downloads: _service.downloads);
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}

/// Download provider
final downloadProvider = StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  final service = ref.watch(downloadServiceProvider);
  return DownloadNotifier(service);
});

/// Provider for checking if an item is downloaded
final isItemDownloadedProvider = Provider.family<bool, String>((ref, itemId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.isItemDownloaded(itemId);
});

/// Provider for getting download task for an item
final downloadTaskProvider = Provider.family<DownloadTask?, String>((ref, itemId) {
  final downloadState = ref.watch(downloadProvider);
  return downloadState.getTaskForItem(itemId);
});
