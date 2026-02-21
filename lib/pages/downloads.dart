import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../core/services/download_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'adaptive_pages.dart';

/// Cross-platform Downloads page. Used as a full page (e.g. from desktop sidebar)
/// and as the Downloads tab content inside [Home].
class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  String _selectedFilter = 'all';
  String _sortBy = 'date';
  bool _gridView = true;

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar with filters
          _buildSidebar(downloadState),

          // Main content
          Expanded(
            child: Column(
              children: [
                _buildHeader(downloadState),
                Expanded(child: _buildContent(downloadState, serverUrl)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(DownloadState downloadState) {
    final allCount = downloadState.downloads.length;
    final completedCount = downloadState.completedDownloads.length;
    final activeCount = downloadState.activeDownloads.length;
    final pausedCount = downloadState.pausedDownloads.length;
    final failedCount = downloadState.failedDownloads.length;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        border: Border(
          right: BorderSide(color: AppColors.divider.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text('Downloads', style: AppTextStyles.headlineSmall),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'FILTER',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
          ),

          _buildFilterItem(
            'all',
            'All Downloads',
            Icons.folder_outlined,
            allCount,
          ),
          _buildFilterItem(
            'completed',
            'Ready to Watch',
            Icons.check_circle_outline,
            completedCount,
          ),
          _buildFilterItem(
            'active',
            'Downloading',
            Icons.downloading,
            activeCount,
          ),
          _buildFilterItem(
            'paused',
            'Paused',
            Icons.pause_circle_outline,
            pausedCount,
          ),
          _buildFilterItem(
            'failed',
            'Failed',
            Icons.error_outline,
            failedCount,
          ),

          const Spacer(),

          // Storage info
          _buildStorageInfo(downloadState),
        ],
      ),
    );
  }

  Widget _buildFilterItem(
    String filter,
    String label,
    IconData icon,
    int count,
  ) {
    final isSelected = _selectedFilter == filter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
            border: Border(
              left: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageInfo(DownloadState downloadState) {
    // Calculate total size of downloads
    int totalBytes = 0;
    for (final download in downloadState.completedDownloads) {
      totalBytes += download.totalBytes;
    }

    final sizeStr = _formatBytes(totalBytes);

    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      blur: AppTheme.blurLight,
      opacity: 0.05,
      borderRadius: AppTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Storage Used',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sizeStr,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (downloadState.completedDownloads.isNotEmpty)
            TextButton.icon(
              onPressed: _showClearAllDialog,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Clear All'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(DownloadState downloadState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Title based on filter
          Text(_getFilterTitle(), style: AppTextStyles.headlineMedium),
          const Spacer(),

          // Sort dropdown
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date', child: Text('Date Added')),
              const PopupMenuItem(value: 'name', child: Text('Name')),
              const PopupMenuItem(value: 'size', child: Text('Size')),
            ],
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              blur: AppTheme.blurLight,
              opacity: 0.05,
              borderRadius: AppTheme.radiusSm,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 18),
                  const SizedBox(width: 8),
                  Text(_getSortLabel()),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // View toggle
          GlassContainer(
            padding: const EdgeInsets.all(4),
            blur: AppTheme.blurLight,
            opacity: 0.05,
            borderRadius: AppTheme.radiusSm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggle(Icons.grid_view, true),
                _buildViewToggle(Icons.list, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, bool isGrid) {
    final isSelected = _gridView == isGrid;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: () => setState(() => _gridView = isGrid),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(DownloadState downloadState, String serverUrl) {
    final filteredDownloads = _getFilteredDownloads(downloadState);
    final sortedDownloads = _sortDownloads(filteredDownloads);

    if (sortedDownloads.isEmpty) {
      return _buildEmptyState();
    }

    if (_gridView) {
      return _buildGridView(sortedDownloads, serverUrl);
    } else {
      return _buildListView(sortedDownloads, serverUrl);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 80,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'all'
                ? 'No Downloads Yet'
                : 'No ${_getFilterTitle()}',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'all'
                ? 'Download movies and shows to watch offline'
                : 'Downloads matching this filter will appear here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          if (_selectedFilter == 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore),
              label: const Text('Browse Library'),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildGridView(List<DownloadTask> downloads, String serverUrl) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.55,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final download = downloads[index];
        return _DownloadGridCard(
          download: download,
          serverUrl: serverUrl,
          onTap: () => _onDownloadTap(download),
          onPlay: () => _playDownload(download),
          onDelete: () => _deleteDownload(download),
          onPause: () =>
              ref.read(downloadProvider.notifier).pauseDownload(download.id),
          onResume: () =>
              ref.read(downloadProvider.notifier).resumeDownload(download.id),
          onRetry: () => _retryDownload(download),
        );
      },
    );
  }

  Widget _buildListView(List<DownloadTask> downloads, String serverUrl) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final download = downloads[index];
        return _DownloadListItem(
          download: download,
          serverUrl: serverUrl,
          onTap: () => _onDownloadTap(download),
          onPlay: () => _playDownload(download),
          onDelete: () => _deleteDownload(download),
          onPause: () =>
              ref.read(downloadProvider.notifier).pauseDownload(download.id),
          onResume: () =>
              ref.read(downloadProvider.notifier).resumeDownload(download.id),
          onRetry: () => _retryDownload(download),
        );
      },
    );
  }

  List<DownloadTask> _getFilteredDownloads(DownloadState state) {
    switch (_selectedFilter) {
      case 'completed':
        return state.completedDownloads;
      case 'active':
        return state.activeDownloads;
      case 'paused':
        return state.pausedDownloads;
      case 'failed':
        return state.failedDownloads;
      default:
        return state.downloads;
    }
  }

  List<DownloadTask> _sortDownloads(List<DownloadTask> downloads) {
    final sorted = List<DownloadTask>.from(downloads);
    switch (_sortBy) {
      case 'name':
        sorted.sort((a, b) => a.itemName.compareTo(b.itemName));
        break;
      case 'size':
        sorted.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
        break;
      case 'date':
      default:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return sorted;
  }

  String _getFilterTitle() {
    switch (_selectedFilter) {
      case 'completed':
        return 'Ready to Watch';
      case 'active':
        return 'Downloading';
      case 'paused':
        return 'Paused Downloads';
      case 'failed':
        return 'Failed Downloads';
      default:
        return 'All Downloads';
    }
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'name':
        return 'Name';
      case 'size':
        return 'Size';
      default:
        return 'Date Added';
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

  void _onDownloadTap(DownloadTask download) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdaptiveDetailPage(itemId: download.itemId),
      ),
    );
  }

  void _playDownload(DownloadTask download) async {
    if (download.status != DownloadStatus.completed) return;
    if (download.localPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download file not found'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Create a minimal MediaItem for the player
    final item = MediaItem(
      id: download.itemId,
      name: download.itemName,
      type: _getMediaTypeFromString(download.itemType),
    );

    try {
      await ref
          .read(playerProvider.notifier)
          .playLocalFile(item, download.localPath!);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdaptivePlayerPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  MediaType _getMediaTypeFromString(String? typeString) {
    switch (typeString?.toLowerCase()) {
      case 'movie':
        return MediaType.movie;
      case 'episode':
        return MediaType.episode;
      case 'series':
        return MediaType.series;
      case 'audio':
        return MediaType.audio;
      case 'musicvideo':
        return MediaType.musicVideo;
      case 'album':
        return MediaType.album;
      default:
        return MediaType.movie;
    }
  }

  void _deleteDownload(DownloadTask download) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Download?'),
        content: Text(
          'Are you sure you want to delete "${download.itemName}"? This will remove the downloaded file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadProvider.notifier).deleteDownload(download.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _retryDownload(DownloadTask download) async {
    final mediaService = ref.read(mediaServiceProvider);
    try {
      final item = await mediaService.getItemDetails(download.itemId);
      await ref.read(downloadProvider.notifier).deleteDownload(download.id);
      await ref.read(downloadProvider.notifier).downloadItem(item);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to retry: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear All Downloads?'),
        content: const Text(
          'This will delete all downloaded files. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadProvider.notifier).deleteAllDownloads();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// Grid card for downloads
class _DownloadGridCard extends StatefulWidget {
  final DownloadTask download;
  final String serverUrl;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRetry;

  const _DownloadGridCard({
    required this.download,
    required this.serverUrl,
    required this.onTap,
    required this.onPlay,
    required this.onDelete,
    required this.onPause,
    required this.onResume,
    required this.onRetry,
  });

  @override
  State<_DownloadGridCard> createState() => _DownloadGridCardState();
}

class _DownloadGridCardState extends State<_DownloadGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final download = widget.download;
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
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster with overlay
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
                                  width: 60,
                                  height: 60,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: download.progress,
                                        strokeWidth: 4,
                                        backgroundColor: Colors.white24,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              AppColors.primary,
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
                                const Icon(
                                  Icons.pause_circle_filled,
                                  size: 48,
                                  color: AppColors.warning,
                                ),
                              const SizedBox(height: 8),
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
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 8),
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
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
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
                          child: const Icon(
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
                        Text(
                          download.itemType ?? 'Unknown',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiary,
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
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
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
              errorBuilder: (_, e, st) =>
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
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (_, e, st) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
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

// List item for downloads
class _DownloadListItem extends StatefulWidget {
  final DownloadTask download;
  final String serverUrl;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRetry;

  const _DownloadListItem({
    required this.download,
    required this.serverUrl,
    required this.onTap,
    required this.onPlay,
    required this.onDelete,
    required this.onPause,
    required this.onResume,
    required this.onRetry,
  });

  @override
  State<_DownloadListItem> createState() => _DownloadListItemState();
}

class _DownloadListItemState extends State<_DownloadListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final download = widget.download;
    final isCompleted = download.status == DownloadStatus.completed;
    final isActive = download.status == DownloadStatus.downloading;
    final isPaused = download.status == DownloadStatus.paused;
    final isFailed = download.status == DownloadStatus.failed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        blur: AppTheme.blurLight,
        opacity: _isHovered ? 0.1 : 0.05,
        borderRadius: AppTheme.radiusMd,
        child: InkWell(
          onTap: isCompleted ? widget.onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 120,
                      child: _buildListPosterImage(download, widget.serverUrl),
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
                          child: const Icon(
                            Icons.download_done,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

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
                        Text(
                          download.itemType ?? 'Unknown',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _formatBytes(download.totalBytes),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStatusWidget(download),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCompleted) ...[
                    ElevatedButton.icon(
                      onPressed: widget.onPlay,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Play'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (isActive)
                    IconButton(
                      onPressed: widget.onPause,
                      icon: const Icon(Icons.pause),
                      tooltip: 'Pause',
                    ),
                  if (isPaused)
                    IconButton(
                      onPressed: widget.onResume,
                      icon: const Icon(Icons.play_arrow),
                      tooltip: 'Resume',
                    ),
                  if (isFailed)
                    IconButton(
                      onPressed: widget.onRetry,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Retry',
                    ),
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    color: AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.02);
  }

  Widget _buildStatusWidget(DownloadTask download) {
    final status = download.status;

    switch (status) {
      case DownloadStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.downloading,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Downloading ${(download.progress * 100).toInt()}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: download.progress,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ],
        );
      case DownloadStatus.paused:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
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
              valueColor: const AlwaysStoppedAnimation(AppColors.warning),
            ),
          ],
        );
      case DownloadStatus.completed:
        return Row(
          children: [
            const Icon(
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
            const Icon(Icons.error_outline, size: 14, color: AppColors.error),
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
            const Icon(
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
            const Icon(
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

  Widget _buildListPosterImage(DownloadTask download, String serverUrl) {
    final localPrimaryPath = download.localPrimaryImagePath;
    if (localPrimaryPath != null && localPrimaryPath.isNotEmpty) {
      final localFile = File(localPrimaryPath);
      if (localFile.existsSync()) {
        return Image.file(
          localFile,
          fit: BoxFit.cover,
          errorBuilder: (context, e, st) =>
              _buildNetworkImage(download, serverUrl),
        );
      }
    }
    return _buildNetworkImage(download, serverUrl);
  }

  Widget _buildNetworkImage(DownloadTask download, String serverUrl) {
    final imageUrl =
        '$serverUrl/Items/${download.itemId}/Images/Primary?fillWidth=160&quality=90';
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.glassBorder,
        child: const Center(
          child: Icon(Icons.movie_outlined, color: AppColors.textSecondary),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.glassBorder,
        child: const Center(
          child: Icon(Icons.movie_outlined, color: AppColors.textSecondary),
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
