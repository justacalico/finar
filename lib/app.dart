import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'pages/auth_page.dart';
import 'pages/shell_page.dart';
import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/ui_scaler.dart';

class FinarApp extends ConsumerWidget {
  const FinarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final session = ref.watch(sessionProvider);

    final notifier = ref.read(settingsProvider.notifier);
    final zoomBindings = <ShortcutActivator, VoidCallback>{
      for (final key in [
        LogicalKeyboardKey.equal,
        LogicalKeyboardKey.add,
        LogicalKeyboardKey.numpadAdd,
      ])
        SingleActivator(key, control: true): notifier.zoomIn,
      for (final key in [
        LogicalKeyboardKey.minus,
        LogicalKeyboardKey.numpadSubtract,
      ])
        SingleActivator(key, control: true): notifier.zoomOut,
      const SingleActivator(LogicalKeyboardKey.digit0, control: true):
          notifier.resetZoom,
    };

    return MaterialApp(
      title: 'Finar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light, settings.accent),
      darkTheme:
          AppTheme.build(Brightness.dark, settings.accent, oled: settings.oled),
      themeMode: settings.flutterThemeMode,
      builder: (context, child) => CallbackShortcuts(
        bindings: zoomBindings,
        child: Focus(
          autofocus: true,
          child:
              UiScaler(scale: settings.uiScale, child: child!),
        ),
      ),
      home: switch (session) {
        SessionLoading() => const Scaffold(
            body: Center(
                child: CircularProgressIndicator.adaptive())),
        SignedOut() => const AuthPage(),
        SignedIn() => const ShellPage(),
      },
    );
  }
}
