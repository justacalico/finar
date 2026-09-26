import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'pages/auth_page.dart';
import 'pages/shell_page.dart';
import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';

class FinarApp extends ConsumerWidget {
  const FinarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final session = ref.watch(sessionProvider);

    return MaterialApp(
      title: 'Finar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light, settings.accent),
      darkTheme:
          AppTheme.build(Brightness.dark, settings.accent, oled: settings.oled),
      themeMode: settings.flutterThemeMode,
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
