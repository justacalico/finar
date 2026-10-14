import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finar/core/storage/session_store.dart';
import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/models/models.dart';
import 'package:finar/l10n/generated/app_localizations.dart';
import 'package:finar/providers/core_providers.dart';
import 'package:finar/widgets/player_backend.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:finar/router.dart';
import 'package:finar/theme/theme.dart';
import 'package:finar/widgets/title_bar.dart';
import 'fake_backend.dart';
import 'fake_client.dart';

class TestHarness {
  TestHarness(this.client, this.backend);

  final FakeJellyfinClient client;
  final FakePlayerBackend backend;

  static Future<({TestHarness harness, List<Override> overrides})> create({
    bool signedIn = true,
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final prefsInstance = await SharedPreferences.getInstance();
    final client = FakeJellyfinClient();
    final backend = FakePlayerBackend();
    FlutterSecureStorage.setMockInitialValues({});
    final overrides = <Override>[
      sharedPrefsProvider.overrideWithValue(prefsInstance),
      playerBackendProvider.overrideWithValue(backend),
      jellyfinClientProvider.overrideWithValue(signedIn ? client : null),
    ];
    return (harness: TestHarness(client, backend), overrides: overrides);
  }
}

Widget testApp({
  required Widget child,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.dark,
  Locale? locale,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.light(0xFFAA5CC3),
      darkTheme: AppTheme.dark(0xFFAA5CC3),
      themeMode: themeMode,
      locale: locale,
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
      home: child is Scaffold ? child : Scaffold(body: child),
    ),
  );
}

Session testSession() => const Session(
      serverUrl: 'http://test.local',
      serverName: 'Test Server',
      accessToken: 'token123',
      user: JellyfinUser(
          id: 'user1', name: 'Calico', primaryImageTag: 'tag'),
    );

class FakeSessionNotifier extends SessionNotifier {
  FakeSessionNotifier(this._session, {this.fakeClient});
  final Session? _session;
  final JellyfinClient? fakeClient;

  @override
  Session? build() => _session;

  @override
  Future<JellyfinClient> clientFor(String serverUrl,
          {String? accessToken, String? userId}) async =>
      fakeClient ?? FakeJellyfinClient(serverUrl: serverUrl, accessToken: accessToken, userId: userId);
}

Override signedInOverride(Session session) =>
    sessionProvider.overrideWith(() => FakeSessionNotifier(session));

Widget routedTestApp({
  required RouterConfig<Object> router,
  List<Override> overrides = const [],
  Locale? locale,
  ProviderContainer? container,
}) {
  if (container != null) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.dark(0xFFAA5CC3),
        themeMode: ThemeMode.dark,
        locale: locale,
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
        routerConfig: router,
      ),
    );
  }
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      theme: AppTheme.dark(0xFFAA5CC3),
      themeMode: ThemeMode.dark,
      locale: locale,
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
      routerConfig: router,
    ),
  );
}

/// A routed test app that drives the real routerProvider. Requires
/// bootstrappedProvider and sessionProvider overrides to control auth.
class RoutedTestApp extends ConsumerWidget {
  const RoutedTestApp(
      {super.key, this.locale, this.showTitleBar = true});

  final Locale? locale;
  final bool showTitleBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      theme: AppTheme.light(0xFFAA5CC3),
      darkTheme: AppTheme.dark(0xFFAA5CC3),
      themeMode: ThemeMode.dark,
      locale: locale,
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
      routerConfig: router,
      builder: (context, child) => Column(
        children: [
          if (showTitleBar) const TitleBar(actions: null),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}
