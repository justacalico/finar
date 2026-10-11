import 'dart:io';

import 'package:finar/core/api/auth_service.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/providers/auth_provider.dart';
import 'package:finar/providers/connectivity_provider.dart';
import 'package:finar/providers/download_provider.dart';
import 'package:finar/providers/library_provider.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:finar/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_services.dart';
import 'golden_fixtures.dart';

const goldenDesktopSize = Size(1600, 1000);
const goldenMobileSize = Size(430, 932);

Directory? _goldenTempDir;

void mockGoldenPlatformChannels() {
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'Finar',
    packageName: 'gitlab.httpanimations.finar',
    version: '5.0.0',
    buildNumber: '1',
    buildSignature: '1',
  );

  _goldenTempDir ??= Directory.systemTemp.createTempSync('finar_golden');
  final tempPath = _goldenTempDir!.path;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async {
          switch (call.method) {
            case 'getExternalStorageDirectories':
            case 'getExternalCacheDirectories':
              return [tempPath];
            default:
              return tempPath;
          }
        },
      );
}

List<Override> goldenOverrides({
  AuthState authState = const AuthState.authenticated(user: goldenUser),
  List<SavedProfile> profiles = const [],
  List<Override> extra = const [],
}) {
  final authService = FakeAuthService(profiles: profiles);
  final api = FakeJellyfinApi();
  final mediaService = FakeMediaService();
  return [
    jellyfinApiProvider.overrideWithValue(api),
    mediaServiceProvider.overrideWithValue(mediaService),
    authServiceProvider.overrideWithValue(authService),
    authProvider.overrideWith(
      (ref) => GoldenAuthNotifier(authService, api, authState),
    ),
    downloadServiceProvider.overrideWith((ref) => FakeDownloadService()),
    downloadProvider.overrideWith((ref) => FakeDownloadNotifier()),
    playerProvider.overrideWith(
      (ref) => PlayerNotifier.uninitialized(
        mediaService,
        FakeDownloadService(),
      ),
    ),
    isOnlineProvider.overrideWithValue(true),
    librariesProvider.overrideWith((ref) => Future.value(goldenLibraries)),
    homeDataProvider.overrideWith((ref) async => goldenHomeData),
    libraryProvider.overrideWith(
      (ref) => LibraryNotifier(mediaService, api),
    ),
    favoritesProvider(null).overrideWith((ref) async => goldenHomeData.favorites),
    ...extra,
  ];
}

ProviderContainer goldenContainer({
  AuthState authState = const AuthState.authenticated(user: goldenUser),
  List<SavedProfile> profiles = const [],
  List<Override> extra = const [],
}) {
  return ProviderContainer(
    overrides: goldenOverrides(
      authState: authState,
      profiles: profiles,
      extra: extra,
    ),
  );
}

Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  Size size = goldenDesktopSize,
  List<Override> overrides = const [],
  ProviderContainer? container,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final accent = accentColorOptions[0].$3;
  AppColors.set(
    brightness: Brightness.dark,
    oled: false,
    themeColor: accent,
    accentColor: accent,
    useSystemAccent: false,
  );

  final scope = container != null
      ? UncontrolledProviderScope(container: container, child: _GoldenApp(child))
      : ProviderScope(
          overrides: goldenOverrides(extra: overrides),
          child: _GoldenApp(child),
        );

  // cached_network_image's stream pipeline cannot emit inside the fake test
  // zone, so the first pumps happen in runAsync where the mock HTTP layer,
  // cache store and image codecs run on the real event loop.
  await tester.runAsync(() async {
    await tester.pumpWidget(scope);
    await tester.pump();
    if (settle) {
      for (var i = 0; i < 8; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        await tester.pump();
      }
    }
  });
  if (settle) {
    await _goldenSettleFake(tester);
  }
}

// After runAsync has let the real async work finish, advance the fake clock
// so entrance animations and repeating placeholders land on a deterministic
// phase, then run past the one-shot debounce timers the cache store schedules
// so nothing is left pending at teardown.
Future<void> goldenSettle(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  });
  await _goldenSettleFake(tester);
}

Future<void> _goldenSettleFake(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  await tester.pump(const Duration(seconds: 12));
  await tester.pump();
}

Future<void> expectGolden(WidgetTester tester, String name) {
  return expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

class _GoldenApp extends StatelessWidget {
  const _GoldenApp(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final accent = accentColorOptions[0].$3;
    final base = AppTheme.darkThemeWithPrimary(accent);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.apply(fontFamily: 'Inter'),
        appBarTheme: base.appBarTheme.copyWith(
          titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
            fontFamily: 'Inter',
          ),
        ),
      ),
      home: child,
    );
  }
}
