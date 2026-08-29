import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/widgets/widgets.dart';
import 'settings/widgets/settings_desktop.dart';
import 'settings/widgets/settings_mobile.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveLayout(
      desktopBuilder: () => const SettingsDesktop(),
      mobileBuilder: () => const SettingsMobile(),
    );
  }
}
