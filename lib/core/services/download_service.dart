import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../api/jellyfin_api.dart';
import '../api/models/media_item.dart';

part 'download_service.g.dart';

/// Download status enum
@HiveType(typeId: 20)
enum DownloadStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  downloading,
  @HiveField(2)
  paused,
  @HiveField(3)
  completed,
  @HiveField(4)
  failed,
  @HiveField(5)
  cancelled,
}

/// Download task model
@HiveType(typeId: 21)
class DownloadTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String itemId;

  @HiveField(2)
  final String itemName;

  @HiveField(3)
  final String? itemType;

  @HiveField(4)
  final String? primaryImageTag;

  @HiveField(5)
  String? localPath;

  @HiveField(6)
  DownloadStatus status;

  @HiveField(7)
  double progress;

  @HiveField(8)
  int totalBytes;

  @HiveField(9)
  int downloadedBytes;

  @HiveField(10)
  String? errorMessage;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime? completedAt;

  @HiveField(13)
  String? serverUrl;

  @HiveField(14)
  String? mediaSourceId;

  @HiveField(15)
  String? localPrimaryImagePath;

  @HiveField(16)
  String? localBackdropImagePath;

  @HiveField(17)
  String? backdropImageTag;

  DownloadTask({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.itemType,
    this.primaryImageTag,
    this.backdropImageTag,
    this.localPath,
    this.localPrimaryImagePath,
    this.localBackdropImagePath,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.errorMessage,
    DateTime? createdAt,
    this.completedAt,
    this.serverUrl,
    this.mediaSourceId,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create from media item
  factory DownloadTask.fromMediaItem(MediaItem item, String serverUrl) {
    return DownloadTask(
      id: '${item.id}_${DateTime.now().millisecondsSinceEpoch}',
      itemId: item.id,
      itemName: item.name,
      itemType: item.typeString,
      primaryImageTag: item.imageTags?.primary,
      backdropImageTag: item.backdropImageTags?.isNotEmpty == true 
          ? item.backdropImageTags!.first 
          : null,
      serverUrl: serverUrl,
    );
  }

  /// Get formatted progress
  String get formattedProgress {
    if (totalBytes == 0) return '0%';
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  /// Get formatted size
  String get formattedSize {
    if (totalBytes == 0) return 'Unknown';
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1024 * 1024 * 1024) return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get downloaded size
  String get formattedDownloadedSize {
    if (downloadedBytes < 1024) return '$downloadedBytes B';
    if (downloadedBytes < 1024 * 1024) return '${(downloadedBytes / 1024).toStringAsFixed(1)} KB';
    if (downloadedBytes < 1024 * 1024 * 1024) return '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(downloadedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Check if download is active
  bool get isActive => status == DownloadStatus.downloading || status == DownloadStatus.pending;

  /// Check if download can be resumed
  bool get canResume => status == DownloadStatus.paused || status == DownloadStatus.failed;

  /// Get image URL for thumbnail (from server)
  String getImageUrl(String serverUrl, {int? width}) {
    if (primaryImageTag == null) return '';
    final w = width ?? 200;
    return '$serverUrl/Items/$itemId/Images/Primary?maxWidth=$w&tag=$primaryImageTag';
  }

  /// Get local primary image path or fall back to server URL
  String? getLocalOrRemotePrimaryImage(String serverUrl, {int? width}) {
    if (localPrimaryImagePath != null) {
      return localPrimaryImagePath;
    }
    if (primaryImageTag == null) return null;
    final w = width ?? 200;
    return '$serverUrl/Items/$itemId/Images/Primary?maxWidth=$w&tag=$primaryImageTag';
  }

  /// Get local backdrop image path or fall back to server URL
  String? getLocalOrRemoteBackdropImage(String serverUrl, {int? width}) {
    if (localBackdropImagePath != null) {
      return localBackdropImagePath;
    }
    if (backdropImageTag == null) return null;
    final w = width ?? 1280;
    return '$serverUrl/Items/$itemId/Images/Backdrop?maxWidth=$w&tag=$backdropImageTag';
  }

  /// Check if this download has local images
  bool get hasLocalImages => localPrimaryImagePath != null || localBackdropImagePath != null;
}

/// Download service for managing media downloads
class DownloadService {
  final JellyfinApi _api;
  final Dio _dio;
  Box<DownloadTask>? _downloadsBox;
  
  final Map<String, CancelToken> _cancelTokens = {};
  final _progressController = StreamController<DownloadTask>.broadcast();
  
  Stream<DownloadTask> get progressStream => _progressController.stream;

  DownloadService(this._api) : _dio = Dio();

  /// Initialize the service
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(DownloadStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(DownloadTaskAdapter());
    }
    _downloadsBox = await Hive.openBox<DownloadTask>('downloads');
    
    // Resume any interrupted downloads
    await _resumeInterruptedDownloads();
  }

  /// Get downloads directory
  Future<Directory> get _downloadsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(path.join(appDir.path, 'Finar', 'Downloads'));
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  /// Get all downloads
  List<DownloadTask> get downloads {
    return _downloadsBox?.values.toList() ?? [];
  }

  /// Get downloads by status
  List<DownloadTask> getDownloadsByStatus(DownloadStatus status) {
    return downloads.where((d) => d.status == status).toList();
  }

  /// Get completed downloads
  List<DownloadTask> get completedDownloads {
    return getDownloadsByStatus(DownloadStatus.completed);
  }

  /// Get active downloads
  List<DownloadTask> get activeDownloads {
    return downloads.where((d) => d.isActive).toList();
  }

  /// Get download by item ID
  DownloadTask? getDownloadByItemId(String itemId) {
    try {
      return downloads.firstWhere((d) => d.itemId == itemId && d.status == DownloadStatus.completed);
    } catch (_) {
      return null;
    }
  }

  /// Check if item is downloaded
  bool isItemDownloaded(String itemId) {
    return getDownloadByItemId(itemId) != null;
  }

  /// Start downloading a media item
  Future<DownloadTask> downloadItem(MediaItem item) async {
    final serverUrl = _api.serverUrl ?? '';
    
    // Create download task
    final task = DownloadTask.fromMediaItem(item, serverUrl);
    
    // Save to box
    await _downloadsBox?.put(task.id, task);
    _notifyProgress(task);
    
    // Start download
    _startDownload(task);
    
    return task;
  }

  /// Start the actual download
  Future<void> _startDownload(DownloadTask task) async {
    try {
      // Get playback info to find the best media source
      final playbackInfo = await _api.getPlaybackInfo(task.itemId);
      final source = playbackInfo.directPlaySource;
      
      if (source == null) {
        task.status = DownloadStatus.failed;
        task.errorMessage = 'No playable media source found';
        await task.save();
        _notifyProgress(task);
        return;
      }

      task.mediaSourceId = source.id;
      task.status = DownloadStatus.downloading;
      await task.save();
      _notifyProgress(task);

      // Get download URL
      final downloadUrl = _api.getStreamUrl(
        task.itemId,
        mediaSourceId: source.id,
        container: source.container,
        static: true,
      );

      // Determine file path
      final downloadsDir = await _downloadsDir;
      final extension = source.container ?? 'mp4';
      final sanitizedName = task.itemName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final localPath = path.join(downloadsDir.path, '${task.itemId}_$sanitizedName.$extension');
      
      task.localPath = localPath;
      await task.save();

      // Create cancel token
      final cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;

      // Start download with progress tracking
      await _dio.download(
        downloadUrl,
        localPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            task.totalBytes = total;
            task.downloadedBytes = received;
            task.progress = received / total;
            _notifyProgress(task);
          }
        },
        options: Options(
          headers: {
            'X-Emby-Authorization': _api.authHeader,
          },
        ),
      );

      // Download completed
      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      task.completedAt = DateTime.now();
      await task.save();
      _notifyProgress(task);
      
      _cancelTokens.remove(task.id);
      
      if (kDebugMode) {
        print('Download completed: ${task.itemName}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        task.status = DownloadStatus.cancelled;
      } else {
        task.status = DownloadStatus.failed;
        task.errorMessage = e.message ?? 'Download failed';
      }
      await task.save();
      _notifyProgress(task);
      _cancelTokens.remove(task.id);
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
      await task.save();
      _notifyProgress(task);
      _cancelTokens.remove(task.id);
    }
  }

  /// Pause a download
  Future<void> pauseDownload(String taskId) async {
    final cancelToken = _cancelTokens[taskId];
    if (cancelToken != null) {
      cancelToken.cancel('Paused by user');
      _cancelTokens.remove(taskId);
    }
    
    final task = _downloadsBox?.get(taskId);
    if (task != null) {
      task.status = DownloadStatus.paused;
      await task.save();
      _notifyProgress(task);
    }
  }

  /// Resume a download
  Future<void> resumeDownload(String taskId) async {
    final task = _downloadsBox?.get(taskId);
    if (task != null && task.canResume) {
      task.status = DownloadStatus.pending;
      task.errorMessage = null;
      await task.save();
      _notifyProgress(task);
      _startDownload(task);
    }
  }

  /// Cancel a download
  Future<void> cancelDownload(String taskId) async {
    final cancelToken = _cancelTokens[taskId];
    if (cancelToken != null) {
      cancelToken.cancel('Cancelled by user');
      _cancelTokens.remove(taskId);
    }
    
    final task = _downloadsBox?.get(taskId);
    if (task != null) {
      // Delete partial file
      if (task.localPath != null) {
        final file = File(task.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      task.status = DownloadStatus.cancelled;
      await task.save();
      _notifyProgress(task);
    }
  }

  /// Delete a download
  Future<void> deleteDownload(String taskId) async {
    await cancelDownload(taskId);
    
    final task = _downloadsBox?.get(taskId);
    if (task != null) {
      // Delete file
      if (task.localPath != null) {
        final file = File(task.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      await _downloadsBox?.delete(taskId);
    }
  }

  /// Delete all downloads
  Future<void> deleteAllDownloads() async {
    // Cancel all active downloads
    for (final token in _cancelTokens.values) {
      token.cancel('Deleting all downloads');
    }
    _cancelTokens.clear();
    
    // Delete all files
    for (final task in downloads) {
      if (task.localPath != null) {
        final file = File(task.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    
    // Clear the box
    await _downloadsBox?.clear();
  }

  /// Get local file path for a downloaded item
  String? getLocalPath(String itemId) {
    final task = getDownloadByItemId(itemId);
    return task?.localPath;
  }

  /// Resume interrupted downloads
  Future<void> _resumeInterruptedDownloads() async {
    final interrupted = downloads.where((d) => 
      d.status == DownloadStatus.downloading || 
      d.status == DownloadStatus.pending
    ).toList();
    
    for (final task in interrupted) {
      task.status = DownloadStatus.paused;
      await task.save();
    }
  }

  void _notifyProgress(DownloadTask task) {
    _progressController.add(task);
  }

  /// Dispose
  void dispose() {
    _progressController.close();
    for (final token in _cancelTokens.values) {
      token.cancel('Service disposed');
    }
  }
}
