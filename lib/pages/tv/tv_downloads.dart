import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/download_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'tv_detail.dart';
import 'tv_player.dart';

class TvDownloads extends ConsumerStatefulWidget {
  const TvDownloads({super.key});

  @override
  ConsumerState<TvDownloads> createState() => _TvDownloadsState();
}

class _TvDownloadsState extends ConsumerState<TvDownloads> {
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  int _selectedFilterIndex = 0;
  bool _inFilterSelection = false;

  final List<String> _filters = ['All', 'Ready', 'Downloading', 'Paused', 'Failed'];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';
    final filteredDownloads = _getFilteredDownloads(downloadState);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) => _handleKeyEvent(event, filteredDownloads),
        child: Row(
          children: [
            // Sidebar with filters
            _buildSidebar(downloadState),
            
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: filteredDownloads.isEmpty
                        ? _buildEmptyState()
                        : _buildDownloadGrid(filteredDownloads, serverUrl),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(DownloadState downloadState) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        border: Border(
          right: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 28),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Downloads',
            style: AppTextStyles.displaySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${downloadState.completedDownloads.length} items ready',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Filters
          Text(
            'FILTER',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._filters.asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final count = _getFilterCount(downloadState, index);
            return _buildFilterItem(index, label, count);
          }),
          
          const Spacer(),
          
          // Storage info
          if (downloadState.downloads.isNotEmpty)
            _buildStorageInfo(downloadState),
        ],
      ),
    );
  }

  Widget _buildFilterItem(int index, String label, int count) {
    final isSelected = _selectedFilterIndex == index;
    final isFocused = _inFilterSelection && isSelected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isFocused ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getFilterIcon(index),
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfo(DownloadState downloadState) {
    int totalBytes = 0;
    for (final download in downloadState.completedDownloads) {
      totalBytes += download.totalBytes;
    }
    
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      blur: AppTheme.blurLight,
      opacity: 0.05,
      borderRadius: AppTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_outlined, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Storage Used',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatBytes(totalBytes),
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Text(
            _getFilterTitle(),
            style: AppTextStyles.headlineLarge,
          ),
          const Spacer(),
          Text(
            'Press ENTER to play • Long press DELETE to remove',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 100,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 32),
          Text(
            _selectedFilterIndex == 0 ? 'No Downloads Yet' : 'No ${_filters[_selectedFilterIndex]} Downloads',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedFilterIndex == 0 
                ? 'Download movies and shows to watch offline'
                : 'Downloads matching this filter will appear here',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildDownloadGrid(List<DownloadTask> downloads, String serverUrl) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        childAspectRatio: 0.6,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final download = downloads[index];
        final isSelected = !_inFilterSelection && _selectedIndex == index;
        
        return _TvDownloadCard(
          download: download,
          serverUrl: serverUrl,
          isSelected: isSelected,
          onSelect: () => _onDownloadSelected(download),
          onPlay: () => _playDownload(download),
          onDelete: () => _deleteDownload(download),
        );
      },
    );
  }

  List<DownloadTask> _getFilteredDownloads(DownloadState state) {
    switch (_selectedFilterIndex) {
      case 1: // Ready
        return state.completedDownloads;
      case 2: // Downloading
        return state.activeDownloads;
      case 3: // Paused
        return state.pausedDownloads;
      case 4: // Failed
        return state.failedDownloads;
      default: // All
        return state.downloads;
    }
  }

  int _getFilterCount(DownloadState state, int filterIndex) {
    switch (filterIndex) {
      case 1:
        return state.completedDownloads.length;
      case 2:
        return state.activeDownloads.length;
      case 3:
        return state.pausedDownloads.length;
      case 4:
        return state.failedDownloads.length;
      default:
        return state.downloads.length;
    }
  }

  IconData _getFilterIcon(int index) {
    switch (index) {
      case 1:
        return Icons.check_circle_outline;
      case 2:
        return Icons.downloading;
      case 3:
        return Icons.pause_circle_outline;
      case 4:
        return Icons.error_outline;
      default:
        return Icons.folder_outlined;
    }
  }

  String _getFilterTitle() {
    switch (_selectedFilterIndex) {
      case 1:
        return 'Ready to Watch';
      case 2:
        return 'Downloading';
      case 3:
        return 'Paused';
      case 4:
        return 'Failed';
      default:
        return 'All Downloads';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _handleKeyEvent(KeyEvent event, List<DownloadTask> downloads) {
    if (event is! KeyDownEvent) return;

    final crossAxisCount = (MediaQuery.of(context).size.width - 280 - 64) ~/ 250;

    setState(() {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          if (_inFilterSelection) {
            if (_selectedFilterIndex > 0) {
              _selectedFilterIndex--;
            }
          } else {
            if (_selectedIndex >= crossAxisCount) {
              _selectedIndex -= crossAxisCount;
            } else {
              _inFilterSelection = true;
            }
          }
          break;

        case LogicalKeyboardKey.arrowDown:
          if (_inFilterSelection) {
            if (_selectedFilterIndex < _filters.length - 1) {
              _selectedFilterIndex++;
            } else {
              _inFilterSelection = false;
              _selectedIndex = 0;
            }
          } else {
            if (_selectedIndex + crossAxisCount < downloads.length) {
              _selectedIndex += crossAxisCount;
            }
          }
          break;

        case LogicalKeyboardKey.arrowLeft:
          if (!_inFilterSelection) {
            if (_selectedIndex % crossAxisCount > 0) {
              _selectedIndex--;
            } else {
              _inFilterSelection = true;
            }
          }
          break;

        case LogicalKeyboardKey.arrowRight:
          if (_inFilterSelection) {
            _inFilterSelection = false;
            _selectedIndex = 0;
          } else {
            if (_selectedIndex % crossAxisCount < crossAxisCount - 1 &&
                _selectedIndex < downloads.length - 1) {
              _selectedIndex++;
            }
          }
          break;

        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
          if (!_inFilterSelection && downloads.isNotEmpty) {
            final download = downloads[_selectedIndex];
            if (download.status == DownloadStatus.completed) {
              _playDownload(download);
            } else {
              _onDownloadSelected(download);
            }
          }
          break;

        case LogicalKeyboardKey.backspace:
        case LogicalKeyboardKey.escape:
          Navigator.pop(context);
          break;

        case LogicalKeyboardKey.delete:
          if (!_inFilterSelection && downloads.isNotEmpty) {
            _deleteDownload(downloads[_selectedIndex]);
          }
          break;
      }
    });
  }

  void _onDownloadSelected(DownloadTask download) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TvDetail(itemId: download.itemId),
      ),
    );
  }

  void _playDownload(DownloadTask download) async {
    if (download.status != DownloadStatus.completed) return;
    
    final mediaService = ref.read(mediaServiceProvider);
    try {
      final item = await mediaService.getItemDetails(download.itemId);
      if (mounted) {
        ref.read(playerProvider.notifier).play(item);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TvPlayer(),
          ),
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

  void _deleteDownload(DownloadTask download) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Download?'),
        content: Text('Are you sure you want to delete "${download.itemName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadProvider.notifier).deleteDownload(download.id);
              Navigator.pop(context);
              // Reset selection if needed
              final downloads = _getFilteredDownloads(ref.read(downloadProvider));
              if (_selectedIndex >= downloads.length && downloads.isNotEmpty) {
                setState(() => _selectedIndex = downloads.length - 1);
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _TvDownloadCard extends StatelessWidget {
  final DownloadTask download;
  final String serverUrl;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _TvDownloadCard({
    required this.download,
    required this.serverUrl,
    required this.isSelected,
    required this.onSelect,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = download.status == DownloadStatus.completed;
    final isActive = download.status == DownloadStatus.downloading;
    final isPaused = download.status == DownloadStatus.paused;
    final isFailed = download.status == DownloadStatus.failed;

    return AnimatedContainer(
      duration: AppTheme.durationFast,
      transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 3,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  download.primaryImageTag != null
                      ? CachedNetworkImage(
                          imageUrl: '$serverUrl/Items/${download.itemId}/Images/Primary?tag=${download.primaryImageTag}',
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: AppColors.surfaceElevated,
                            child: const Center(
                              child: Icon(Icons.movie_outlined, size: 48, color: AppColors.textTertiary),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.surfaceElevated,
                            child: const Center(
                              child: Icon(Icons.movie_outlined, size: 48, color: AppColors.textTertiary),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceElevated,
                          child: const Center(
                            child: Icon(Icons.movie_outlined, size: 48, color: AppColors.textTertiary),
                          ),
                        ),

                  // Status overlay
                  if (!isCompleted)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isActive)
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: download.progress,
                                      strokeWidth: 4,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                    ),
                                    Text(
                                      '${(download.progress * 100).toInt()}%',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isPaused)
                              const Icon(Icons.pause_circle_filled, size: 56, color: AppColors.warning)
                            else if (isFailed)
                              const Icon(Icons.error_outline, size: 56, color: AppColors.error)
                            else
                              const Icon(Icons.hourglass_empty, size: 56, color: AppColors.textSecondary),
                            const SizedBox(height: 8),
                            Text(
                              _getStatusText(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Play button overlay for completed downloads when selected
                  if (isCompleted && isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Downloaded badge
                  if (isCompleted)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.download_done, size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.1) 
                  : AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    download.itemName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getTypeIcon(),
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
                      if (download.totalBytes > 0) ...[
                        const Spacer(),
                        Text(
                          _formatBytes(download.totalBytes),
                          style: AppTextStyles.bodySmall.copyWith(
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
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.95, 0.95),
          duration: 300.ms,
        );
  }

  String _getStatusText() {
    switch (download.status) {
      case DownloadStatus.downloading:
        return 'Downloading...';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.pending:
        return 'Pending';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
      default:
        return '';
    }
  }

  IconData _getTypeIcon() {
    switch (download.itemType?.toLowerCase()) {
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
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
