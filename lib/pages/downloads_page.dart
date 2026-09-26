import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/downloads_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/providers.dart';
import '../widgets/app_image.dart';
import '../widgets/async_view.dart';
import '../widgets/focusable.dart';
import '../widgets/page_header.dart';
import 'player_page.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(downloadsProvider);
    return Column(
      children: [
        const PageHeader(title: 'Downloads'),
        Expanded(
          child: entries.isEmpty
              ? const EmptyView(
                  icon: Icons.download_outlined,
                  title: 'No downloads',
                  subtitle:
                      'Downloaded items are stored on this device for offline playback.')
              : ListView.separated(
                  padding: const EdgeInsets.all(Insets.md),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: Insets.sm),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    return _DownloadTile(entry: e);
                  },
                ),
        ),
      ],
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  final DownloadEntry entry;
  const _DownloadTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(jellyfinClientProvider);
    final item = entry.item;
    return Focusable(
      onTap: entry.status == DownloadStatus.done
          ? () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PlayerPage(item: item)))
          : null,
      onLongPress: () =>
          ref.read(downloadsProvider.notifier).remove(item.id),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Insets.sm),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: AppImage(
                  client.thumbUrl(item, maxWidth: 220),
                  shape: ArtShape.backdrop,
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    if (entry.status == DownloadStatus.downloading)
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                              value: entry.progress > 0
                                  ? entry.progress
                                  : null),
                          const SizedBox(height: 4),
                          Text(
                            '${(entry.progress * 100).toStringAsFixed(0)}%',
                            style:
                                Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      )
                    else if (entry.status == DownloadStatus.failed)
                      Text('Download failed',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error))
                    else
                      Text(
                        [
                          if (item.metaLine != null) item.metaLine!,
                          if (item.mediaSources.isNotEmpty &&
                              item.mediaSources.first.size != null)
                            '${(item.mediaSources.first.size! / 1073741824).toStringAsFixed(1)} GB',
                        ].join('  •  '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remove download',
                onPressed: () => ref
                    .read(downloadsProvider.notifier)
                    .remove(item.id),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Details',
                onPressed: () => ref
                    .read(shellNavProvider.notifier)
                    .openDetail(item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
