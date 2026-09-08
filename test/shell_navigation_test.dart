import 'package:finar/core/api/jellyfin_api.dart';
import 'package:finar/core/api/media_service.dart';
import 'package:finar/core/api/models/library.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/services/download_service.dart';
import 'package:finar/pages/home.dart';
import 'package:finar/pages/home/widgets/home_desktop.dart';
import 'package:finar/pages/home/widgets/home_library_browser.dart';
import 'package:finar/pages/home/widgets/home_mobile.dart';
import 'package:finar/pages/library.dart';
import 'package:finar/pages/settings/widgets/settings_desktop.dart';
import 'package:finar/pages/settings/widgets/settings_mobile.dart';
import 'package:finar/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeJellyfinApi extends JellyfinApi {
  @override
  Future<List<Library>> getLibraries() async => _libraries;
}

class _FakeMediaService extends MediaService {
  _FakeMediaService() : super(JellyfinApi());

  @override
  Future<HomeData> getHomeData() async {
    return const HomeData(
      continueWatching: [],
      nextUp: [],
      recentlyAdded: [],
      recentlyReleased: [],
      topRated: [],
      recommended: [],
      favorites: [],
      recentlyAddedMovies: [],
      recentlyAddedShows: [],
      libraries: [],
    );
  }

  @override
  Future<LibraryContent> getLibraryContent(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    List<String>? genres,
    List<int>? years,
    String? searchTerm,
  }) async {
    return const LibraryContent(items: [], totalCount: 0, hasMore: false);
  }

  @override
  Future<LibraryContent> getMusicLibraryContent(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    return const LibraryContent(items: [], totalCount: 0, hasMore: false);
  }

  @override
  Future<LibraryContent> getMusicArtists(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    return const LibraryContent(items: [], totalCount: 0, hasMore: false);
  }

  @override
  Future<LibraryContent> getMusicTracks(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    return const LibraryContent(items: [], totalCount: 0, hasMore: false);
  }
}

const _libraries = [
  Library(id: 'lib1', name: 'Movies', collectionType: 'movies'),
];

List<Override> _overrides() => [
  mediaServiceProvider.overrideWith((ref) => _FakeMediaService()),
  jellyfinApiProvider.overrideWith((ref) => _FakeJellyfinApi()),
  libraryProvider.overrideWith(
    (ref) => LibraryNotifier(_FakeMediaService(), _FakeJellyfinApi()),
  ),
  librariesProvider.overrideWith((ref) => Future.value(_libraries)),
  homeDataProvider.overrideWith(
    (ref) async => const HomeData(
      continueWatching: [],
      nextUp: [],
      recentlyAdded: [],
      recentlyReleased: [],
      topRated: [],
      recommended: [],
      favorites: [],
      recentlyAddedMovies: [],
      recentlyAddedShows: [],
      libraries: _libraries,
    ),
  ),
  isOnlineProvider.overrideWith((ref) => true),
  playerProvider.overrideWith(
    (ref) => PlayerNotifier.uninitialized(
      _FakeMediaService(),
      DownloadService(_FakeJellyfinApi()),
    ),
  ),
  favoritesProvider(null).overrideWith((ref) async => <MediaItem>[]),
];

void _setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  group('ShellNavNotifier', () {
    test('goTo selects a section and leaves any open library', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(shellNavProvider.notifier);

      notifier.openLibrary('lib1');
      notifier.goTo(ShellSection.settings);

      final state = container.read(shellNavProvider);
      expect(state.section, ShellSection.settings);
      expect(state.libraryId, isNull);
    });

    test('openLibrary selects the library section with its id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(shellNavProvider.notifier).openLibrary('lib1');

      final state = container.read(shellNavProvider);
      expect(state.section, ShellSection.library);
      expect(state.libraryId, 'lib1');
    });

    test('closeLibrary returns to the library browser', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(shellNavProvider.notifier);

      notifier.openLibrary('lib1');
      notifier.closeLibrary();

      final state = container.read(shellNavProvider);
      expect(state.section, ShellSection.library);
      expect(state.libraryId, isNull);
    });
  });

  group('layout switching', () {
    testWidgets('resizing to desktop keeps the settings section', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: _overrides());
      addTearDown(container.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      _setSurfaceSize(tester, const Size(500, 900));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeMobile), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsMobile), findsOneWidget);
      expect(container.read(shellNavProvider).section, ShellSection.settings);

      _setSurfaceSize(tester, const Size(1400, 900));
      await tester.pumpAndSettle();

      expect(find.byType(HomeDesktop), findsOneWidget);
      expect(find.byType(SettingsDesktop), findsOneWidget);
      expect(container.read(shellNavProvider).section, ShellSection.settings);

      _setSurfaceSize(tester, const Size(500, 900));
      await tester.pumpAndSettle();

      expect(find.byType(HomeMobile), findsOneWidget);
      expect(find.byType(SettingsMobile), findsOneWidget);
    });

    testWidgets('an open library stays open across the breakpoint', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: _overrides());
      addTearDown(container.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      container.read(libraryProvider.notifier).state = const LibraryState(
        libraries: _libraries,
      );

      _setSurfaceSize(tester, const Size(500, 900));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      container.read(shellNavProvider.notifier).openLibrary('lib1');
      await tester.pumpAndSettle();

      expect(find.byType(LibraryMobile), findsOneWidget);
      expect(find.text('Movies'), findsWidgets);

      _setSurfaceSize(tester, const Size(1400, 900));
      await tester.pumpAndSettle();

      expect(find.byType(LibraryDesktop), findsOneWidget);
      expect(find.text('Movies'), findsWidgets);
      expect(container.read(shellNavProvider).libraryId, 'lib1');
    });

    testWidgets('in-shell library back button returns to the browser', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(overrides: _overrides());
      addTearDown(container.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      container.read(libraryProvider.notifier).state = const LibraryState(
        libraries: _libraries,
      );

      _setSurfaceSize(tester, const Size(500, 900));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      container.read(shellNavProvider.notifier).openLibrary('lib1');
      await tester.pumpAndSettle();

      expect(find.byType(LibraryMobile), findsOneWidget);

      // The header must show a back button even though the route cannot pop.
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      final nav = container.read(shellNavProvider);
      expect(nav.section, ShellSection.library);
      expect(nav.libraryId, isNull);
      expect(find.byType(LibraryBrowser), findsOneWidget);
    });
  });
}
