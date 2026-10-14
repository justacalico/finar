import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finar/pages/home/home_page.dart';
import 'package:finar/pages/library/library_page.dart';
import 'package:finar/providers/library_providers.dart';
import 'package:finar/pages/login/login_page.dart';
import 'package:finar/pages/player/player_page.dart';
import 'package:finar/pages/profiles/profiles_page.dart';
import 'package:finar/pages/settings/settings_page.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:finar/providers/session_provider.dart';

import 'helpers/fake_client.dart';
import 'helpers/path_provider_mock.dart';
import 'helpers/secure_storage_mock.dart';
import 'helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TestHarness> pump(
    WidgetTester tester,
    Widget page, {
    Size size = const Size(1280, 900),
    bool signedIn = true,
    List<Override> extra = const [],
    void Function(FakeJellyfinClient client)? seed,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    mockPathProvider();
    mockPackageInfo();
    final result = await TestHarness.create(signedIn: signedIn);
    seed?.call(result.harness.client);
    await tester.pumpWidget(testApp(
      overrides: [
        ...result.overrides,
        if (signedIn)
          sessionProvider
              .overrideWith(() => FakeSessionNotifier(testSession())),
        ...extra,
      ],
      child: page,
    ));
    await tester.pumpAndSettle();
    return result.harness;
  }

  group('LoginPage', () {
    testWidgets('password sign in navigates home', (tester) async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false);
      final router = GoRouter(routes: [
        GoRoute(
            path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(
            path: '/connect',
            builder: (_, _) =>
                const Scaffold(body: Text('CONNECT'))),
        GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME'))),
      ], initialLocation: '/login');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider.overrideWith(() => FakeSessionNotifier(
            null, fakeClient: result.harness.client)),
        pendingServerProvider
            .overrideWith((ref) => 'http://demo.local'),
      ]));
      await tester.enterText(
          find.byType(TextField).at(0), 'cal');
      await tester.enterText(
          find.byType(TextField).at(1), 'pw');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('bad credentials show an error', (tester) async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false);
      result.harness.client.authResult = null;
      final router = GoRouter(routes: [
        GoRoute(
            path: '/login', builder: (_, _) => const LoginPage()),
      ], initialLocation: '/login');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider.overrideWith(() => FakeSessionNotifier(
            null, fakeClient: result.harness.client)),
        pendingServerProvider
            .overrideWith((ref) => 'http://demo.local'),
      ]));
      await tester.enterText(
          find.byType(TextField).at(0), 'cal');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Invalid username or password.'),
          findsOneWidget);
    });

    testWidgets('quick connect pane shows code when enabled',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false);
      result.harness.client.quickConnectAvailable = true;
      final router = GoRouter(routes: [
        GoRoute(
            path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(
            path: '/connect',
            builder: (_, _) =>
                const Scaffold(body: Text('CONNECT'))),
      ], initialLocation: '/login');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider.overrideWith(() => FakeSessionNotifier(
            null, fakeClient: result.harness.client)),
        pendingServerProvider
            .overrideWith((ref) => 'http://demo.local'),
      ]));
      await tester.tap(find.text('Quick Connect'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.textContaining('AB12'), findsWidgets);
      // poll timer is still running; leave the page to cancel it
      router.go('/connect');
      await tester.pump();
      await tester.pump();
    });
  });

  group('ProfilesPage', () {
    Future<void> pumpProfiles(WidgetTester tester,
        {String? extra}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false, prefs: {
        'session.profiles':
            '[{"id":"http://srv|u1","serverUrl":"http://srv","serverName":"Home","userId":"u1","userName":"Cal"}]'
      });
      final router = GoRouter(routes: [
        GoRoute(
            path: '/profiles',
            builder: (_, _) => const ProfilesPage()),
        GoRoute(
            path: '/connect',
            builder: (_, _) =>
                const Scaffold(body: Text('CONNECT'))),
        GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME'))),
      ], initialLocation: '/profiles');
      await tester.pumpWidget(routedTestApp(
          router: router,
          overrides: [
            ...result.overrides,
            sessionProvider.overrideWith(() => FakeSessionNotifier(
                null, fakeClient: result.harness.client)),
          ]));
      await tester.pumpAndSettle();
    }

    testWidgets('tapping a profile signs in', (tester) async {
      await pumpProfiles(tester);
      await const FlutterSecureStorage().write(
          key: 'token.http://srv|u1', value: 'tok');
      await tester.tap(find.text('Cal'));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('add account navigates to connect', (tester) async {
      await pumpProfiles(tester);
      await tester.tap(find.text('Add account').last);
      await tester.pumpAndSettle();
      expect(find.text('CONNECT'), findsOneWidget);
    });
  });

  group('LibraryPage menus', () {
    testWidgets('sort and filter menus apply', (tester) async {
      await pump(
          tester,
          const LibraryPage(
              libraryId: 'lib', libraryName: 'Movies'),
          seed: (c) {
            c.children['lib'] = [
              makeItem(id: 'a', name: 'A'),
              makeItem(id: 'b', name: 'B'),
            ];
          });
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(CheckedPopupMenuItem<LibraryQuery>), matching: find.text('Name')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.sort), findsOneWidget);
      await tester.tap(find.text('Unwatched'));
      await tester.pumpAndSettle();
    });
  });

  group('HomePage', () {
    testWidgets('hero and rows render, refresh works',
        (tester) async {
      await pump(tester, const HomePage(), seed: (c) {
        c.resume = [makeItem(id: 'r1', name: 'Mid Film')];
        c.latest['x'] = [];
      });
      expect(find.text('Continue watching'), findsOneWidget);
      final scroll = find.byType(RefreshIndicator);
      expect(scroll, findsOneWidget);
      await tester.fling(
          find.byType(ListView).first, const Offset(0, 300), 1000);
      await tester.pumpAndSettle();
    });
  });

  group('PlayerPage', () {
    testWidgets('controls toggle playback', (tester) async {
      final result = await TestHarness.create();
      final c = ProviderContainer(overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]);
      addTearDown(c.dispose);
      await c.read(playerProvider.notifier).playItem(
          makeItem(id: 'a', type: 'Audio', name: 'Track A'));
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: testApp(
            overrides: const [], child: const PlayerPage()),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();
      expect(result.harness.backend.isPlaying, isFalse);
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();
      expect(result.harness.backend.isPlaying, isTrue);
      await c.read(playerProvider.notifier).stop();
    });
  });

  group('SettingsPage', () {
    testWidgets('check for updates shows a result', (tester) async {
      await pump(tester, const SettingsPage());
      await tester.fling(find.byType(ListView).first,
          const Offset(0, -400), 1000);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
    });
  });
}
