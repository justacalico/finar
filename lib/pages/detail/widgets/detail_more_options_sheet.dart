import 'package:flutter/material.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/widgets/widgets.dart';

class DetailMoreOptionsSheet extends StatelessWidget {
  final MediaItem item;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onMediaInfo;
  final VoidCallback? onReportIssue;

  const DetailMoreOptionsSheet({
    super.key,
    required this.item,
    this.onDownload,
    this.onShare,
    this.onAddToPlaylist,
    this.onMediaInfo,
    this.onReportIssue,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: AppTheme.blurHeavy,
      opacity: 0.1,
      borderRadius: AppTheme.radiusXl,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          _buildOption(
            context,
            Icons.download_outlined,
            'Download',
            onDownload,
          ),
          _buildOption(
            context,
            Icons.playlist_add,
            'Add to Playlist',
            onAddToPlaylist,
          ),
          _buildOption(context, Icons.share_outlined, 'Share', onShare),
          _buildOption(context, Icons.info_outline, 'Media Info', onMediaInfo),
          _buildOption(
            context,
            Icons.bug_report_outlined,
            'Report Issue',
            onReportIssue,
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap != null
          ? () {
              Navigator.pop(context);
              onTap();
            }
          : () {},
    );
  }
}
