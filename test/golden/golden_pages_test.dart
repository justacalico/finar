import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finar/core/models/models.dart';
import 'package:finar/core/storage/downloads_store.dart';
import 'package:finar/pages/connect/connect_page.dart';
import 'package:finar/pages/detail/detail_page.dart';
import 'package:finar/pages/downloads/downloads_page.dart';
import 'package:finar/pages/favorites/favorites_page.dart';
import 'package:finar/pages/home/home_page.dart';
import 'package:finar/pages/libraries/libraries_page.dart';
import 'package:finar/pages/library/library_page.dart';
import 'package:finar/pages/login/login_page.dart';
import 'package:finar/pages/player/player_page.dart';
import 'package:finar/pages/profiles/profiles_page.dart';
import 'package:finar/pages/search/search_page.dart';
import 'package:finar/pages/settings/settings_page.dart';
import 'package:finar/providers/downloads_provider.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:finar/l10n/generated/app_localizations.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../helpers/fake_client.dart';
import '../helpers/path_provider_mock.dart';
import '../helpers/secure_storage_mock.dart';
import '../helpers/test_app.dart';

const _desktop = Size(1440, 900);
const _mobile = Size(390, 844);

class _FixedDownloads extends DownloadsNotifier {
  _FixedDownloads(this.records);
  final List<DownloadRecord> records;
  @override
  List<DownloadRecord> build() => records;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TestHarness> pump(
    WidgetTester tester,
    Widget page, {
    Size size = _desktop,
    bool signedIn = true,
    List<Override> extra = const [],
    Locale? locale,
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
      locale: locale,
      child: Scaffold(body: page),
    ));
    await tester.pumpAndSettle();
    return result.harness;
  }

  void seedLibrary(FakeJellyfinClient client) {
    client.libraries = [
      makeItem(
          id: 'libMovies',
          name: 'Movies',
          type: 'CollectionFolder',
          collectionType: 'movies',
          isFolder: true),
      makeItem(
          id: 'libShows',
          name: 'Shows',
          type: 'CollectionFolder',
          collectionType: 'tvshows',
          isFolder: true),
      makeItem(
          id: 'libMusic',
          name: 'Music',
          type: 'CollectionFolder',
          collectionType: 'music',
          isFolder: true),
    ];
    client.resume = [
      makeItem(
          id: 'r1', name: 'Dune: Part Two', positionTicks: 36000000000),
      makeItem(
          id: 'r2',
          name: 'Pilot',
          type: 'Episode',
          seriesName: 'Severance',
          positionTicks: 12000000000),
    ];
    client.nextUp = [
      makeItem(
          id: 'n1',
          name: 'The We We Are',
          type: 'Episode',
          seriesName: 'Severance'),
      makeItem(
          id: 'n2',
          name: 'What\'s Past Is Prologue',
          type: 'Episode',
          seriesName: 'Discovery'),
    ];
    client.latest['libMovies'] = [
      makeItem(id: 'l1', name: 'Interstellar'),
      makeItem(id: 'l2', name: 'Arrival'),
      makeItem(id: 'l3', name: 'Tenet'),
      makeItem(id: 'l4', name: 'The Batman'),
    ];
    client.latest['libShows'] = [
      makeItem(id: 'l5', name: 'Andor', type: 'Series'),
      makeItem(id: 'l6', name: 'Silo', type: 'Series'),
    ];
    client.latest['libMusic'] = [
      makeItem(
          id: 'l7',
          name: 'Currents',
          type: 'MusicAlbum',
          albumArtist: 'Tame Impala'),
    ];
    client.favorites = [
      makeItem(id: 'f1', name: 'Dune', favorite: true),
      makeItem(id: 'f2', name: 'Andor', type: 'Series', favorite: true),
    ];
    client.searchResults = [makeItem(id: 's1', name: 'Dune')];
    client.children['libMovies'] = [
      for (var i = 0; i < 12; i++)
        makeItem(id: 'g$i', name: 'Movie ${i + 1}', year: 2000 + i),
    ];
    client.items['m1'] = makeItem(
      id: 'm1',
      name: 'Interstellar',
      year: 2014,
      overview:
          'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.',
      genres: ['Sci-Fi', 'Adventure', 'Drama'],
      rating: 8.7,
      runTimeTicks: 101400000000,
      people: const [
        Person(id: 'p1', name: 'Matthew McConaughey', role: 'Cooper'),
        Person(id: 'p2', name: 'Anne Hathaway', role: 'Brand'),
        Person(id: 'p3', name: 'Jessica Chastain', role: 'Murph'),
      ],
    );
    client.similar['m1'] = [
      makeItem(id: 's2', name: 'Arrival'),
      makeItem(id: 's3', name: 'Tenet'),
    ];
    client.items['series1'] = makeItem(
      id: 'series1',
      name: 'Severance',
      type: 'Series',
      overview: 'Mark leads a team of office workers.',
      genres: ['Drama', 'Sci-Fi'],
    );
    client.seasons['series1'] = [
      makeItem(id: 'sea1', name: 'Season 1', type: 'Season'),
      makeItem(id: 'sea2', name: 'Season 2', type: 'Season'),
    ];
    client.episodes['series1|sea1'] = [
      makeItem(
          id: 'e1',
          name: 'Good News About Hell',
          type: 'Episode',
          indexNumber: 1,
          runTimeTicks: 34200000000),
      makeItem(
          id: 'e2',
          name: 'Half Loop',
          type: 'Episode',
          indexNumber: 2,
          runTimeTicks: 31800000000,
          positionTicks: 10000000000),
    ];
    client.items['album1'] = makeItem(
      id: 'album1',
      name: 'Currents',
      type: 'MusicAlbum',
      albumArtist: 'Tame Impala',
      overview: 'Third studio album.',
    );
    client.children['album1'] = [
      makeItem(
          id: 't1',
          name: 'Let It Happen',
          type: 'Audio',
          indexNumber: 1,
          albumArtist: 'Tame Impala',
          runTimeTicks: 4680000000),
      makeItem(
          id: 't2',
          name: 'The Less I Know the Better',
          type: 'Audio',
          indexNumber: 2,
          albumArtist: 'Tame Impala',
          runTimeTicks: 2160000000),
    ];
  }

  Future<void> snap(String name) => expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/$name.png'));

  group('auth screens', () {
    testWidgets('connect page', (tester) async {
      await pump(tester, const ConnectPage(),
          size: _mobile, signedIn: false);
      await snap('connect_mobile');
    });

    testWidgets('login page', (tester) async {
      tester.view.physicalSize = _mobile;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false);
      await tester.pumpWidget(testApp(
        overrides: [
          ...result.overrides,
          pendingServerProvider
              .overrideWith((ref) => 'http://demo.local'),
        ],
        child: const Scaffold(body: LoginPage()),
      ));
      await tester.pumpAndSettle();
      await snap('login_mobile');
    });

    testWidgets('profiles page', (tester) async {
      tester.view.physicalSize = _mobile;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false, prefs: {
        'session.profiles':
            '[{"id":"p1","serverUrl":"http://srv","serverName":"Home","userId":"u1","userName":"Calico"}]'
      });
      await tester.pumpWidget(testApp(
        overrides: result.overrides,
        child: const Scaffold(body: ProfilesPage()),
      ));
      await tester.pumpAndSettle();
      await snap('profiles_mobile');
    });
  });

  group('main screens', () {
    testWidgets('home desktop', (tester) async {
      await pump(tester, const HomePage(), seed: seedLibrary);
      await snap('home_desktop');
    });

    testWidgets('home mobile', (tester) async {
      await pump(tester, const HomePage(),
          size: _mobile, seed: seedLibrary);
      await snap('home_mobile');
    });

    testWidgets('libraries', (tester) async {
      await pump(tester, const LibrariesPage(), seed: seedLibrary);
      await snap('libraries_desktop');
    });

    testWidgets('library grid', (tester) async {
      await pump(tester,
          const LibraryPage(libraryId: 'libMovies', libraryName: 'Movies'),
          seed: seedLibrary);
      await snap('library_desktop');
    });

    testWidgets('search', (tester) async {
      await pump(tester, const SearchPage(), seed: seedLibrary);
      await snap('search_desktop');
    });

    testWidgets('favorites', (tester) async {
      await pump(tester, const FavoritesPage(), seed: seedLibrary);
      await snap('favorites_desktop');
    });

    testWidgets('downloads', (tester) async {
      await pump(
        tester,
        const DownloadsPage(),
        seed: seedLibrary,
        extra: [
          downloadsProvider.overrideWith(() => _FixedDownloads([
                const DownloadRecord(
                    itemId: 'd1',
                    name: 'Dune: Part Two',
                    type: 'Movie',
                    subtitle: 'Movies',
                    serverUrl: 'http://srv',
                    localPath: '/tmp/d1',
                    status: DownloadStatus.completed,
                    totalBytes: 4294967296),
                const DownloadRecord(
                    itemId: 'd2',
                    name: 'Let It Happen',
                    type: 'Audio',
                    subtitle: 'Tame Impala',
                    serverUrl: 'http://srv',
                    localPath: '/tmp/d2',
                    status: DownloadStatus.downloading,
                    progress: 0.4),
              ])),
        ],
      );
      await snap('downloads_desktop');
    });

    testWidgets('settings desktop', (tester) async {
      await pump(tester, const SettingsPage(), seed: seedLibrary);
      await snap('settings_desktop');
    });

    testWidgets('settings zh locale', (tester) async {
      await pump(tester, const SettingsPage(),
          seed: seedLibrary, locale: const Locale('zh'));
      await snap('settings_zh');
    });

    testWidgets('movie detail', (tester) async {
      await pump(tester, const DetailPage(itemId: 'm1'),
          seed: seedLibrary);
      await snap('detail_movie_desktop');
    });

    testWidgets('series detail', (tester) async {
      await pump(tester, const DetailPage(itemId: 'series1'),
          seed: seedLibrary);
      await snap('detail_series_desktop');
    });

    testWidgets('album detail mobile', (tester) async {
      await pump(tester, const DetailPage(itemId: 'album1'),
          size: _mobile, seed: seedLibrary);
      await snap('detail_album_mobile');
    });

    testWidgets('player audio', (tester) async {
          tester.view.physicalSize = _desktop;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      mockPathProvider();
      final result = await TestHarness.create();
      seedLibrary(result.harness.client);
      final container = ProviderContainer(overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ]);
      await container.read(playerProvider.notifier).playQueue(
          result.harness.client.children['album1']!, 0);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const Scaffold(body: PlayerPage()),
        ),
      ));
      await tester.pumpAndSettle();
      await snap('player_audio');
      await container.read(playerProvider.notifier).stop();
      container.dispose();
    });
  });
}
