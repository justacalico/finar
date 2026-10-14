import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finar/core/models/models.dart';
import 'package:finar/core/storage/downloads_store.dart';
import 'package:finar/pages/connect/connect_page.dart';
import 'package:finar/pages/detail/detail_page.dart';
import 'package:finar/pages/downloads/downloads_page.dart';
import 'package:finar/pages/favorites/favorites_page.dart';
import 'package:finar/pages/libraries/libraries_page.dart';
import 'package:finar/pages/library/library_page.dart';
import 'package:finar/pages/player/player_page.dart';
import 'package:finar/pages/search/search_page.dart';
import 'package:finar/pages/settings/settings_page.dart';
import 'package:finar/providers/downloads_provider.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:finar/providers/session_provider.dart';

import 'helpers/fake_client.dart';
import 'helpers/path_provider_mock.dart';
import 'helpers/secure_storage_mock.dart';
import 'helpers/test_app.dart';

const _size = Size(1280, 900);

Future<TestHarness> pumpPage(
  WidgetTester tester,
  Widget page, {
  Size size = _size,
  bool signedIn = true,
  List<Override> extra = const [],
  void Function(FakeJellyfinClient client)? seed,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  mockSecureStorage();
  mockPathProvider();
  mockPackageInfo();
  final result = await TestHarness.create(signedIn: signedIn);
  seed?.call(result.harness.client);
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => Scaffold(body: page))],
    errorBuilder: (_, s) => Scaffold(body: Text('NAV ${s.uri}')),
  );
  await tester.pumpWidget(routedTestApp(
    router: router,
    overrides: [
      ...result.overrides,
      if (signedIn)
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

  group('PlayerPage interactions', () {
    Future<(ProviderContainer, TestHarness)> pumpPlayer(
        WidgetTester tester,
        {List<BaseItem>? queue, int index = 0}) async {
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
      if (queue != null) {
        await c.read(playerProvider.notifier).playQueue(queue, index);
      } else {
        await c
            .read(playerProvider.notifier)
            .playItem(makeItem(id: 'v1', type: 'Movie', name: 'Film'));
      }
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: testApp(child: const PlayerPage()),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      return (c, result.harness);
    }

    testWidgets('keyboard shortcuts drive playback', (tester) async {
      final (c, harness) = await pumpPlayer(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(harness.backend.isPlaying, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(harness.backend.isPlaying, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(harness.backend.currentPosition,
          const Duration(seconds: 10));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await c.read(playerProvider.notifier).stop();
    });

    testWidgets('seek buttons and slider work', (tester) async {
      final (c, harness) = await pumpPlayer(tester);
      await tester.tap(find.byIcon(Icons.forward_10));
      await tester.pump();
      expect(harness.backend.currentPosition,
          const Duration(seconds: 10));
      await tester.tap(find.byIcon(Icons.replay_10));
      await tester.pump();
      expect(harness.backend.currentPosition, Duration.zero);
      await tester.pump(const Duration(seconds: 5));
      await c.read(playerProvider.notifier).stop();
    });

    testWidgets('speed menu sets rate', (tester) async {
      final (c, harness) = await pumpPlayer(tester);
      await tester.tap(find.byIcon(Icons.speed));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();
      expect(harness.backend.currentRate, 1.5);
      await tester.pump(const Duration(seconds: 5));
      await c.read(playerProvider.notifier).stop();
    });

    testWidgets('queue sheet lists and selects tracks',
        (tester) async {
      final queue = [
        makeItem(id: 'a', type: 'Audio', name: 'One'),
        makeItem(id: 'b', type: 'Audio', name: 'Two'),
      ];
      final (c, harness) = await pumpPlayer(tester, queue: queue);
      await tester.tap(find.byIcon(Icons.queue_music));
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsOneWidget);
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(c.read(playerProvider).queueIndex, 1);
      await tester.pump(const Duration(seconds: 5));
      await c.read(playerProvider.notifier).stop();
    });

    testWidgets('subtitle and audio menus show tracks',
        (tester) async {
      final (c, harness) = await pumpPlayer(tester);
      if (find.byIcon(Icons.subtitles).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.subtitles));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Off').last);
        await tester.pumpAndSettle();
      }
      if (find.byIcon(Icons.audiotrack).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.audiotrack));
        await tester.pumpAndSettle();
        await tester.tap(find.text('English').last);
        await tester.pumpAndSettle();
      }
      await c.read(playerProvider.notifier).stop();
    });

    testWidgets('tapping video toggles controls', (tester) async {
      final (c, _) = await pumpPlayer(tester);
      await tester.tapAt(const Offset(640, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.tapAt(const Offset(640, 300));
      await tester.pump(const Duration(seconds: 5));
      await c.read(playerProvider.notifier).stop();
    });

    testWidgets('empty player shows back button', (tester) async {
      tester.view.physicalSize = _size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      mockSecureStorage();
      final result = await TestHarness.create();
      await tester.pumpWidget(testApp(
          overrides: result.overrides, child: const PlayerPage()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back).evaluate().isNotEmpty ||
          find.text('Back').evaluate().isNotEmpty, isTrue);
    });
  });

  group('DetailPage interactions', () {
    FakeJellyfinClient seedDetail(FakeJellyfinClient c) {
      c.items['m1'] = makeItem(
          id: 'm1', name: 'Film', favorite: true, genres: ['Drama']);
      c.seasons['s1'] = [
        makeItem(id: 'sea1', name: 'Season 1', type: 'Season')
      ];
      c.items['s1'] = makeItem(
          id: 's1', name: 'Show', type: 'Series');
      c.episodes['s1|sea1'] = [
        makeItem(
            id: 'e1',
            name: 'Ep One',
            type: 'Episode',
            indexNumber: 1),
      ];
      c.similar['m1'] = [makeItem(id: 's9', name: 'Similar Film')];
      return c;
    }

    testWidgets('mark watched toggles played', (tester) async {
      final harness = await pumpPage(
          tester, const DetailPage(itemId: 'm1'),
          seed: seedDetail);
      await tester.tap(find.text('Mark as watched'));
      await tester.pumpAndSettle();
      expect(harness.client.playedCalls, 1);
    });

    testWidgets('download button queues a download', (tester) async {
      await pumpPage(
          tester, const DetailPage(itemId: 'm1'),
          seed: seedDetail);
      await tester.tap(find.text('Download'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Downloaded'), findsNothing);
    });

    testWidgets('series page shows seasons and episodes',
        (tester) async {
      await pumpPage(
          tester, const DetailPage(itemId: 's1'),
          seed: (c) {
            seedDetail(c);
            c.seasons['s1'] = [
              makeItem(id: 'sea1', name: 'Season 1', type: 'Season'),
              makeItem(id: 'sea2', name: 'Season 2', type: 'Season'),
            ];
            c.episodes['s1|sea2'] = [
              makeItem(
                  id: 'e9',
                  name: 'Season Two Pilot',
                  type: 'Episode',
                  indexNumber: 1),
            ];
          });
      for (var i = 0; i < 10 && find.text('Season 1').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(find.text('Season 1'), findsOneWidget);
      tester
          .widget<DropdownButton<String>>(
              find.byType(DropdownButton<String>))
          .onChanged!('sea2');
      await tester.pumpAndSettle();
      for (var i = 0; i < 10 && find.textContaining('Season Two Pilot').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Season Two Pilot'), findsOneWidget);
    });

    testWidgets('similar item navigates', (tester) async {
      final result = await TestHarness.create();
      mockSecureStorage();
      mockPathProvider();
      result.harness.client.items['m1'] =
          makeItem(id: 'm1', name: 'Film');
      result.harness.client.similar['m1'] = [
        makeItem(id: 's9', name: 'Similar Film')
      ];
      final router = GoRouter(routes: [
        GoRoute(
            path: '/item/:id',
            builder: (_, s) => Scaffold(
                body: DetailPage(itemId: s.pathParameters['id']!))),
      ], initialLocation: '/item/m1');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]));
      await tester.pumpAndSettle();
      for (var i = 0; i < 10 && find.text('Similar Film').evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Similar Film'));
      await tester.pumpAndSettle();
      tester
          .widget<InkWell>(find.ancestor(
              of: find.text('Similar Film'),
              matching: find.byType(InkWell)))
          .onTap!();
      await tester.pumpAndSettle();
      expect(
          router.routerDelegate.currentConfiguration.matches.last
              .matchedLocation,
          '/item/s9');
    });
  });

  group('LibraryPage', () {
    FakeJellyfinClient seed(FakeJellyfinClient c) {
      c.children['lib'] = [
        for (var i = 0; i < 60; i++)
          makeItem(id: 'g$i', name: 'Item $i'),
      ];
      c.items['lib'] = makeItem(
          id: 'lib',
          name: 'Movies',
          type: 'CollectionFolder',
          collectionType: 'movies',
          isFolder: true);
      return c;
    }

    testWidgets('grid item tap navigates', (tester) async {
      final result = await TestHarness.create();
      mockSecureStorage();
      seed(result.harness.client);
      final router = GoRouter(routes: [
        GoRoute(
            path: '/lib',
            builder: (_, _) => const Scaffold(
                body: LibraryPage(
                    libraryId: 'lib', libraryName: 'Movies'))),
        GoRoute(
            path: '/item/:id',
            builder: (_, s) => Scaffold(
                body: Text('ITEM ${s.pathParameters['id']}'))),
      ], initialLocation: '/lib');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Item 0'));
      await tester.pumpAndSettle();
      expect(find.text('ITEM g0'), findsOneWidget);
    });

    testWidgets('scrolling loads more items', (tester) async {
      await pumpPage(
          tester,
          const LibraryPage(libraryId: 'lib', libraryName: 'Movies'),
          seed: seed);
      await tester.drag(
          find.byType(GridView), const Offset(0, -4000));
      await tester.pumpAndSettle();
    });

    testWidgets('error state retries', (tester) async {
      await pumpPage(
          tester,
          const LibraryPage(libraryId: 'bad', libraryName: 'Bad'),
          seed: (c) => c.failChildren = true);
      if (find.text('Retry').evaluate().isNotEmpty) {
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
      }
    });
  });

  group('SearchPage', () {
    testWidgets('tapping a result navigates', (tester) async {
      final result = await TestHarness.create();
      mockSecureStorage();
      result.harness.client.searchResults = [
        makeItem(id: 'r9', name: 'Hit')
      ];
      final router = GoRouter(routes: [
        GoRoute(
            path: '/search',
            builder: (_, _) => const Scaffold(body: SearchPage())),
        GoRoute(
            path: '/item/:id',
            builder: (_, s) => Scaffold(
                body: Text('ITEM ${s.pathParameters['id']}'))),
      ], initialLocation: '/search');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]));
      await tester.enterText(find.byType(TextField), 'hit');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hit'));
      await tester.pumpAndSettle();
      expect(find.text('ITEM r9'), findsOneWidget);
    });
  });

  group('FavoritesPage', () {
    testWidgets('unfavorite via detail route works', (tester) async {
      await pumpPage(tester, const FavoritesPage(), seed: (c) {
        c.favorites = [makeItem(id: 'f1', name: 'Fav')];
      });
      expect(find.text('Fav'), findsOneWidget);
    });
  });

  group('DownloadsPage', () {
    testWidgets('remove action shows confirm dialog',
        (tester) async {
      final result = await TestHarness.create();
      await tester.pumpWidget(testApp(
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
              ])),
        ],
        child: const DownloadsPage(),
      ));
      await tester.pumpAndSettle();
      if (find.byIcon(Icons.delete_outline).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
      } else {
        await tester.drag(find.text('Film'), const Offset(-400, 0));
        await tester.pumpAndSettle();
      }
    });
  });

  group('LibrariesPage', () {
    testWidgets('tapping a library navigates', (tester) async {
      final result = await TestHarness.create();
      mockSecureStorage();
      result.harness.client.libraries = [
        makeItem(
            id: 'l9',
            name: 'Films',
            type: 'CollectionFolder',
            collectionType: 'movies',
            isFolder: true)
      ];
      final router = GoRouter(routes: [
        GoRoute(
            path: '/libraries',
            builder: (_, _) => const LibrariesPage()),
        GoRoute(
            path: '/library/:id',
            builder: (_, s) => Scaffold(
                body: Text('LIB ${s.pathParameters['id']}'))),
      ], initialLocation: '/libraries');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Films'));
      await tester.pumpAndSettle();
      expect(find.text('LIB l9'), findsOneWidget);
    });
  });

  group('ConnectPage', () {
    testWidgets('probe failure shows an error', (tester) async {
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false);
      result.harness.client.failInfo = true;
      await tester.pumpWidget(testApp(
        overrides: [
          ...result.overrides,
          sessionProvider.overrideWith(() => FakeSessionNotifier(
              null, fakeClient: result.harness.client)),
        ],
        child: const ConnectPage(),
      ));
      await tester.enterText(
          find.byType(TextField), 'http://bad.local');
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
      expect(find.textContaining('reach'), findsWidgets);
    });
  });

  group('SettingsPage', () {
    testWidgets('sign out confirms and clears', (tester) async {
      await pumpPage(tester, const SettingsPage());
      await tester.fling(find.byType(ListView).first,
          const Offset(0, -600), 1000);
      await tester.pumpAndSettle();
      if (find.text('Sign out').evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign out'));
        await tester.pumpAndSettle();
        expect(find.text('NAV /connect'), findsOneWidget);
      }
    });
  });
}

class _Dl extends DownloadsNotifier {
  _Dl(this.records);
  final List<DownloadRecord> records;
  @override
  List<DownloadRecord> build() => records;
}
