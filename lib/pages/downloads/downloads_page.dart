import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/downloads_store.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/downloads_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/media_image.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final downloads = ref.watch(downloadsProvider);
    if (downloads.isEmpty) {
      return EmptyState(
          icon: Icons.download_outlined,
          message: l10n.emptyDownloads);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: downloads.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final record = downloads[i];
        return _DownloadTile(record: record);
      },
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  const _DownloadTile({required this.record});

  final DownloadRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final statusText = switch (record.status) {
      DownloadStatus.completed => l10n.downloaded,
      DownloadStatus.downloading =>
        '${l10n.downloading} ${(record.progress * 100).toStringAsFixed(0)}%',
      DownloadStatus.failed => l10n.downloadFailed,
      DownloadStatus.queued => l10n.downloading,
    };
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: MediaImage(
            url: record.imageId == null
                ? null
                : Uri.parse(
                    '${record.serverUrl}/Items/${record.imageId}/Images/Primary?maxWidth=112'),
            icon: record.type == 'Audio'
                ? Icons.music_note
                : Icons.movie_outlined,
          ),
        ),
        title: Text(record.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.subtitle != null)
              Text(record.subtitle!,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(statusText,
                    style: TextStyle(
                        fontSize: 12,
                        color: switch (record.status) {
                          DownloadStatus.failed => scheme.error,
                          DownloadStatus.completed =>
                            scheme.primary,
                          _ => scheme.onSurfaceVariant,
                        })),
                if (record.totalBytes > 0) ...[
                  const SizedBox(width: 8),
                  Text(formatBytes(record.totalBytes),
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
            if (record.status == DownloadStatus.downloading) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(value: record.progress),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (record.status == DownloadStatus.completed)
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                tooltip: l10n.play,
                onPressed: () => context.push('/item/${record.itemId}'),
              ),
            IconButton(
              icon: Icon(
                record.status == DownloadStatus.downloading
                    ? Icons.close
                    : Icons.delete_outline,
                color: record.status == DownloadStatus.downloading
                    ? null
                    : scheme.error,
              ),
              tooltip: record.status == DownloadStatus.downloading
                  ? l10n.cancelDownload
                  : l10n.deleteDownload,
              onPressed: () {
                final notifier =
                    ref.read(downloadsProvider.notifier);
                if (record.status == DownloadStatus.downloading) {
                  notifier.cancel(record.itemId);
                } else {
                  notifier.remove(record.itemId);
                }
              },
            ),
          ],
        ),
        onTap: () => context.push('/item/${record.itemId}'),
      ),
    );
  }
}
