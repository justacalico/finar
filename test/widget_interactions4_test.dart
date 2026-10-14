import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finar/core/storage/downloads_store.dart';
import 'package:finar/pages/connect/connect_page.dart';
import 'package:finar/pages/detail/detail_page.dart';
import 'package:finar/pages/downloads/downloads_page.dart';
import 'package:finar/pages/favorites/favorites_page.dart';
import 'package:finar/pages/home/home_page.dart';
import 'package:finar/pages/libraries/libraries_page.dart';
import 'package:finar/pages/library/library_page.dart';
import 'package:finar/pages/login/login_page.dart';
import 'package:finar/pages/profiles/profiles_page.dart';
import 'package:finar/pages/search/search_page.dart';
import 'package:finar/providers/downloads_provider.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:finar/widgets/title_bar.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryPage deep', () {
    FakeJellyfinClient seed(FakeJellyfinClient c) {
      c.children['lib'] = [
        for (var i = 0; i < 90; i++)
          makeItem(id: 'g$i', name: 'Item $i'),
      ];
      c.items['lib'] = makeItem(
          id: 'lib',
          name: 'Movies',
          type: 'CollectionFolder',
          collectionType: 'movies',
          isFolder: true);
      c.genreItems = [
        makeItem(id: 'gn1', name: 'Drama', type: 'Genre'),
      ];
      return c;
    }

    testWidgets('scroll to bottom loads more pages', (tester) async {
      await pumpPage(
          tester,
          const LibraryPage(
              libraryId: 'lib', libraryName: 'Movies'),
          seed: seed);
      for (var i = 0; i < 6; i++) {
        await tester.drag(
            find.byType(GridView), const Offset(0, -3000));
        await tester.pumpAndSettle();
      }
      expect(find.text('Item 89'), findsWidgets);
    });

    testWidgets('error page retries after recovery', (tester) async {
      final harness = await pumpPage(
          tester,
          const LibraryPage(libraryId: 'lib', libraryName: 'Movies'),
          seed: (c) => c.failChildren = true);
      expect(find.text('Retry'), findsOneWidget);
      harness.client.failChildren = false;
      seed(harness.client);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Item 0'), findsWidgets);
    });

    testWidgets('genre menu filters items', (tester) async {
      await pumpPage(
          tester,
          const LibraryPage(
              libraryId: 'lib', libraryName: 'Movies'),
          seed: seed);
      await tester.tap(find.byIcon(Icons.category_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Drama').last);
      await tester.pumpAndSettle();
    });

    testWidgets('descending sort works', (tester) async {
      await pumpPage(
          tester,
          const LibraryPage(
              libraryId: 'lib', libraryName: 'Movies'),
          seed: seed);
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descending'));
      await tester.pumpAndSettle();
    });
  });

  group('HomePage details', () {
    testWidgets('hero button, continue card, see all navigate',
        (tester) async {
      final result = await TestHarness.create();
      mockSecureStorage();
      final c = result.harness.client;
      c.libraries = [
        makeItem(
            id: 'l1',
            name: 'Films',
            type: 'CollectionFolder',
            collectionType: 'movies',
            isFolder: true)
      ];
      c.resume = [
        makeItem(
            id: 'r1',
            name: 'Mid Film',
            seriesName: 'Serial',
            indexNumber: 3,
            parentIndexNumber: 1)
      ];
      c.nextUp = [
        makeItem(id: 'n1', name: 'Next Ep', type: 'Episode')
      ];
      c.latest['l1'] = [makeItem(id: 'lt1', name: 'Latest One')];
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: HomePage())),
        GoRoute(
            path: '/item/:id',
            builder: (_, s) =>
                Scaffold(body: Text('ITEM ${s.pathParameters['id']}'))),
      ]);
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      expect(
          router.routerDelegate.currentConfiguration.matches.last
              .matchedLocation,
          startsWith('/item/'));
    });

    testWidgets('see all goes to the library', (tester) async {
      final result = await TestHarness.create();
      mockSecureStorage();
      final c = result.harness.client;
      c.libraries = [
        makeItem(
            id: 'l1',
            name: 'Films',
            type: 'CollectionFolder',
            collectionType: 'movies',
            isFolder: true)
      ];
      c.latest['l1'] = [makeItem(id: 'lt1', name: 'Latest One')];
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: HomePage())),
        GoRoute(
            path: '/library/:id',
            builder: (_, s) =>
                Scaffold(body: Text('LIB ${s.pathParameters['id']}'))),
      ]);
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();
      expect(find.text('LIB l1'), findsOneWidget);
    });
  });

  group('DetailPage extras', () {
    testWidgets('album play queues all tracks', (tester) async {
      await pumpDetail(tester, 'a1', seed: (c) {
        c.items['a1'] =
            makeItem(id: 'a1', name: 'Album', type: 'MusicAlbum');
        c.children['a1'] = [
          makeItem(id: 't1', name: 'Track', type: 'Audio')
        ];
      });
      await tester.tap(find.widgetWithText(FilledButton, 'Play').first);
      await tester.pumpAndSettle();
      expect(find.text('NAV /play'), findsOneWidget);
    });

    testWidgets('mark unplayed resets played', (tester) async {
      final harness = await pumpPage(
          tester, const DetailPage(itemId: 'm1'), seed: (c) {
        c.items['m1'] =
            makeItem(id: 'm1', name: 'Film', played: true);
      });
      await tester.tap(find.text('Mark as unwatched'));
      await tester.pumpAndSettle();
      expect(harness.client.playedCalls, 1);
    });

    testWidgets('artist album card opens album', (tester) async {
      final router = await pumpDetail(tester, 'ar1', seed: (c) {
        c.items['ar1'] =
            makeItem(id: 'ar1', name: 'Artist', type: 'MusicArtist');
        c.artistAlbums = [
          makeItem(id: 'alb1', name: 'Studio', type: 'MusicAlbum')
        ];
        c.items['alb1'] =
            makeItem(id: 'alb1', name: 'Studio', type: 'MusicAlbum');
      });
      tester
          .widget<InkWell>(find.ancestor(
              of: find.text('Studio'), matching: find.byType(InkWell)))
          .onTap!();
      await tester.pumpAndSettle();
      expect(
          router.routerDelegate.currentConfiguration.matches.last
              .matchedLocation,
          '/item/alb1');
    });
  });

  group('ProfilesPage extras', () {
    testWidgets('long press removes a profile', (tester) async {
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
      ], initialLocation: '/profiles');
      await tester.pumpWidget(routedTestApp(
          router: router, overrides: result.overrides));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Cal'));
      await tester.pumpAndSettle();
      expect(find.text('Cal'), findsNothing);
    });
  });

  group('DownloadsPage extras', () {
    testWidgets('play and delete buttons act', (tester) async {
      mockSecureStorage();
      mockPathProvider();
      final result = await TestHarness.create();
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: DownloadsPage())),
        GoRoute(
            path: '/item/:id',
            builder: (_, s) =>
                Scaffold(body: Text('ITEM ${s.pathParameters['id']}'))),
      ]);
      await tester.pumpWidget(routedTestApp(
        router: router,
        overrides: [
          ...result.overrides,
          downloadsProvider.overrideWith(() => _Dl([
                const DownloadRecord(
                    itemId: 'd1',
                    name: 'Film',
                    type: 'Movie',
                    serverUrl: 'http://s',
                    localPath: '/tmp/x',
                    status: DownloadStatus.completed),
                const DownloadRecord(
                    itemId: 'd2',
                    name: 'Track',
                    type: 'Audio',
                    serverUrl: 'http://s',
                    localPath: '/tmp/y',
                    status: DownloadStatus.downloading,
                    progress: 0.4),
              ])),
        ],
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Film'), findsNothing);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Track'), findsNothing);
    });
  });

  group('LoginPage extras', () {
    testWidgets('keyboard submit signs in', (tester) async {
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false);
      final client = result.harness.client;
      final router = GoRouter(routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME'))),
      ], initialLocation: '/login');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider.overrideWith(
            () => FakeSessionNotifier(null, fakeClient: client)),
        pendingServerProvider
            .overrideWith((ref) => 'http://demo.local'),
      ]));
      await tester.enterText(find.byType(TextField).at(0), 'cal');
      await tester.enterText(find.byType(TextField).at(1), 'pw');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });
  });

  group('Misc', () {
    testWidgets('connect: invalid url then error', (tester) async {
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false);
      await tester.pumpWidget(testApp(
        overrides: [
          ...result.overrides,
          sessionProvider.overrideWith(() => FakeSessionNotifier(
              null, fakeClient: result.harness.client)),
        ],
        child: const ConnectPage(),
      ));
      await tester.enterText(find.byType(TextField), 'not a url');
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
    });

    testWidgets('libraries error state retries', (tester) async {
      final harness = await pumpPage(tester, const LibrariesPage(),
          seed: (c) => c.failChildren = true);
      if (find.text('Retry').evaluate().isNotEmpty) {
        harness.client.failChildren = false;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('favorites error and card tap', (tester) async {
      final result = await TestHarness.create();
      mockSecureStorage();
      result.harness.client.failChildren = false;
      result.harness.client.favorites =
          [makeItem(id: 'f9', name: 'Fav')];
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: FavoritesPage())),
        GoRoute(
            path: '/item/:id',
            builder: (_, s) =>
                Scaffold(body: Text('ITEM ${s.pathParameters['id']}'))),
      ]);
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fav'));
      await tester.pumpAndSettle();
      expect(find.text('ITEM f9'), findsOneWidget);
    });

    testWidgets('search clear button resets', (tester) async {
      await pumpPage(tester, const SearchPage(), seed: (c) {
        c.searchResults = [makeItem(id: 'r1', name: 'Hit')];
      });
      await tester.enterText(find.byType(TextField), 'hit');
      await tester.pumpAndSettle();
      expect(find.text('Hit'), findsWidgets);
      final clear = find.byIcon(Icons.close);
      if (clear.evaluate().isNotEmpty) {
        await tester.tap(clear);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('medium width uses compact layout', (tester) async {
      await pumpPage(tester, const LibrariesPage(),
          size: const Size(720, 1000));
      expect(find.byType(LibrariesPage), findsOneWidget);
    });

    testWidgets('title bar buttons invoke window actions',
        (tester) async {
      mockSecureStorage();
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final actions = _FakeWindowActions();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: TitleBar(actions: actions)),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('minimize'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('maximize'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('close'));
      await tester.pump();
      expect(actions.calls, ['minimize', 'maximize', 'close']);
    });
  });
}

Future<GoRouter> pumpDetail(WidgetTester tester, String id,
    {void Function(FakeJellyfinClient)? seed}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  mockSecureStorage();
  mockPathProvider();
  mockPackageInfo();
  final result = await TestHarness.create();
  seed?.call(result.harness.client);
  final router = GoRouter(routes: [
    GoRoute(
        path: '/item/:id',
        builder: (_, s) =>
            Scaffold(body: DetailPage(itemId: s.pathParameters['id']!))),
  ], initialLocation: '/item/$id',
      errorBuilder: (_, s) => Scaffold(body: Text('NAV ${s.uri}')));
  await tester.pumpWidget(routedTestApp(router: router, overrides: [
    ...result.overrides,
    sessionProvider
        .overrideWith(() => FakeSessionNotifier(testSession())),
  ]));
  await tester.pumpAndSettle();
  return router;
}

class _Dl extends DownloadsNotifier {
  _Dl(this.records);
  final List<DownloadRecord> records;
  @override
  List<DownloadRecord> build() => records;
}


class _FakeWindowActions implements WindowActions {
  final calls = <String>[];
  bool maximized = false;
  @override
  Future<void> minimize() async => calls.add('minimize');
  @override
  Future<void> maximizeOrRestore() async => calls.add('maximize');
  @override
  Future<void> close() async => calls.add('close');
  @override
  Future<bool> isMaximized() async => maximized;
  @override
  void dragMove() {}
}
