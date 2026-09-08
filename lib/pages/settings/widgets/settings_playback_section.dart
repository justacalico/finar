import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/providers/providers.dart';
import 'settings_tiles.dart';

class SettingsPlaybackSection extends ConsumerWidget {
  const SettingsPlaybackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader('Playback', 'Configure video playback preferences'),
        const SizedBox(height: 24),
        settingsCard(
          context,
          title: 'Quality',
          icon: Icons.high_quality,
          children: [
            dropdownTile<int>(
              context,
              title: 'Default Video Quality',
              subtitle: 'Preferred resolution for streaming',
              value: settings.defaultVideoQuality,
              items: videoQualityOptions
                  .map(
                    (q) =>
                        DropdownMenuItem(value: q.value, child: Text(q.label)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setDefaultVideoQuality(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        settingsCard(
          context,
          title: 'Auto Play',
          icon: Icons.play_arrow,
          children: [
            switchTile(
              context,
              title: 'Auto Play Next Episode',
              subtitle: 'Automatically play the next episode when one ends',
              value: settings.autoPlayNext,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setAutoPlayNext(v),
            ),
            Divider(color: AppColors.glassBorder),
            switchTile(
              context,
              title: 'Skip Intros',
              subtitle: 'Automatically skip intro sequences',
              value: settings.skipIntros,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setSkipIntros(v),
            ),
            Divider(color: AppColors.glassBorder),
            switchTile(
              context,
              title: 'Skip Credits',
              subtitle: 'Automatically skip end credits',
              value: settings.skipCredits,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setSkipCredits(v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        settingsCard(
          context,
          title: 'Skip Duration',
          icon: Icons.fast_forward,
          children: [
            sliderTile(
              context,
              title: 'Forward Skip',
              subtitle: '${settings.forwardSkipDuration} seconds',
              value: settings.forwardSkipDuration.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setForwardSkipDuration(v.toInt()),
            ),
            Divider(color: AppColors.glassBorder),
            sliderTile(
              context,
              title: 'Rewind Skip',
              subtitle: '${settings.rewindSkipDuration} seconds',
              value: settings.rewindSkipDuration.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .setRewindSkipDuration(v.toInt()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        settingsCard(
          context,
          title: 'Sleep Timer',
          icon: Icons.timer_outlined,
          children: [
            dropdownTile<int>(
              context,
              title: 'Stop playback after',
              subtitle: sleepTimerOptions
                  .firstWhere(
                    (o) => o.value == settings.sleepTimerMinutes,
                    orElse: () => sleepTimerOptions.first,
                  )
                  .label,
              value: settings.sleepTimerMinutes,
              items: sleepTimerOptions
                  .map(
                    (o) =>
                        DropdownMenuItem(value: o.value, child: Text(o.label)),
                  )
                  .toList(),
              onChanged: (v) {
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
