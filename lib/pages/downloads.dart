import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../core/services/download_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'adaptive_pages.dart';
import 'downloads_widgets.dart';

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
    final accent = Theme.of(context).colorScheme.primary;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context, downloadState, accent),
            ),
            SliverToBoxAdapter(child: _buildFilterChips(downloadState, accent)),
            SliverToBoxAdapter(child: _buildToolbar(context, accent, isNarrow)),
            _buildContent(downloadState, serverUrl, accent, isNarrow),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DownloadState downloadState,
    Color accent,
  ) {
    final totalBytes = downloadState.completedDownloads.fold<int>(
      0,
      (sum, d) => sum + d.totalBytes,
    );

    return PageHeader(
      title: 'Downloads',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storage_outlined, size: 16, color: accent),
                const SizedBox(width: 6),
                Text(
                  _formatBytes(totalBytes),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (downloadState.completedDownloads.isNotEmpty)
            TextButton.icon(
              onPressed: _showClearAllDialog,
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.error,
              ),
              label: Text(
                'Clear All',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(DownloadState downloadState, Color accent) {
    final filters = [
      ('all', 'All', downloadState.downloads.length),
      ('completed', 'Ready', downloadState.completedDownloads.length),
      ('active', 'Downloading', downloadState.activeDownloads.length),
      ('paused', 'Paused', downloadState.pausedDownloads.length),
      ('failed', 'Failed', downloadState.failedDownloads.length),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final (filter, label, count) = filters[index];
            final isSelected = _selectedFilter == filter;
            return FilterChip(
              label: Text('$label${count > 0 ? ' ($count)' : ''}'),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              selectedColor: accent.withValues(alpha: 0.2),
              checkmarkColor: accent,
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? accent : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: AppColors.surface.withValues(alpha: 0.5),
              side: BorderSide(
                color: isSelected
                    ? accent.withValues(alpha: 0.4)
                    : AppColors.divider.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, Color accent, bool isNarrow) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            _getFilterTitle(),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
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
                  Icon(Icons.sort, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Text(_getSortLabel()),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GlassContainer(
            padding: const EdgeInsets.all(4),
            blur: AppTheme.blurLight,
            opacity: 0.05,
            borderRadius: AppTheme.radiusSm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggle(Icons.grid_view, true, accent),
                _buildViewToggle(Icons.list, false, accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, bool isGrid, Color accent) {
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
            color: isSelected ? accent.withValues(alpha: 0.2) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    DownloadState downloadState,
    String serverUrl,
    Color accent,
    bool isNarrow,
  ) {
    final filtered = _getFilteredDownloads(downloadState);
    final sorted = _sortDownloads(filtered);

    if (sorted.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    if (_gridView) {
      return _buildGrid(sorted, serverUrl, accent, isNarrow);
    }
    return _buildList(sorted, serverUrl, accent);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 72,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
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
        ],
      ),
    );
  }

  Widget _buildGrid(
    List<DownloadTask> downloads,
    String serverUrl,
    Color accent,
    bool isNarrow,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxExtent = isNarrow ? 160.0 : (screenWidth < 900 ? 180.0 : 200.0);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtent,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final download = downloads[index];
          return DownloadGridCard(
            download: download,
            serverUrl: serverUrl,
            accent: accent,
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
        childCount: downloads.length,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
      ),
    );
  }

  Widget _buildList(
    List<DownloadTask> downloads,
    String serverUrl,
    Color accent,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final download = downloads[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: DownloadListItem(
              download: download,
              serverUrl: serverUrl,
              accent: accent,
              onTap: () => _onDownloadTap(download),
              onPlay: () => _playDownload(download),
              onDelete: () => _deleteDownload(download),
              onPause: () => ref
                  .read(downloadProvider.notifier)
                  .pauseDownload(download.id),
              onResume: () => ref
                  .read(downloadProvider.notifier)
                  .resumeDownload(download.id),
              onRetry: () => _retryDownload(download),
            ),
          );
        },
        childCount: downloads.length,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
      ),
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
      case 'size':
        sorted.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
      default:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
        return 'Paused';
      case 'failed':
        return 'Failed';
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
          SnackBar(
            content: Text('Download file not found'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

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
        title: Text('Delete Download?'),
        content: Text(
          'Are you sure you want to delete "${download.itemName}"? This will remove the downloaded file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadProvider.notifier).deleteDownload(download.id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
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
        title: Text('Clear All Downloads?'),
        content: Text(
          'This will delete all downloaded files. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadProvider.notifier).deleteAllDownloads();
              Navigator.pop(context);
            },
            child: Text('Clear All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
