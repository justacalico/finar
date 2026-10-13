import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/storage/settings_store.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'router.dart';
import 'theme/theme.dart';
import 'widgets/platform.dart';
import 'widgets/title_bar.dart';
import 'widgets/window_actions.dart';

class FinarApp extends ConsumerStatefulWidget {
  const FinarApp({super.key});

  @override
  ConsumerState<FinarApp> createState() => _FinarAppState();
}

class _FinarAppState extends ConsumerState<FinarApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(sessionProvider.notifier).restore());
  }

  Locale? _resolveLocale(String? code) {
    if (code == null) return null;
    return switch (code) {
      'en_GB' => const Locale('en', 'GB'),
      'zh' => const Locale('zh'),
      'ru' => const Locale('ru'),
      'ga' => const Locale('ga'),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    final accent = settings.accentColor;
    return MaterialApp.router(
      title: 'Finar',
      routerConfig: router,
      themeMode: AppTheme.materialThemeMode(settings.themeMode),
      theme: AppTheme.light(accent),
      darkTheme: settings.themeMode == AppThemeMode.oled
          ? AppTheme.oled(accent)
          : AppTheme.dark(accent),
      locale: _resolveLocale(settings.locale),
      supportedLocales: const [
        Locale('en', 'GB'),
        Locale('en'),
        Locale('zh'),
        Locale('ru'),
        Locale('ga'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) {
        if (!isDesktopPlatform) return child ?? const SizedBox.shrink();
        final location =
            GoRouterState.of(context).uri.path;
        final hideBar = location == '/play';
        return Column(
          children: [
            if (!hideBar)
              const TitleBar(actions: WindowManagerActions()),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
