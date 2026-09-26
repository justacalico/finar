import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A titled group of settings rows inside one card. Every settings
/// section renders through this so the page stays uniform.
class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsGroup({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Insets.md,
            Insets.lg,
            Insets.md,
            Insets.sm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.symmetric(horizontal: Insets.md),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingSwitch extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingSwitch({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

class SettingDropdown<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T>? onChanged;

  const SettingDropdown({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.options,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: DropdownButton<T>(
        value: value,
        underline: SizedBox.shrink(),
        borderRadius: BorderRadius.circular(Radii.card),
        items: [
          for (final e in options.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: onChanged == null
            ? null
            : (v) {
                if (v != null) onChanged!(v);
              },
      ),
      onTap: onChanged == null ? null : () {},
    );
  }
}

class SettingSlider extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double)? label;
  final ValueChanged<double> onChanged;

  const SettingSlider({
    super.key,
    required this.title,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Row(
        children: [
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: dim(48),
            child: Text(
              label?.call(value) ?? value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const SettingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      leading: icon != null ? Icon(icon, color: color) : null,
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
