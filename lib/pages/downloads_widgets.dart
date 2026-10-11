import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/download_service.dart';
import '../../widgets/widgets.dart';

class DownloadGridCard extends StatefulWidget {
  final DownloadTask download;
  final String serverUrl;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRetry;

  const DownloadGridCard({
    super.key,
    required this.download,
    required this.serverUrl,
    required this.accent,
    required this.onTap,
    required this.onPlay,
    required this.onDelete,
    required this.onPause,
    required this.onResume,
    required this.onRetry,
  });

  @override
  State<DownloadGridCard> createState() => _DownloadGridCardState();
}

class _DownloadGridCardState extends State<DownloadGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final download = widget.download;
    final accent = widget.accent;
    final isCompleted = download.status == DownloadStatus.completed;
    final isActive = download.status == DownloadStatus.downloading;
    final isPaused = download.status == DownloadStatus.paused;
    final isFailed = download.status == DownloadStatus.failed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isCompleted ? widget.onTap : null,
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: _isHovered
                  ? accent.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: _buildPosterImage(download, widget.serverUrl),
                    ),
                    if (isActive || isPaused)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            color: Colors.black54,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isActive)
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: download.progress,
                                        strokeWidth: 4,
                                        backgroundColor: Colors.white24,
                                        valueColor: AlwaysStoppedAnimation(
                                          accent,
                                        ),
                                      ),
                                      Text(
                                        '${(download.progress * 100).toInt()}%',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Icon(
                                  Icons.pause_circle_filled,
                                  size: 44,
                                  color: AppColors.warning,
                                ),
                              const SizedBox(height: 6),
                              Text(
                                isActive ? 'Downloading...' : 'Paused',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (isFailed)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            color: Colors.black54,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 44,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Failed',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_isHovered && isCompleted)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: widget.onPlay,
                                icon: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Icon(
                                    Icons.play_arrow,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Play',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (isCompleted)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.download_done,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (_isHovered)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (isActive)
                              _buildActionButton(
                                Icons.pause,
                                'Pause',
                                widget.onPause,
                              ),
                            if (isPaused)
                              _buildActionButton(
                                Icons.play_arrow,
                                'Resume',
                                widget.onResume,
                              ),
                            if (isFailed)
                              _buildActionButton(
                                Icons.refresh,
                                'Retry',
                                widget.onRetry,
                              ),
                            _buildActionButton(
                              Icons.delete_outline,
                              'Delete',
                              widget.onDelete,
                              isDestructive: true,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      download.itemName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getTypeIcon(download.itemType),
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            download.itemType ?? 'Unknown',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (download.totalBytes > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatBytes(download.totalBytes),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPosterImage(DownloadTask download, String serverUrl) {
    if (download.localPrimaryImagePath != null) {
      final file = File(download.localPrimaryImagePath!);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  _buildNetworkPoster(download, serverUrl),
            );
          }
          return _buildNetworkPoster(download, serverUrl);
        },
      );
    }
    return _buildNetworkPoster(download, serverUrl);
  }

  Widget _buildNetworkPoster(DownloadTask download, String serverUrl) {
    if (download.primaryImageTag != null) {
      return CachedNetworkImage(
        imageUrl:
            '$serverUrl/Items/${download.itemId}/Images/Primary?tag=${download.primaryImageTag}',
        memCacheWidth: 400,
        memCacheHeight: 600,
        fadeInDuration: const Duration(milliseconds: 150),
        fit: BoxFit.cover,
        placeholder: (_, _) => _buildPlaceholder(),
        errorWidget: (_, _, _) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceElevated,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 40,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppColors.error.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'movie':
        return Icons.movie_outlined;
      case 'episode':
        return Icons.tv_outlined;
      case 'series':
        return Icons.video_library_outlined;
      case 'audio':
      case 'musicalbum':
        return Icons.music_note_outlined;
      default:
        return Icons.video_file_outlined;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class DownloadListItem extends StatelessWidget {
  final DownloadTask download;
  final String serverUrl;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRetry;

  const DownloadListItem({
    super.key,
    required this.download,
    required this.serverUrl,
    required this.accent,
    required this.onTap,
    required this.onPlay,
    required this.onDelete,
    required this.onPause,
    required this.onResume,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = download.status == DownloadStatus.completed;
    final isActive = download.status == DownloadStatus.downloading;
    final isPaused = download.status == DownloadStatus.paused;
    final isFailed = download.status == DownloadStatus.failed;

    return GlassContainer(
      padding: const EdgeInsets.all(12),
      blur: AppTheme.blurLight,
      opacity: 0.05,
      borderRadius: AppTheme.radiusMd,
      child: InkWell(
        onTap: isCompleted ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Stack(
                children: [
                  SizedBox(
                    width: 70,
                    height: 100,
                    child: _buildPosterImage(download, serverUrl),
                  ),
                  if (isCompleted)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.download_done,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    download.itemName,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getTypeIcon(download.itemType),
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          download.itemType ?? 'Unknown',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (download.totalBytes > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatBytes(download.totalBytes),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatusWidget(download, accent),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCompleted)
                  ElevatedButton.icon(
                    onPressed: onPlay,
                    icon: Icon(Icons.play_arrow, size: 18),
                    label: Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                if (isActive)
                  IconButton(
                    onPressed: onPause,
                    icon: Icon(Icons.pause),
                    tooltip: 'Pause',
                  ),
                if (isPaused)
                  IconButton(
                    onPressed: onResume,
                    icon: Icon(Icons.play_arrow),
                    tooltip: 'Resume',
                    color: accent,
                  ),
                if (isFailed)
                  IconButton(
                    onPressed: onRetry,
                    icon: Icon(Icons.refresh),
                    tooltip: 'Retry',
                    color: accent,
                  ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusWidget(DownloadTask download, Color accent) {
    switch (download.status) {
      case DownloadStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.downloading, size: 14, color: accent),
                const SizedBox(width: 4),
                Text(
                  'Downloading ${(download.progress * 100).toInt()}%',
                  style: AppTextStyles.bodySmall.copyWith(color: accent),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: download.progress,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ],
        );
      case DownloadStatus.paused:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pause_circle_outline,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  'Paused - ${(download.progress * 100).toInt()}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: download.progress,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(AppColors.warning),
            ),
          ],
        );
      case DownloadStatus.completed:
        return Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: AppColors.success,
            ),
            const SizedBox(width: 4),
            Text(
              'Ready to watch',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
            ),
          ],
        );
      case DownloadStatus.failed:
        return Row(
          children: [
            Icon(Icons.error_outline, size: 14, color: AppColors.error),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                download.errorMessage ?? 'Download failed',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case DownloadStatus.pending:
        return Row(
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Pending...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      case DownloadStatus.cancelled:
        return Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Cancelled',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPosterImage(DownloadTask download, String serverUrl) {
    final localPrimaryPath = download.localPrimaryImagePath;
    if (localPrimaryPath != null && localPrimaryPath.isNotEmpty) {
      final localFile = File(localPrimaryPath);
      if (localFile.existsSync()) {
        return Image.file(
          localFile,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildNetworkImage(download, serverUrl),
        );
      }
    }
    return _buildNetworkImage(download, serverUrl);
  }

  Widget _buildNetworkImage(DownloadTask download, String serverUrl) {
    if (download.primaryImageTag != null) {
      return CachedNetworkImage(
        imageUrl:
            '$serverUrl/Items/${download.itemId}/Images/Primary?fillWidth=160&quality=90',
        memCacheWidth: 160,
        memCacheHeight: 240,
        fadeInDuration: const Duration(milliseconds: 150),
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          color: AppColors.glassBorder,
          child: Center(
            child: Icon(Icons.movie_outlined, color: AppColors.textSecondary),
          ),
        ),
        errorWidget: (_, _, _) => Container(
          color: AppColors.glassBorder,
          child: Center(
            child: Icon(Icons.movie_outlined, color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Container(
      color: AppColors.glassBorder,
      child: Center(
        child: Icon(Icons.movie_outlined, color: AppColors.textSecondary),
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'movie':
        return Icons.movie_outlined;
      case 'episode':
        return Icons.tv_outlined;
      case 'series':
        return Icons.video_library_outlined;
      case 'audio':
      case 'musicalbum':
        return Icons.music_note_outlined;
      default:
        return Icons.video_file_outlined;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
