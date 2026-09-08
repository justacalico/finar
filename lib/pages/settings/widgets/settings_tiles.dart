import 'package:flutter/material.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/widgets/widgets.dart';

Widget sectionHeader(String title, String subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}

Widget settingsCard(
  BuildContext context, {
  required String title,
  required IconData icon,
  required List<Widget> children,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  return GlassContainer(
    blur: AppTheme.blurLight,
    opacity: 0.05,
    padding: const EdgeInsets.all(20),
    // Transparent Material so the tiles inside still get ink splashes.
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}

Widget switchTile(
  BuildContext context, {
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title, style: AppTextStyles.bodyLarge),
    subtitle: Text(
      subtitle,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
    ),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.primary,
    ),
  );
}

Widget dropdownTile<T>(
  BuildContext context, {
  required String title,
  required String subtitle,
  required T value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title, style: AppTextStyles.bodyLarge),
    subtitle: Text(
      subtitle,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
    ),
    trailing: DropdownButton<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: AppColors.surfaceElevated,
      underline: const SizedBox(),
      style: AppTextStyles.bodyMedium,
    ),
  );
}

Widget sliderTile(
  BuildContext context, {
  required String title,
  required String subtitle,
  required double value,
  required double min,
  required double max,
  required int divisions,
  required ValueChanged<double> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: AppTextStyles.bodyLarge),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
      Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: AppColors.glassBorder,
        onChanged: onChanged,
      ),
    ],
  );
}
