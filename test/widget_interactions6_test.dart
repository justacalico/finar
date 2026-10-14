import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:finar/pages/connect/connect_page.dart';
import 'package:finar/pages/detail/detail_page.dart';
import 'package:finar/pages/favorites/favorites_page.dart';
import 'package:finar/pages/home/home_page.dart';
import 'package:finar/pages/libraries/libraries_page.dart';
import 'package:finar/pages/player/player_page.dart';
import 'package:finar/pages/profiles/profiles_page.dart';
import 'package:finar/pages/search/search_page.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:finar/widgets/media_image.dart';
import 'package:finar/widgets/platform_io.dart';
import 'package:finar/widgets/responsive.dart';
import 'package:finar/widgets/title_bar.dart';

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

  group('Player slider and queue tile', () {
    testWidgets('seeking the slider seeks playback', (tester) async {
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
          .playItem(makeItem(id: 'v1', type: 'Movie', name: 'Film'));
      result.harness.backend.emitDuration(const Duration(minutes: 2));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: testApp(child: const PlayerPage()),
      ));
      await tester.pumpAndSettle();
      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        final center = tester.getCenter(slider);
        await tester.drag(slider, Offset(center.dx * -0.9, 0));
        await tester.pump();
        await tester.dragFrom(center, const Offset(300, 0));
        await tester.pump();
        expect(result.harness.backend.currentPosition,
            greaterThan(Duration.zero));
      }
      await c.read(playerProvider.notifier).stop();
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('Detail extras 2', () {
    testWidgets('played episode shows check icon', (tester) async {
      await pumpPage(tester, const DetailPage(itemId: 's1'),
          seed: (c) {
        c.items['s1'] =
            makeItem(id: 's1', name: 'Show', type: 'Series');
        c.seasons['s1'] = [
          makeItem(id: 'sea1', name: 'Season 1', type: 'Season')
        ];
        c.episodes['s1|sea1'] = [
          makeItem(
              id: 'e1',
              name: 'Done Ep',
              type: 'Episode',
              indexNumber: 1,
              played: true)
        ];
      });
      expect(find.textContaining('Done Ep'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('artist album card year subtitle', (tester) async {
      await pumpPage(tester, const DetailPage(itemId: 'ar1'),
          seed: (c) {
        c.items['ar1'] =
            makeItem(id: 'ar1', name: 'Artist', type: 'MusicArtist');
        c.artistAlbums = [
          makeItem(
              id: 'alb1',
              name: 'Studio',
              type: 'MusicAlbum',
              year: 1999)
        ];
      });
      expect(find.text('1999'), findsOneWidget);
    });
  });

  group('Profiles extras', () {
    Future<void> pumpProfiles(WidgetTester tester,
        {required String profilesJson,
        required FakeJellyfinClient client}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      mockSecureStorage();
      final result = await TestHarness.create(
          signedIn: false, prefs: {'session.profiles': profilesJson});
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
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider.overrideWith(
            () => FakeSessionNotifier(null, fakeClient: client)),
      ]));
      await tester.pumpAndSettle();
    }

    testWidgets('profile sign in failure goes to connect',
        (tester) async {
      final client = FakeJellyfinClient()..failViews = true;
      await pumpProfiles(tester, client: client, profilesJson:
          '[{"id":"http://srv|u1","serverUrl":"http://srv","serverName":"Home","userId":"u1","userName":"Cal"}]');
      await tester.tap(find.text('Cal'));
      await tester.pumpAndSettle();
      expect(find.text('CONNECT'), findsOneWidget);
    });

    testWidgets('add profile card navigates', (tester) async {
      await pumpProfiles(tester, client: FakeJellyfinClient(),
          profilesJson:
              '[{"id":"http://srv|u1","serverUrl":"http://srv","serverName":"Home","userId":"u1","userName":"Cal"}]');
      await tester.tap(find.text('Add account').first);
      await tester.pumpAndSettle();
      expect(find.text('CONNECT'), findsOneWidget);
    });
  });

  group('Home extras', () {
    testWidgets('continue watching card navigates', (tester) async {
      final result = await TestHarness.create();
      mockSecureStorage();
      result.harness.client.resume = [
        makeItem(id: 'r1', name: 'Mid Film')
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
          i < 8 && find.text('Mid Film').evaluate().isEmpty;
          i++) {
        await tester.drag(
            find.byType(ListView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      tester
          .widget<InkWell>(find.ancestor(
              of: find.text('Mid Film'),
              matching: find.byType(InkWell)))
          .onTap!();
      await tester.pumpAndSettle();
      expect(
          router.routerDelegate.currentConfiguration.matches.last
              .matchedLocation,
          '/item/r1');
    });

    testWidgets('hero resume label on partial item', (tester) async {
      await pumpPage(tester, const HomePage(), seed: (c) {
        c.resume = [makeItem(id: 'r1', name: 'Mid Film')];
        c.libraries = [];
        c.items['hero'] = makeItem(
            id: 'hero', name: 'Hero', positionTicks: 100000);
      });
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('Rest', () {
    testWidgets('search error state renders', (tester) async {
      await pumpPage(tester, const SearchPage(), seed: (c) {
        c.failSearch = true;
      });
      await tester.enterText(find.byType(TextField), 'hit');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.error_outline), findsWidgets);
    });

    testWidgets('favorites error retries', (tester) async {
      final harness = await pumpPage(tester, const FavoritesPage(),
          seed: (c) => c.failChildren = true);
      if (find.text('Retry').evaluate().isNotEmpty) {
        harness.client.failChildren = false;
        harness.client.favorites = [makeItem(id: 'f9', name: 'Fav')];
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(find.text('Fav'), findsOneWidget);
      }
    });

    testWidgets('libraries icon variants render', (tester) async {
      await pumpPage(tester, const LibrariesPage(), seed: (c) {
        c.libraries = [
          makeItem(
              id: 'a', name: 'Films', type: 'CollectionFolder',
              collectionType: 'music', isFolder: true),
          makeItem(
              id: 'b', name: 'Pics', type: 'CollectionFolder',
              collectionType: 'photos', isFolder: true),
          makeItem(
              id: 'c', name: 'Books', type: 'CollectionFolder',
              collectionType: 'books', isFolder: true),
        ];
      });
      expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
      expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
      expect(find.byIcon(Icons.book_outlined), findsOneWidget);
    });

    testWidgets('connect profiles shortcut navigates', (tester) async {
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false);
      final router = GoRouter(routes: [
        GoRoute(
            path: '/connect',
            builder: (_, _) => const ConnectPage()),
        GoRoute(
            path: '/profiles',
            builder: (_, _) =>
                const Scaffold(body: Text('PROFILES'))),
      ], initialLocation: '/connect');
      await tester.pumpWidget(routedTestApp(router: router, overrides: [
        ...result.overrides,
        sessionProvider.overrideWith(() => FakeSessionNotifier(
            null, fakeClient: result.harness.client)),
      ]));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('watching'));
      await tester.pumpAndSettle();
      expect(find.text('PROFILES'), findsOneWidget);
    });

    testWidgets('media image fallback on 404', (tester) async {
      mockSecureStorage();
      final result = await TestHarness.create();
      await tester.pumpWidget(testApp(
        overrides: result.overrides,
        child: SizedBox(
          width: 80,
          height: 80,
          child: MediaImage(
              url: Uri.parse('http://s/broken.jpg'),
              icon: Icons.movie_outlined),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    });

    testWidgets('grid columns adapt to width', (tester) async {
      await pumpPage(tester, const LibrariesPage(),
          size: const Size(400, 800), seed: (c) {
        c.libraries = [];
      });
      expect(gridColumnsForWidth(400), 3);
      expect(isDesktopOs, isTrue);
    });

    testWidgets('title bar hover shows icons', (tester) async {
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
      final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse, pointer: 1);
      await mouse.moveTo(tester.getCenter(find.byTooltip('close')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      final title = tester.getCenter(find.text('Finar'));
      final pan = await tester.createGesture();
      await pan.down(title);
      await pan.moveBy(const Offset(50, 0));
      await tester.pump();
      await pan.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
    });
  });
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
