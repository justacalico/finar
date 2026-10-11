import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/services/download_service.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'detail_focusable_download_progress.dart';

Future<void> downloadDetailItem(
  WidgetRef ref,
  BuildContext context,
  MediaItem item,
) async {
  try {
    await ref.read(downloadProvider.notifier).downloadItem(item);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting download: ${item.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start download: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class DetailDownloadButton extends ConsumerWidget {
  final MediaItem item;

  const DetailDownloadButton({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadProvider);
    final existingDownload = downloadState.getTaskForItem(item.id);

    if (existingDownload != null) {
      switch (existingDownload.status) {
        case DownloadStatus.downloading:
          return DetailFocusableDownloadProgress(
            progress: existingDownload.progress,
            onPressed: () => ref
                .read(downloadProvider.notifier)
                .pauseDownload(existingDownload.id),
          );
        case DownloadStatus.paused:
          return GlassIconButton(
            icon: Icons.play_arrow_rounded,
            iconColor: AppColors.warning,
            size: 54,
            onPressed: () => ref
                .read(downloadProvider.notifier)
                .resumeDownload(existingDownload.id),
          );
        case DownloadStatus.completed:
          return GlassIconButton(
            icon: Icons.download_done_rounded,
            iconColor: AppColors.success,
            size: 54,
            onPressed: () =>
                _showDownloadOptions(context, ref, existingDownload.id),
          );
        case DownloadStatus.failed:
          return GlassIconButton(
            icon: Icons.error_outline_rounded,
            iconColor: AppColors.error,
            size: 54,
            onPressed: () => downloadDetailItem(ref, context, item),
          );
        case DownloadStatus.pending:
          return GlassIconButton(
            icon: Icons.hourglass_empty_rounded,
            size: 54,
            onPressed: () => ref
                .read(downloadProvider.notifier)
                .cancelDownload(existingDownload.id),
          );
        case DownloadStatus.cancelled:
          return GlassIconButton(
            icon: Icons.download_outlined,
            size: 54,
            onPressed: () => downloadDetailItem(ref, context, item),
          );
      }
    }

    return GlassIconButton(
      icon: Icons.download_outlined,
      size: 54,
      onPressed: () => downloadDetailItem(ref, context, item),
    );
  }

  void _showDownloadOptions(
    BuildContext context,
    WidgetRef ref,
    String taskId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Download Options'),
        content: const Text(
          'This item has been downloaded. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadProvider.notifier).deleteDownload(taskId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download removed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Remove Download',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
