import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/providers/providers.dart';
import 'settings_tiles.dart';

class SettingsAudioSection extends ConsumerWidget {
  const SettingsAudioSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader('Audio', 'Configure audio preferences'),
        const SizedBox(height: 24),
        settingsCard(
          context,
          title: 'Audio Options',
          icon: Icons.audiotrack,
          children: [
            dropdownTile<String>(
              context,
              title: 'Preferred Language',
              subtitle: 'Default audio track language',
              value: settings.audioLanguage,
              items: languageOptions
                  .map(
                    (l) => DropdownMenuItem(value: l.code, child: Text(l.name)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setAudioLanguage(v);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            switchTile(
              context,
              title: 'Normalize Volume',
              subtitle: 'Maintain consistent volume levels',
              value: settings.normalizeVolume,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setNormalizeVolume(v),
            ),
          ],
        ),
      ],
    );
  }
}
