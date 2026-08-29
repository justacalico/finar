import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/providers/providers.dart';
import 'settings_mobile_tiles.dart';

class SettingsPlaybackMobileSection extends ConsumerWidget {
  const SettingsPlaybackMobileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mobileSectionHeader('Playback'),
        const SizedBox(height: 10),
        mobileCard(
          children: [
            mobileSwitchTile(
              context,
              'Auto Play Next',
              'Automatically play next episode',
              settings.autoPlayNext,
              (v) => ref.read(settingsProvider.notifier).setAutoPlayNext(v),
            ),
            mobileDivider(),
            mobileSwitchTile(
              context,
              'Skip Intros',
              'Automatically skip intros',
              settings.skipIntros,
              (v) => ref.read(settingsProvider.notifier).setSkipIntros(v),
            ),
            mobileDivider(),
            mobileSwitchTile(
              context,
              'Skip Credits',
              'Automatically skip credits',
              settings.skipCredits,
              (v) => ref.read(settingsProvider.notifier).setSkipCredits(v),
            ),
            mobileDivider(),
            mobileDropdownTile<int>(
              context,
              'Default Quality',
              settings.defaultVideoQuality,
              videoQualityOptions
                  .map(
                    (q) =>
                        DropdownMenuItem(value: q.value, child: Text(q.label)),
                  )
                  .toList(),
              (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setDefaultVideoQuality(v);
              },
            ),
            mobileDivider(),
            mobileDropdownTile<int>(
              context,
              'Sleep Timer',
              settings.sleepTimerMinutes,
              sleepTimerOptions
                  .map(
                    (o) =>
                        DropdownMenuItem(value: o.value, child: Text(o.label)),
                  )
                  .toList(),
              (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setSleepTimerMinutes(v);
              },
            ),
          ],
        ),
      ],
    );
  }
}
