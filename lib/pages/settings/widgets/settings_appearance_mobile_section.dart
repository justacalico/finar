import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/providers/providers.dart';
import 'settings_mobile_tiles.dart';

class SettingsAppearanceMobileSection extends ConsumerWidget {
  const SettingsAppearanceMobileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mobileSectionHeader('Appearance'),
        const SizedBox(height: 10),
        mobileCard(
          children: [
            mobileDropdownTile<ThemeMode>(
              context,
              'Theme',
              settings.themeMode,
              const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setThemeMode(v);
              },
            ),
            mobileDivider(),
            mobileDropdownTile<ThemeStyle>(
              context,
              'Theme style',
              settings.themeStyle,
              const [
                DropdownMenuItem(
                  value: ThemeStyle.standard,
                  child: Text('Default'),
                ),
                DropdownMenuItem(value: ThemeStyle.oled, child: Text('OLED')),
                DropdownMenuItem(
                  value: ThemeStyle.coloured,
                  child: Text('Coloured'),
                ),
              ],
              (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setThemeStyle(v);
              },
            ),
            mobileDivider(),
            mobileDropdownTile<int>(
              context,
              'Theme color',
              settings.themeColorIndex,
              accentColorOptions
                  .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                  .toList(),
              (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setThemeColorIndex(v);
              },
            ),
            mobileDivider(),
            mobileSwitchTile(
              context,
              'Use system accent',
              'Use device accent',
              settings.useSystemAccent,
              (v) => ref.read(settingsProvider.notifier).setUseSystemAccent(v),
            ),
            mobileDivider(),
            mobileDropdownTile<int>(
              context,
              'Accent color',
              settings.accentColorIndex,
              accentColorOptions
                  .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                  .toList(),
              (v) {
                if (v != null)
                  ref.read(settingsProvider.notifier).setAccentColorIndex(v);
              },
            ),
            mobileDivider(),
            mobileSwitchTile(
              context,
              'Enable Animations',
              'Show smooth transitions',
              settings.enableAnimations,
              (v) => ref.read(settingsProvider.notifier).setEnableAnimations(v),
            ),
            mobileDivider(),
            mobileSwitchTile(
              context,
              'Reduced Motion',
              'Minimize animations',
              settings.reducedMotion,
              (v) => ref.read(settingsProvider.notifier).setReducedMotion(v),
            ),
          ],
        ),
      ],
    );
  }
}
