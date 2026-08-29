import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/providers/providers.dart';
import 'settings_mobile_tiles.dart';

class SettingsAudioMobileSection extends ConsumerWidget {
  const SettingsAudioMobileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mobileSectionHeader('Audio'),
        const SizedBox(height: 10),
        mobileCard(
          children: [
            mobileDropdownTile<String>(
              context,
              'Preferred Language',
              settings.audioLanguage,
              languageOptions
                  .map(
                    (l) => DropdownMenuItem(value: l.code, child: Text(l.name)),
                  )
                  .toList(),
              (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setAudioLanguage(v);
              },
            ),
            mobileDivider(),
            mobileSwitchTile(
              context,
              'Normalize Volume',
              'Keep consistent volume levels',
              settings.normalizeVolume,
              (v) => ref.read(settingsProvider.notifier).setNormalizeVolume(v),
            ),
          ],
        ),
      ],
    );
  }
}
