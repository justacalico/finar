import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/providers/providers.dart';
import 'settings_tiles.dart';

class SettingsNetworkSection extends ConsumerWidget {
  const SettingsNetworkSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader('Network', 'Configure streaming and caching'),
        const SizedBox(height: 24),
        settingsCard(
          context,
          title: 'Streaming',
          icon: Icons.stream,
          children: [
            dropdownTile<int>(
              context,
              title: 'Max Streaming Bitrate',
              subtitle: 'Limit bandwidth usage',
              value: settings.maxStreamingBitrate,
              items: videoQualityOptions
                  .map(
                    (q) => DropdownMenuItem(
                      value: q.bitrate,
                      child: Text(
                        '${q.label} (${(q.bitrate / 1000000).toStringAsFixed(0)} Mbps)',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setMaxStreamingBitrate(v);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            switchTile(
              context,
              title: 'Allow Cellular Streaming',
              subtitle: 'Stream over mobile data',
              value: settings.allowCellularStreaming,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setAllowCellularStreaming(v),
            ),
            const Divider(color: AppColors.glassBorder),
            switchTile(
              context,
              title: 'Preload Next Episode',
              subtitle: 'Buffer upcoming content for smooth playback',
              value: settings.preloadNextEpisode,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setPreloadNextEpisode(v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        settingsCard(
          context,
          title: 'Cache',
          icon: Icons.storage,
          children: [
            switchTile(
              context,
              title: 'Cache Images',
              subtitle: 'Store images locally for faster loading',
              value: settings.cacheImages,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setCacheImages(v),
            ),
            const Divider(color: AppColors.glassBorder),
            sliderTile(
              context,
              title: 'Image Cache Size',
              subtitle: '${settings.imageCacheSize} MB',
              value: settings.imageCacheSize.toDouble(),
              min: 100,
              max: 2000,
              divisions: 19,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setImageCacheSize(v.toInt()),
            ),
          ],
        ),
      ],
    );
  }
}
