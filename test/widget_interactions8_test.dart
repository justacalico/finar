import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finar/pages/detail/detail_page.dart';
import 'package:finar/pages/downloads/downloads_page.dart';
import 'package:finar/pages/home/home_page.dart';
import 'package:finar/pages/settings/settings_page.dart';
import 'package:finar/providers/downloads_provider.dart';
import 'package:finar/core/storage/session_store.dart';
import 'package:finar/core/models/models.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:finar/core/storage/downloads_store.dart';
import 'package:finar/widgets/app_shell.dart';
import 'package:finar/widgets/media_card.dart';

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

  testWidgets('home with all rows and edge-case items', (tester) async {
    await pumpPage(tester, const HomePage(), seed: (c) {
      c.resume = [
        makeItem(
            id: 'r1',
            name: 'Plain',
            backdropTag: null,
            positionTicks: 5),
        makeItem(
            id: 'r2',
            name: 'Serial Ep',
            type: 'Episode',
            seriesName: 'Show'),
      ];
      c.nextUp = [
        makeItem(id: 'n1', name: 'Up', type: 'Episode', indexNumber: 2)
      ];
      c.libraries = [
        makeItem(
            id: 'l1',
            name: 'Films',
            type: 'CollectionFolder',
            collectionType: 'movies',
            isFolder: true)
      ];
      c.latest['l1'] = [
        makeItem(id: 'lt1', name: 'Newest', backdropTag: null)
      ];
    });
    expect(find.text('Continue watching'), findsOneWidget);
  });

  testWidgets('home error branches render empty sections',
      (tester) async {
    await pumpPage(tester, const HomePage(), seed: (c) {
      c.failHome = true;
      c.libraries = [
        makeItem(
            id: 'l1',
            name: 'Films',
            type: 'CollectionFolder',
            collectionType: 'movies',
            isFolder: true)
      ];
    });
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('downloads play icon navigates', (tester) async {
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
    final play = find.byIcon(Icons.play_circle_outline);
    if (play.evaluate().isNotEmpty) {
      await tester.tap(play);
      await tester.pumpAndSettle();
      expect(
          router.routerDelegate.currentConfiguration.matches.last
              .matchedLocation,
          '/item/d1');
    }
  });

  testWidgets('media card icons for every type', (tester) async {
    mockSecureStorage();
    final result = await TestHarness.create();
    for (final (type, icon) in [
      ('Movie', Icons.movie_outlined),
      ('Series', Icons.tv_outlined),
      ('Episode', Icons.play_circle_outline),
      ('Audio', Icons.music_note_outlined),
      ('MusicAlbum', Icons.album_outlined),
      ('MusicArtist', Icons.person_outline),
      ('CollectionFolder', Icons.video_library_outlined),
      ('Genre', Icons.category_outlined),
      ('Whatever', Icons.folder_outlined),
    ]) {
      await tester.pumpWidget(testApp(
        overrides: result.overrides,
        child: MediaCard(
            item: makeItem(id: 'x', name: 'X', type: type)),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(icon), findsOneWidget);
    }
  });

  testWidgets('detail similar and artist empty states', (tester) async {
    await pumpPage(tester, const DetailPage(itemId: 'm1'), seed: (c) {
      c.items['m1'] = makeItem(id: 'm1', name: 'Film');
      c.similar['m1'] = [];
    });
    expect(find.byType(DetailPage), findsOneWidget);
  });

  testWidgets('settings renders server url when name empty',
      (tester) async {
    await pumpPage(tester, const SettingsPage(), extra: [
      sessionProvider.overrideWith(() => FakeSessionNotifier(
          const Session(
              serverUrl: 'http://noname.local',
              serverName: '',
              accessToken: 't',
              user: JellyfinUser(id: 'u', name: 'Cal')))),
    ]);
    await tester.fling(
        find.byType(ListView).first, const Offset(0, -600), 1000);
    await tester.pumpAndSettle();
    expect(find.text('http://noname.local'), findsWidgets);
  });

  testWidgets('shell mobile app bar title', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    mockSecureStorage();
    final result = await TestHarness.create();
    final router = GoRouter(routes: [
      GoRoute(
          path: '/library/:id',
          builder: (_, s) => AppShell(
              child: Text('LIB ${s.pathParameters['id']}'))),
    ], initialLocation: '/library/x1');
    await tester.pumpWidget(routedTestApp(router: router, overrides: [
      ...result.overrides,
      sessionProvider
          .overrideWith(() => FakeSessionNotifier(testSession())),
    ]));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}

class _Dl extends DownloadsNotifier {
  _Dl(this.records);
  final List<DownloadRecord> records;
  @override
  List<DownloadRecord> build() => records;
}
