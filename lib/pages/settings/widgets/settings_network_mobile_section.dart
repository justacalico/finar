import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/providers/providers.dart';
import 'settings_mobile_tiles.dart';

class SettingsNetworkMobileSection extends ConsumerWidget {
  const SettingsNetworkMobileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mobileSectionHeader('Network'),
        const SizedBox(height: 10),
        mobileCard(
          children: [
            mobileSwitchTile(
              context,
              'Allow Cellular Streaming',
              'Stream over mobile data',
              settings.allowCellularStreaming,
              (v) => ref
                  .read(settingsProvider.notifier)
                  .setAllowCellularStreaming(v),
            ),
            mobileDivider(),
            mobileSwitchTile(
              context,
              'Preload Next Episode',
              'Buffer upcoming content',
              settings.preloadNextEpisode,
              (v) =>
                  ref.read(settingsProvider.notifier).setPreloadNextEpisode(v),
            ),
            mobileDivider(),
            mobileSwitchTile(
              context,
              'Cache Images',
              'Store images locally',
              settings.cacheImages,
              (v) => ref.read(settingsProvider.notifier).setCacheImages(v),
            ),
          ],
        ),
      ],
    );
  }
}
