import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/services/download_service.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/pages/adaptive_pages.dart';
import 'package:finar/providers/providers.dart';

void handleMobileDownloadAction(
  WidgetRef ref,
  BuildContext context,
  MediaItem item,
  DownloadTask? task,
) {
  if (task == null) {
    downloadMobileItem(ref, context, item);
    return;
  }
  switch (task.status) {
    case DownloadStatus.downloading:
      ref.read(downloadProvider.notifier).pauseDownload(task.id);
      break;
    case DownloadStatus.paused:
    case DownloadStatus.failed:
      ref.read(downloadProvider.notifier).resumeDownload(task.id);
      break;
    case DownloadStatus.completed:
      // Already downloaded, could show options
      break;
    default:
      downloadMobileItem(ref, context, item);
  }
}

void downloadMobileItem(WidgetRef ref, BuildContext context, MediaItem item) {
  final downloadState = ref.read(downloadProvider);
  final existingTask = downloadState.getTaskForItem(item.id);

  if (existingTask != null) {
    // Show options for existing download
    showMobileDownloadOptions(ref, context, existingTask);
  } else {
    // Start new download
    ref.read(downloadProvider.notifier).downloadItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${item.name}"'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => showDownloadsPage(context),
        ),
      ),
    );
  }
}

Future<void> playDownloadedItem(
  WidgetRef ref,
  BuildContext context,
  DownloadTask task,
) async {
  if (task.localPath == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download file not found')));
    }
    return;
  }

  try {
    // Fetch the MediaItem details
    final mediaService = ref.read(mediaServiceProvider);
    final item = await mediaService.getItemDetails(task.itemId);

    // Play from local file
    ref.read(playerProvider.notifier).playLocalFile(item, task.localPath!);

    // Navigate to player for video content
    final isMusic =
        item.type == MediaType.audio ||
        item.type == MediaType.album ||
        item.type == MediaType.musicVideo;

    if (!isMusic && context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AdaptivePlayerPage()));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to play: $e')));
    }
  }
}

void showMobileDownloadOptions(
  WidgetRef ref,
  BuildContext context,
  DownloadTask task,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.itemName, style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Status: ${downloadStatusText(task.status)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (task.status == DownloadStatus.downloading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.formattedDownloadedSize} / ${task.formattedSize}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (task.status == DownloadStatus.downloading)
            ListTile(
              leading: Icon(Icons.pause),
              title: const Text('Pause Download'),
              onTap: () {
                ref.read(downloadProvider.notifier).pauseDownload(task.id);
                Navigator.pop(context);
              },
            ),
          if (task.canResume)
            ListTile(
              leading: Icon(Icons.play_arrow),
              title: const Text('Resume Download'),
              onTap: () {
                ref.read(downloadProvider.notifier).resumeDownload(task.id);
                Navigator.pop(context);
              },
            ),
          if (task.status == DownloadStatus.completed)
            ListTile(
              leading: Icon(Icons.play_circle_outline),
              title: const Text('Play Downloaded'),
              onTap: () {
                Navigator.pop(context);
                playDownloadedItem(ref, context, task);
              },
            ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text(
              'Delete Download',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              ref.read(downloadProvider.notifier).deleteDownload(task.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

String downloadStatusText(DownloadStatus status) {
  switch (status) {
    case DownloadStatus.pending:
      return 'Waiting...';
    case DownloadStatus.downloading:
      return 'Downloading';
    case DownloadStatus.paused:
      return 'Paused';
    case DownloadStatus.completed:
      return 'Downloaded';
    case DownloadStatus.failed:
      return 'Failed';
    case DownloadStatus.cancelled:
      return 'Cancelled';
  }
}

void showDownloadsPage(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AdaptiveDownloadsPage()));
}
