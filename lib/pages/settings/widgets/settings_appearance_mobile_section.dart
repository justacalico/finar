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
            mobileDropdownTile<AppThemeMode>(
              context,
              'Theme',
              settings.appThemeMode,
              const [
                DropdownMenuItem(
                  value: AppThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.dark,
                  child: Text('Dark'),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.oled,
                  child: Text('OLED'),
                ),
              ],
              (v) {
                if (v != null) {
                  ref.read(settingsProvider.notifier).setAppThemeMode(v);
                }
              },
            ),
            mobileDivider(),
            mobileDropdownTile<int>(
              context,
              'Accent color',
              settings.useSystemAccent ? -1 : settings.accentColorIndex,
              [
                const DropdownMenuItem(value: -1, child: Text('System')),
                ...accentColorOptions.map(
                  (o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)),
                ),
              ],
              (v) {
                if (v == null) {
                  return;
                }
                final notifier = ref.read(settingsProvider.notifier);
                if (v == -1) {
                  notifier.setUseSystemAccent(true);
                } else {
                  notifier.setAccentColorIndex(v);
                  notifier.setUseSystemAccent(false);
                }
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
