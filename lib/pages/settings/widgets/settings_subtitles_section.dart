import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/providers/providers.dart';
import 'settings_tiles.dart';

class SettingsSubtitlesSection extends ConsumerWidget {
  const SettingsSubtitlesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader('Subtitles', 'Customize subtitle appearance'),
        const SizedBox(height: 24),
        settingsCard(
          context,
          title: 'Subtitle Options',
          icon: Icons.subtitles,
          children: [
            switchTile(
              context,
              title: 'Enable Subtitles',
              subtitle: 'Show subtitles when available',
              value: settings.subtitlesEnabled,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setSubtitlesEnabled(v),
            ),
            const Divider(color: AppColors.glassBorder),
            dropdownTile<String>(
              context,
              title: 'Preferred Language',
              subtitle: 'Default subtitle language',
              value: settings.subtitleLanguage,
              items: languageOptions
                  .map(
                    (l) => DropdownMenuItem(value: l.code, child: Text(l.name)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setSubtitleLanguage(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        settingsCard(
          context,
          title: 'Appearance',
          icon: Icons.text_fields,
          children: [
            sliderTile(
              context,
              title: 'Subtitle Size',
              subtitle: '${(settings.subtitleSize * 100).toInt()}%',
              value: settings.subtitleSize,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setSubtitleSize(v),
            ),
          ],
        ),
      ],
    );
  }
}
