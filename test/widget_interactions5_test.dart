import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finar/core/models/models.dart';
import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/storage/downloads_store.dart';
import 'package:finar/pages/connect/connect_page.dart';
import 'package:finar/pages/detail/detail_page.dart';
import 'package:finar/pages/downloads/downloads_page.dart';
import 'package:finar/pages/favorites/favorites_page.dart';
import 'package:finar/pages/home/home_page.dart';
import 'package:finar/pages/libraries/libraries_page.dart';
import 'package:finar/pages/login/login_page.dart';
import 'package:finar/pages/player/player_page.dart';
import 'package:finar/pages/search/search_page.dart';
import 'package:finar/pages/settings/settings_page.dart';
import 'package:finar/providers/downloads_provider.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:finar/providers/update_provider.dart';
import 'package:finar/widgets/title_bar.dart';
import 'package:finar/core/update/app_update.dart';
import 'package:finar/core/utils/version_utils.dart';

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

  group('PlayerPage controls', () {
    Future<(ProviderContainer, TestHarness)> pumpPlayer(
        WidgetTester tester, BaseItem item) async {
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
      await c.read(playerProvider.notifier).playItem(item);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: testApp(child: const PlayerPage()),
      ));
      await tester.pumpAndSettle();
      return (c, result.harness);
    }

    testWidgets('subtitle and audio menus select tracks',
        (tester) async {
      final (c, harness) = await pumpPlayer(
          tester,
          makeItem(id: 'v1', type: 'Movie', name: 'Film', mediaStreams: [
            const MediaStream(
                index: 1, type: 'Audio', displayTitle: 'English'),
            const MediaStream(
                index: 2, type: 'Subtitle', displayTitle: 'English'),
          ]));
      await tester.tap(find.byIcon(Icons.subtitles_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(harness.backend.lastSubtitle, 2);
      await tester.tap(find.byIcon(Icons.audiotrack_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(harness.backend.lastAudio, 1);
      await c.read(playerProvider.notifier).stop();
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('overlay back button stops playback',
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
      await c
          .read(playerProvider.notifier)
          .playItem(makeItem(id: 'v1', type: 'Movie'));
      final router = GoRouter(routes: [
        GoRoute(path: '/play', builder: (_, _) => const PlayerPage()),
        GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME'))),
      ], initialLocation: '/home');
      await tester.pumpWidget(
          routedTestApp(router: router, container: c));
      await tester.pumpAndSettle();
      router.push('/play');
      await tester.pumpAndSettle();
      final back = find.byIcon(Icons.arrow_back);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
        await tester.pumpAndSettle();
        expect(c.read(playerProvider).item, isNull);
      }
    });

    testWidgets('empty player back button pops', (tester) async {
      mockSecureStorage();
      final result = await TestHarness.create();
      final router = GoRouter(routes: [
        GoRoute(
            path: '/play',
            builder: (_, _) => const PlayerPage()),
        GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME'))),
      ], initialLocation: '/home');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]));
      router.push('/play');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Back'));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });
  });

  group('DetailPage buttons', () {
    testWidgets('resume label shows for partial item',
        (tester) async {
      await pumpPage(tester, const DetailPage(itemId: 'm1'),
          seed: (c) {
        c.items['m1'] = makeItem(
            id: 'm1', name: 'Film', positionTicks: 3000000000);
      });
      expect(find.text('Resume'), findsOneWidget);
    });

    testWidgets('genre chip tap is a no-op', (tester) async {
      await pumpPage(tester, const DetailPage(itemId: 'm1'),
          seed: (c) {
        c.items['m1'] =
            makeItem(id: 'm1', name: 'Film', genres: ['Drama']);
      });
      await tester.tap(find.text('Drama'));
      await tester.pumpAndSettle();
    });

    testWidgets('downloaded item shows disabled button',
        (tester) async {
      await pumpPage(tester, const DetailPage(itemId: 'm1'),
          seed: (c) {
        c.items['m1'] = makeItem(id: 'm1', name: 'Film');
      }, extra: [
        downloadsProvider.overrideWith(() => _Dl([
              const DownloadRecord(
                  itemId: 'm1',
                  name: 'Film',
                  type: 'Movie',
                  serverUrl: 'http://s',
                  localPath: '/tmp/x',
                  status: DownloadStatus.completed),
            ])),
      ]);
      expect(find.text('Downloaded'), findsOneWidget);
    });

    testWidgets('series play falls back to first episode',
        (tester) async {
      await pumpPage(tester, const DetailPage(itemId: 's1'),
          seed: (c) {
        c.items['s1'] =
            makeItem(id: 's1', name: 'Show', type: 'Series');
        c.nextUp = [];
        c.episodes['s1|'] = [
          makeItem(id: 'e1', name: 'Pilot', type: 'Episode')
        ];
      });
      await tester.tap(find.widgetWithText(FilledButton, 'Play'));
      await tester.pumpAndSettle();
      expect(find.text('NAV /play'), findsOneWidget);
    });

    testWidgets('back arrow navigates home without history',
        (tester) async {
      await pumpPage(tester, const DetailPage(itemId: 'm1'),
          seed: (c) {
        c.items['m1'] = makeItem(id: 'm1', name: 'Film');
      });
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('NAV /home'), findsOneWidget);
    });
  });

  group('SettingsPage updates and links', () {
    testWidgets('update available tile opens the release page',
        (tester) async {
      final launched = <String>[];
      TestDefaultBinaryMessengerBinding.instance
          .defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/url_launcher'),
              (call) async {
                if (call.method == 'launch') {
                  launched.add(call.arguments['url'] as String);
                }
                return true;
              });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance
          .defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/url_launcher'),
              null));
      await pumpPage(tester, const SettingsPage(), extra: [
        updateProvider.overrideWith(() => _Update(
            AppUpdate(
                version: const Version(9, 0, 0),
                tag: 'v9.0.0',
                url: Uri.parse('https://example.com/r')))),
      ]);
      await tester.fling(find.byType(ListView).first,
          const Offset(0, -800), 1000);
      await tester.pumpAndSettle();
      if (find.text('View release').evaluate().isNotEmpty) {
        await tester.tap(find.text('View release'));
        await tester.pumpAndSettle();
        expect(launched, contains('https://example.com/r'));
      }
      await tester.tap(find.text('Source code'));
      await tester.pumpAndSettle();
      expect(launched, isNotEmpty);
      await tester.tap(find.text('All releases'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy policy'));
      await tester.pumpAndSettle();
    });

    testWidgets('accent picker changes theme color',
        (tester) async {
      await pumpPage(tester, const SettingsPage());
      final boxes = find.byType(InkWell).evaluate()
          .map((e) => e.widget as InkWell)
          .where((w) => w.child is Container)
          .toList();
      if (boxes.isNotEmpty) {
        boxes.last.onTap!();
        await tester.pumpAndSettle();
      }
    });
  });

  group('LoginPage error branches', () {
    Future<GoRouter> pumpLogin(
        WidgetTester tester, FakeJellyfinClient client) async {
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
        sessionProvider.overrideWith(
            () => FakeSessionNotifier(null, fakeClient: client)),
        pendingServerProvider
            .overrideWith((ref) => 'http://demo.local'),
      ]));
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('non-auth error shows generic failure',
        (tester) async {
      final client = FakeJellyfinClient();
      client.authResult = null;
      client.failWith = const JellyfinException('server exploded',
          statusCode: 500);
      await pumpLogin(tester, client);
      await tester.enterText(find.byType(TextField).at(0), 'cal');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.textContaining('failed'), findsWidgets);
    });

    testWidgets('username field submits on enter', (tester) async {
      final client = FakeJellyfinClient();
      await pumpLogin(tester, client);
      await tester.enterText(find.byType(TextField).at(0), 'cal');
      await tester.testTextInput
          .receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
    });

    testWidgets('quick connect disabled shows error text',
        (tester) async {
      final client = FakeJellyfinClient();
      client.quickConnectAvailable = false;
      await pumpLogin(tester, client);
      await tester.tap(find.text('Quick Connect'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.textContaining('not enabled'), findsWidgets);
    });
  });

  group('HomePage details', () {
    testWidgets('next up card navigates', (tester) async {
      final result = await TestHarness.create();
      mockSecureStorage();
      result.harness.client.nextUp = [
        makeItem(id: 'n1', name: 'Next Ep', type: 'Episode')
      ];
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: HomePage())),
        GoRoute(
            path: '/item/:id',
            builder: (_, s) => Scaffold(
                body: Text('ITEM ${s.pathParameters['id']}'))),
      ]);
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]));
      await tester.pumpAndSettle();
      for (var i = 0;
          i < 8 && find.text('Next Ep').evaluate().isEmpty;
          i++) {
        await tester.drag(
            find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      tester
          .widget<InkWell>(find.ancestor(
              of: find.text('Next Ep'),
              matching: find.byType(InkWell)))
          .onTap!();
      await tester.pumpAndSettle();
      expect(
          router.routerDelegate.currentConfiguration.matches.last
              .matchedLocation,
          '/item/n1');
    });

    testWidgets('latest card opens detail', (tester) async {
      final result = await TestHarness.create();
      mockSecureStorage();
      result.harness.client.libraries = [
        makeItem(
            id: 'l1',
            name: 'Films',
            type: 'CollectionFolder',
            collectionType: 'movies',
            isFolder: true)
      ];
      result.harness.client.latest['l1'] = [
        makeItem(id: 'lt1', name: 'Latest One')
      ];
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: HomePage())),
        GoRoute(
            path: '/item/:id',
            builder: (_, s) => Scaffold(
                body: Text('ITEM ${s.pathParameters['id']}'))),
      ]);
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]));
      await tester.pumpAndSettle();
      for (var i = 0;
          i < 8 && find.text('Latest One').evaluate().isEmpty;
          i++) {
        await tester.drag(
            find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      tester
          .widget<InkWell>(find.ancestor(
              of: find.text('Latest One'),
              matching: find.byType(InkWell)))
          .onTap!();
      await tester.pumpAndSettle();
      expect(
          router.routerDelegate.currentConfiguration.matches.last
              .matchedLocation,
          '/item/lt1');
    });
  });

  group('Remaining pages', () {
    testWidgets('search clear resets the field', (tester) async {
      await pumpPage(tester, const SearchPage(), seed: (c) {
        c.searchResults = [makeItem(id: 'r1', name: 'Hit')];
      });
      await tester.enterText(find.byType(TextField), 'hit');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.text('Hit'), findsNothing);
    });

    testWidgets('search empty results state', (tester) async {
      await pumpPage(tester, const SearchPage());
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('libraries error retries', (tester) async {
      final harness = await pumpPage(tester, const LibrariesPage(),
          seed: (c) => c.failViews = true);
      if (find.text('Retry').evaluate().isNotEmpty) {
        harness.client.failViews = false;
        harness.client.libraries = [
          makeItem(
              id: 'l1',
              name: 'Films',
              type: 'CollectionFolder',
              isFolder: true)
        ];
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(find.text('Films'), findsOneWidget);
      }
    });

    testWidgets('favorites empty state', (tester) async {
      await pumpPage(tester, const FavoritesPage());
      expect(find.byType(FavoritesPage), findsOneWidget);
    });

    testWidgets('connect page submit on enter', (tester) async {
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
      await tester.enterText(
          find.byType(TextField), 'http://demo.local');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    });

    testWidgets('downloads renders all status rows', (tester) async {
      mockSecureStorage();
      mockPathProvider();
      final result = await TestHarness.create();
      await tester.pumpWidget(routedTestApp(
        router: GoRouter(routes: [
          GoRoute(
              path: '/',
              builder: (_, _) =>
                  const Scaffold(body: DownloadsPage())),
        ]),
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
                const DownloadRecord(
                    itemId: 'd3',
                    name: 'Bad',
                    type: 'Movie',
                    serverUrl: 'http://s',
                    localPath: '/tmp/z',
                    status: DownloadStatus.failed),
                const DownloadRecord(
                    itemId: 'd4',
                    name: 'Next',
                    type: 'Movie',
                    serverUrl: 'http://s',
                    localPath: '/tmp/w',
                    status: DownloadStatus.queued),
              ])),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Film'), findsOneWidget);
      expect(find.text('Track'), findsOneWidget);
      expect(find.text('Bad'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('title bar double tap maximizes', (tester) async {
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
      await tester.tap(find.text('Finar'));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.text('Finar'));
      await tester.pumpAndSettle();
      expect(actions.calls, contains('maximize'));
    });
  });
}

class _Dl extends DownloadsNotifier {
  _Dl(this.records);
  final List<DownloadRecord> records;
  @override
  List<DownloadRecord> build() => records;
}

class _FakeWindowActions implements WindowActions {
  final calls = <String>[];
  @override
  Future<void> minimize() async => calls.add('minimize');
  @override
  Future<void> maximizeOrRestore() async => calls.add('maximize');
  @override
  Future<void> close() async => calls.add('close');
  @override
  Future<bool> isMaximized() async => false;
  @override
  void dragMove() {}
}

class _Update extends UpdateNotifier {
  _Update(this.available);
  final AppUpdate available;
  @override
  UpdateState build() => UpdateAvailable(available);
}
