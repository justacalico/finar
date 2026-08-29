import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/services/download_service.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'detail_liquid_glass_menu_item.dart';

class DetailLiquidGlassMenu extends StatelessWidget {
  final MediaItem item;
  final DownloadTask? downloadTask;
  final bool isInWatchlist;
  final VoidCallback onFavorite;
  final VoidCallback onWatched;
  final VoidCallback onWatchlist;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  const DetailLiquidGlassMenu({
    super.key,
    required this.item,
    required this.downloadTask,
    required this.isInWatchlist,
    required this.onFavorite,
    required this.onWatched,
    required this.onWatchlist,
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main menu container
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.white.withValues(alpha: 0.25),
                      AppColors.white.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Watchlist
                    DetailLiquidGlassMenuItem(
                      icon: isInWatchlist
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      iconColor: isInWatchlist
                          ? AppColors.accentYellow
                          : AppColors.white,
                      label: isInWatchlist
                          ? 'Remove from Watchlist'
                          : 'Add to Watchlist',
                      onTap: () {
                        Navigator.pop(context);
                        onWatchlist();
                      },
                    ),
                    _buildDivider(),
                    // Favorite
                    DetailLiquidGlassMenuItem(
                      icon: (item.isFavorite == true)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      iconColor: (item.isFavorite == true)
                          ? AppColors.accentRed
                          : AppColors.white,
                      label: (item.isFavorite == true)
                          ? 'Remove from Favorites'
                          : 'Add to Favorites',
                      onTap: () {
                        Navigator.pop(context);
                        onFavorite();
                      },
                    ),
                    _buildDivider(),
                    // Mark as watched
                    DetailLiquidGlassMenuItem(
                      icon: (item.isPlayed == true)
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      iconColor: (item.isPlayed == true)
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.white,
                      label: (item.isPlayed == true)
                          ? 'Mark as Unwatched'
                          : 'Mark as Watched',
                      onTap: () {
                        Navigator.pop(context);
                        onWatched();
                      },
                    ),
                    _buildDivider(),
                    // Download (hide on web)
                    if (!kIsWeb) ...[
                      DetailLiquidGlassMenuItem(
                        icon: _getDownloadIcon(),
                        iconColor: _getDownloadIconColor(context),
                        label: _getDownloadText(),
                        onTap: () {
                          Navigator.pop(context);
                          onDownload();
                        },
                      ),
                      _buildDivider(),
                    ],
                    // Share
                    DetailLiquidGlassMenuItem(
                      icon: Icons.share_outlined,
                      iconColor: AppColors.white,
                      label: 'Share',
                      onTap: () {
                        Navigator.pop(context);
                        onShare();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cancel button
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.white.withValues(alpha: 0.3),
                      AppColors.white.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.white.withValues(alpha: 0),
            AppColors.white.withValues(alpha: 0.2),
            AppColors.white.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  IconData _getDownloadIcon() {
    if (downloadTask == null) return Icons.download_outlined;
    switch (downloadTask!.status) {
      case DownloadStatus.downloading:
        return Icons.downloading;
      case DownloadStatus.paused:
        return Icons.pause_circle_outline;
      case DownloadStatus.completed:
        return Icons.download_done;
      case DownloadStatus.failed:
        return Icons.refresh;
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getDownloadIconColor(BuildContext context) {
    if (downloadTask == null) return AppColors.white;
    switch (downloadTask!.status) {
      case DownloadStatus.downloading:
        return Theme.of(context).colorScheme.primary;
      case DownloadStatus.paused:
        return AppColors.accentYellow;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.error;
      default:
        return AppColors.white;
    }
  }

  String _getDownloadText() {
    if (downloadTask == null) return 'Download';
    switch (downloadTask!.status) {
      case DownloadStatus.downloading:
        return 'Downloading (${(downloadTask!.progress * 100).toInt()}%)';
      case DownloadStatus.paused:
        return 'Resume Download';
      case DownloadStatus.completed:
        return 'Downloaded';
      case DownloadStatus.failed:
        return 'Retry Download';
      default:
        return 'Download Pending';
    }
  }
}
