import 'package:flutter/material.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';

Widget mobileSectionHeader(String title) {
  return Text(
    title,
    style: AppTextStyles.titleMedium.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: -0.2,
    ),
  );
}

Widget mobileCard({required List<Widget> children}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
    ),
    child: Column(children: children),
  );
}

Widget mobileSwitchTile(
  BuildContext context,
  String title,
  String subtitle,
  bool value,
  ValueChanged<bool> onChanged,
) {
  return SwitchListTile(
    title: Text(title, style: AppTextStyles.bodyLarge),
    subtitle: Text(
      subtitle,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
    ),
    value: value,
    onChanged: onChanged,
    activeThumbColor: Theme.of(context).colorScheme.primary,
    activeTrackColor: Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.3),
    inactiveThumbColor: AppColors.textSecondary,
    inactiveTrackColor: AppColors.divider.withValues(alpha: 0.3),
  );
}

Widget mobileDropdownTile<T>(
  BuildContext context,
  String title,
  T value,
  List<DropdownMenuItem<T>> items,
  ValueChanged<T?> onChanged,
) {
  return ListTile(
    title: Text(title, style: AppTextStyles.bodyLarge),
    trailing: DropdownButton<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: AppColors.surfaceElevated,
      underline: const SizedBox(),
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSecondary,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

Widget mobileDivider() {
  return Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1);
}
