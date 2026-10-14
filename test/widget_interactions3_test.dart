import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finar/core/models/models.dart';
import 'package:finar/pages/detail/detail_page.dart';
import 'package:finar/pages/login/login_page.dart';
import 'package:finar/pages/settings/settings_page.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:finar/widgets/app_shell.dart';

import 'helpers/fake_client.dart';
import 'helpers/path_provider_mock.dart';
import 'helpers/secure_storage_mock.dart';
import 'helpers/test_app.dart';

Future<TestHarness> pumpPage(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(1280, 900),
  List<Override> extra = const [],
  void Function(FakeJellyfinClient client)? seed,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  mockSecureStorage();
  mockPathProvider();
  mockPackageInfo();
  final result = await TestHarness.create();
  seed?.call(result.harness.client);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => Scaffold(body: page))
    ],
    errorBuilder: (_, s) => Scaffold(body: Text('NAV ${s.uri}')),
  );
  await tester.pumpWidget(routedTestApp(
    router: router,
    overrides: [
      ...result.overrides,
      sessionProvider
          .overrideWith(() => FakeSessionNotifier(testSession())),
      ...extra,
    ],
  ));
  await tester.pumpAndSettle();
  return result.harness;
}

void mockShare() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/share'),
          (call) async => 'share');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DetailPage', () {
    testWidgets('error state retries the fetch', (tester) async {
      final harness = await pumpPage(
          tester, const DetailPage(itemId: 'missing'),
          seed: (c) => c.failGetItem = true);
      expect(find.text('Retry'), findsOneWidget);
      harness.client.failGetItem = false;
      harness.client.items['missing'] =
          makeItem(id: 'missing', name: 'Now Found');
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Now Found'), findsOneWidget);
    });

    testWidgets('play button starts playback and navigates',
        (tester) async {
      await pumpPage(
          tester, const DetailPage(itemId: 'm1'), seed: (c) {
        c.items['m1'] = makeItem(id: 'm1', name: 'Film');
      });
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      expect(find.text('NAV /play'), findsOneWidget);
    });

    testWidgets('series play picks next up', (tester) async {
      await pumpPage(
          tester, const DetailPage(itemId: 's1'), seed: (c) {
        c.items['s1'] =
            makeItem(id: 's1', name: 'Show', type: 'Series');
        c.nextUp = [makeItem(id: 'e5', name: 'Next Ep', type: 'Episode')];
      });
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      expect(find.text('NAV /play'), findsOneWidget);
    });

    testWidgets('album shows tracks and plays them',
        (tester) async {
      await pumpPage(
          tester, const DetailPage(itemId: 'a1'), seed: (c) {
        c.items['a1'] =
            makeItem(id: 'a1', name: 'Album', type: 'MusicAlbum');
        c.children['a1'] = [
          makeItem(
              id: 't1',
              name: 'First Track',
              type: 'Audio',
              indexNumber: 1),
          makeItem(
              id: 't2',
              name: 'Second Track',
              type: 'Audio',
              indexNumber: 2),
        ];
      });
      expect(find.text('First Track'), findsOneWidget);
      await tester.tap(find.text('Second Track'));
      await tester.pumpAndSettle();
    });

    testWidgets('artist page lists albums', (tester) async {
      await pumpPage(tester, const DetailPage(itemId: 'ar1'),
          seed: (c) {
        c.items['ar1'] = makeItem(
            id: 'ar1', name: 'Artist', type: 'MusicArtist');
        c.artistAlbums = [
          makeItem(id: 'alb1', name: 'Studio Album', type: 'MusicAlbum')
        ];
      });
      expect(find.text('Studio Album'), findsOneWidget);
    });

    testWidgets('cast renders person rows', (tester) async {
      await pumpPage(tester, const DetailPage(itemId: 'm1'),
          seed: (c) {
        c.items['m1'] = makeItem(id: 'm1', name: 'Film', people: [
          const Person(id: 'p1', name: 'Actor One', role: 'Hero'),
          const Person(id: 'p2', name: 'Actor Two'),
        ]);
      });
      expect(find.text('Actor One'), findsOneWidget);
      expect(find.text('Hero'), findsOneWidget);
    });

    testWidgets('episode badge and genre chips render',
        (tester) async {
      await pumpPage(tester, const DetailPage(itemId: 'e1'),
          seed: (c) {
        c.items['e1'] = makeItem(
            id: 'e1',
            name: 'Ep',
            type: 'Episode',
            seriesName: 'The Show',
            seriesId: 's1',
            parentIndexNumber: 2,
            indexNumber: 4,
            genres: ['Drama']);
      });
      expect(find.text('S2 E4'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
    });

    testWidgets('share button sends a link', (tester) async {
      mockShare();
      await pumpPage(tester, const DetailPage(itemId: 'm1'),
          seed: (c) {
        c.items['m1'] = makeItem(id: 'm1', name: 'Film');
      });
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
    });

    testWidgets('episode tile navigates to its detail',
        (tester) async {
      final result = await TestHarness.create();
      mockSecureStorage();
      mockPathProvider();
      result.harness.client.items['s1'] =
          makeItem(id: 's1', name: 'Show', type: 'Series');
      result.harness.client.seasons['s1'] = [
        makeItem(id: 'sea1', name: 'Season 1', type: 'Season')
      ];
      result.harness.client.episodes['s1|sea1'] = [
        makeItem(
            id: 'e1', name: 'Ep One', type: 'Episode', indexNumber: 1)
      ];
      result.harness.client.items['e1'] =
          makeItem(id: 'e1', name: 'Ep One', type: 'Episode');
      final router = GoRouter(routes: [
        GoRoute(
            path: '/item/:id',
            builder: (_, s) => Scaffold(
                body: DetailPage(itemId: s.pathParameters['id']!))),
      ], initialLocation: '/item/s1');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]));
      await tester.pumpAndSettle();
      for (var i = 0;
          i < 10 && find.textContaining('Ep One').evaluate().isEmpty;
          i++) {
        await tester.drag(
            find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      tester
          .widget<InkWell>(find.ancestor(
              of: find.textContaining('Ep One'),
              matching: find.byType(InkWell)))
          .onTap!();
      await tester.pumpAndSettle();
      expect(
          router.routerDelegate.currentConfiguration.matches.last
              .matchedLocation,
          '/item/e1');
    });
  });

  group('LoginPage', () {
    Future<GoRouter> pumpLogin(
        WidgetTester tester, FakeJellyfinClient client,
        {String? server = 'http://demo.local'}) async {
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false);
      final router = GoRouter(routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(
            path: '/connect',
            builder: (_, _) => const Scaffold(body: Text('CONNECT'))),
        GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME'))),
      ], initialLocation: '/login');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider.overrideWith(() => FakeSessionNotifier(
            null, fakeClient: client)),
        pendingServerProvider.overrideWith((ref) => server),
      ]));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('no pending server bounces to connect',
        (tester) async {
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false);
      final router = GoRouter(routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(
            path: '/connect',
            builder: (_, _) => const Scaffold(body: Text('CONNECT'))),
      ], initialLocation: '/login');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(null)),
      ]));
      await tester.enterText(find.byType(TextField).at(0), 'cal');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('CONNECT'), findsOneWidget);
    });

    testWidgets('empty username shows an error', (tester) async {
      await pumpLogin(tester, FakeJellyfinClient());
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your username.'), findsOneWidget);
    });

    testWidgets('generic failure shows generic error',
        (tester) async {
      final client = FakeJellyfinClient();
      client.authShouldThrow = true;
      await pumpLogin(tester, client);
      await tester.enterText(find.byType(TextField).at(0), 'cal');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.textContaining('failed'), findsWidgets);
    });

    testWidgets('back button returns to connect', (tester) async {
      await pumpLogin(tester, FakeJellyfinClient());
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('CONNECT'), findsOneWidget);
    });

    testWidgets('quick connect unavailable shows error',
        (tester) async {
      final client = FakeJellyfinClient();
      client.quickConnectAvailable = false;
      await pumpLogin(tester, client);
      await tester.tap(find.text('Quick Connect'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(
          find.textContaining('Quick Connect'), findsWidgets);
    });

    testWidgets('quick connect success signs in', (tester) async {
      final client = FakeJellyfinClient();
      client.quickConnectAvailable = true;
      await pumpLogin(tester, client);
      await tester.tap(find.text('Quick Connect'));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
      expect(find.text('HOME'), findsOneWidget);
    });
  });

  group('AppShell', () {
    Future<(GoRouter, ProviderContainer)> pumpShell(
        WidgetTester tester, Size size,
        {bool withPlayer = false}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      mockSecureStorage();
      mockPathProvider();
      final result = await TestHarness.create();
      result.harness.client.libraries = [
        makeItem(
            id: 'l1',
            name: 'Movies',
            type: 'CollectionFolder',
            collectionType: 'movies',
            isFolder: true)
      ];
      final router = GoRouter(routes: [
        GoRoute(
            path: '/home',
            builder: (_, _) => const AppShell(child: Text('PAGE'))),
        GoRoute(
            path: '/settings',
            builder: (_, _) =>
                const AppShell(child: Text('SETTINGS'))),
        GoRoute(
            path: '/library/:id',
            builder: (_, s) =>
                AppShell(child: Text('LIB ${s.pathParameters['id']}'))),
        GoRoute(
            path: '/profiles',
            builder: (_, _) =>
                const Scaffold(body: Text('PROFILES'))),
        GoRoute(
            path: '/play',
            builder: (_, _) =>
                const Scaffold(body: Text('PLAY'))),
      ], initialLocation: '/home');
      final c = ProviderContainer(overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]);
      addTearDown(c.dispose);
      if (withPlayer) {
        await c.read(playerProvider.notifier).playQueue([
          makeItem(id: 'a', type: 'Audio', name: 'One'),
          makeItem(id: 'b', type: 'Audio', name: 'Two'),
        ], 0);
      }
      await tester.pumpWidget(
          routedTestApp(router: router, container: c));
      await tester.pumpAndSettle();
      return (router, c);
    }

    testWidgets('desktop sidebar navigates and shows libraries',
        (tester) async {
      await pumpShell(tester, const Size(1280, 900));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('library row navigates to library page',
        (tester) async {
      await pumpShell(tester, const Size(1280, 900));
      await tester.tap(find.text('Movies'));
      await tester.pumpAndSettle();
      expect(find.text('LIB l1'), findsOneWidget);
    });

    testWidgets('profile footer goes to profiles', (tester) async {
      await pumpShell(tester, const Size(1280, 900));
      await tester.tap(find.text('Calico'));
      await tester.pumpAndSettle();
      expect(find.text('PROFILES'), findsOneWidget);
    });

    testWidgets('mobile drawer works', (tester) async {
      await pumpShell(tester, const Size(390, 844));
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('mini player shows when audio plays',
        (tester) async {
      final (router, c) =
          await pumpShell(tester, const Size(1280, 900),
              withPlayer: true);
      await tester.pumpAndSettle();
      expect(find.text('One'), findsWidgets);
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsWidgets);
      await tester.tap(find.byType(MiniPlayerBar));
      await tester.pumpAndSettle();
      expect(find.text('PLAY'), findsOneWidget);
      await c.read(playerProvider.notifier).stop();
    });
  });

  group('SettingsPage extras', () {
    testWidgets('switch profile navigates', (tester) async {
      await pumpPage(tester, const SettingsPage());
      await tester.fling(find.byType(ListView).first,
          const Offset(0, -600), 1000);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch profile'));
      await tester.pumpAndSettle();
      expect(find.text('NAV /profiles'), findsOneWidget);
    });

    testWidgets('about links present', (tester) async {
      await pumpPage(tester, const SettingsPage());
      await tester.fling(find.byType(ListView).first,
          const Offset(0, -800), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Source code'), findsOneWidget);
      await tester.tap(find.text('Licences'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}
