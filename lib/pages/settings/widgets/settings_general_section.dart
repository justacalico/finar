import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/providers/providers.dart';
import 'settings_tiles.dart';

class SettingsGeneralSection extends ConsumerWidget {
  final VoidCallback onReset;

  const SettingsGeneralSection({super.key, required this.onReset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader('General', 'Customize your app experience'),
        const SizedBox(height: 24),
        settingsCard(
          context,
          title: 'Appearance',
          icon: Icons.palette_outlined,
          children: [
            dropdownTile<AppThemeMode>(
              context,
              title: 'Theme',
              subtitle: settings.appThemeMode == AppThemeMode.system
                  ? 'Follow system'
                  : settings.appThemeMode == AppThemeMode.oled
                  ? 'OLED, pure black'
                  : settings.appThemeMode.label,
              value: settings.appThemeMode,
              items: const [
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
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsProvider.notifier).setAppThemeMode(v);
                }
              },
            ),
            Divider(color: AppColors.glassBorder),
            dropdownTile<int>(
              context,
              title: 'Accent color',
              subtitle: settings.useSystemAccent
                  ? 'System'
                  : accentColorOptions[settings.accentColorIndex.clamp(
                          0,
                          accentColorOptions.length - 1,
                        )]
                        .$2,
              value: settings.useSystemAccent ? -1 : settings.accentColorIndex,
              items: [
                const DropdownMenuItem(value: -1, child: Text('System')),
                ...accentColorOptions.map(
                  (o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)),
                ),
              ],
              onChanged: (v) {
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
            Divider(color: AppColors.glassBorder),
            switchTile(
              context,
              title: 'Enable Animations',
              subtitle: 'Show smooth transitions and effects',
              value: settings.enableAnimations,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setEnableAnimations(v),
            ),
            Divider(color: AppColors.glassBorder),
            switchTile(
              context,
              title: 'Reduced Motion',
              subtitle: 'Minimize animations for accessibility',
              value: settings.reducedMotion,
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setReducedMotion(v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        settingsCard(
          context,
          title: 'Reset',
          icon: Icons.restore,
          children: [
            Text(
              'Reset all settings to their default values.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restore, size: 20),
              label: const Text('Reset to Defaults'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                foregroundColor: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
