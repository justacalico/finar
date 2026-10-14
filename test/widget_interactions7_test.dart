import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finar/core/storage/downloads_store.dart';
import 'package:finar/pages/detail/detail_page.dart';
import 'package:finar/pages/downloads/downloads_page.dart';
import 'package:finar/pages/home/home_page.dart';
import 'package:finar/pages/library/library_page.dart';
import 'package:finar/pages/login/login_page.dart';
import 'package:finar/pages/player/player_page.dart';
import 'package:finar/providers/downloads_provider.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:finar/widgets/app_shell.dart';

import 'helpers/fake_client.dart';
import 'helpers/path_provider_mock.dart';
import 'helpers/secure_storage_mock.dart';
import 'helpers/test_app.dart';

const _size = Size(1280, 900);

Future<TestHarness> pumpPage(
  WidgetTester tester,
  Widget page, {
  Size size = _size,
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

  testWidgets('album play queues the album', (tester) async {
    await pumpPage(tester, const DetailPage(itemId: 'a1'), seed: (c) {
      c.items['a1'] =
          makeItem(id: 'a1', name: 'Album', type: 'MusicAlbum');
      c.children['a1'] = [
        makeItem(id: 't1', name: 'Track', type: 'Audio')
      ];
    });
    (tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Play').last)
            .onPressed!());
    await tester.pumpAndSettle();
    expect(find.text('NAV /play'), findsOneWidget);
  });

  testWidgets('queue sheet tile with artist subtitle',
      (tester) async {
    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockSecureStorage();
    final result = await TestHarness.create();
    final c = ProviderContainer(overrides: [
      ...result.overrides,
      sessionProvider
          .overrideWith(() => FakeSessionNotifier(testSession())),
    ]);
    addTearDown(() async {
      await c.read(playerProvider.notifier).stop();
      c.dispose();
    });
    await c.read(playerProvider.notifier).playQueue([
      makeItem(id: 'a', type: 'Audio', name: 'One', albumArtist: 'Art'),
      makeItem(id: 'b', type: 'Audio', name: 'Two'),
    ], 0);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: testApp(child: const PlayerPage()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.queue_music));
    await tester.pumpAndSettle();
    tester
        .widget<ListTile>(find.widgetWithText(ListTile, 'Two'))
        .onTap!();
    await tester.pumpAndSettle();
    expect(c.read(playerProvider).queueIndex, 1);
    await c.read(playerProvider.notifier).stop();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('library card uses album artist subtitle',
      (tester) async {
    await pumpPage(
        tester,
        const LibraryPage(libraryId: 'lib', libraryName: 'Music'),
        seed: (c) {
          c.items['lib'] = makeItem(
              id: 'lib',
              name: 'Music',
              type: 'CollectionFolder',
              collectionType: 'music',
              isFolder: true);
          c.children['lib'] = [
            makeItem(
                id: 'x1',
                name: 'Track',
                type: 'Audio',
                albumArtist: 'The Band',
                year: null)
          ];
        });
    expect(find.text('The Band'), findsOneWidget);
  });

  testWidgets('downloads: tile tap navigates, imageId renders',
      (tester) async {
    mockSecureStorage();
    mockPathProvider();
    final result = await TestHarness.create();
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: DownloadsPage())),
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
                  imageId: 'img1',
                  status: DownloadStatus.completed),
            ])),
      ],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Film'));
    await tester.pumpAndSettle();
    expect(find.text('ITEM d1'), findsOneWidget);
  });

  testWidgets('quick connect initiate failure shows error',
      (tester) async {
    mockSecureStorage();
    final result = await TestHarness.create(signedIn: false);
    final client = result.harness.client;
    client.qcInitiateThrows = true;
    final router = GoRouter(routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
    ], initialLocation: '/login');
    await tester.pumpWidget(routedTestApp(router: router, overrides: [
      ...result.overrides,
      sessionProvider.overrideWith(
          () => FakeSessionNotifier(null, fakeClient: client)),
      pendingServerProvider.overrideWith((ref) => 'http://demo.local'),
    ]));
    await tester.tap(find.text('Quick Connect'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.textContaining('not enabled'), findsWidgets);
  });

  testWidgets('shell sidebar shows all library icons',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockSecureStorage();
    final result = await TestHarness.create();
    result.harness.client.libraries = [
      makeItem(id: 'a', name: 'Movies', type: 'CollectionFolder', collectionType: 'movies', isFolder: true),
      makeItem(id: 'b', name: 'TV', type: 'CollectionFolder', collectionType: 'tvshows', isFolder: true),
      makeItem(id: 'c', name: 'Music', type: 'CollectionFolder', collectionType: 'music', isFolder: true),
      makeItem(id: 'd', name: 'Pics', type: 'CollectionFolder', collectionType: 'photos', isFolder: true),
      makeItem(id: 'e', name: 'Books', type: 'CollectionFolder', collectionType: 'books', isFolder: true),
      makeItem(id: 'f', name: 'Live', type: 'CollectionFolder', collectionType: 'livetv', isFolder: true),
      makeItem(id: 'g', name: 'Misc', type: 'CollectionFolder', isFolder: true),
    ];
    final router = GoRouter(routes: [
      GoRoute(
          path: '/home',
          builder: (_, _) => const AppShell(child: Text('PAGE'))),
      GoRoute(
          path: '/library/:id',
          builder: (_, s) => AppShell(
              child: Text('LIB ${s.pathParameters['id']}'))),
    ], initialLocation: '/home');
    await tester.pumpWidget(routedTestApp(router: router, overrides: [
      ...result.overrides,
      sessionProvider
          .overrideWith(() => FakeSessionNotifier(testSession())),
    ]));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.live_tv_outlined), findsWidgets);
    await tester.tap(find.text('Misc'));
    await tester.pumpAndSettle();
    expect(find.text('LIB g'), findsWidgets);
  });

  testWidgets('media card shows played badge and progress',
      (tester) async {
    await pumpPage(tester, const HomePage(), seed: (c) {
      c.resume = [
        makeItem(
            id: 'r1',
            name: 'Watched',
            played: true,
            positionTicks: 3000000000)
      ];
      c.items['r1'] = makeItem(id: 'r1', name: 'Watched');
    });
    expect(find.byIcon(Icons.check_circle), findsWidgets);
  });
}

class _Dl extends DownloadsNotifier {
  _Dl(this.records);
  final List<DownloadRecord> records;
  @override
  List<DownloadRecord> build() => records;
}
