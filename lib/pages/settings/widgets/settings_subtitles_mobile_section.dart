import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/providers/providers.dart';
import 'settings_mobile_tiles.dart';

class SettingsSubtitlesMobileSection extends ConsumerWidget {
  const SettingsSubtitlesMobileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mobileSectionHeader('Subtitles'),
        const SizedBox(height: 10),
        mobileCard(
          children: [
            mobileSwitchTile(
              context,
              'Enable Subtitles',
              'Show subtitles when available',
              settings.subtitlesEnabled,
              (v) => ref.read(settingsProvider.notifier).setSubtitlesEnabled(v),
            ),
            mobileDivider(),
            mobileDropdownTile<String>(
              context,
              'Language',
              settings.subtitleLanguage,
              languageOptions
                  .map(
                    (l) => DropdownMenuItem(value: l.code, child: Text(l.name)),
                  )
                  .toList(),
              (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setSubtitleLanguage(v);
              },
            ),
          ],
        ),
      ],
    );
  }
}
