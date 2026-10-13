import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finar/core/models/models.dart';
import 'package:finar/core/storage/downloads_store.dart';
import 'package:finar/core/storage/settings_store.dart';
import 'package:finar/pages/connect/connect_page.dart';
import 'package:finar/pages/detail/detail_page.dart';
import 'package:finar/pages/downloads/downloads_page.dart';
import 'package:finar/pages/favorites/favorites_page.dart';
import 'package:finar/pages/search/search_page.dart';
import 'package:finar/pages/settings/settings_page.dart';
import 'package:finar/providers/downloads_provider.dart';
import 'package:finar/providers/session_provider.dart';

import 'helpers/fake_client.dart';
import 'helpers/path_provider_mock.dart';
import 'helpers/secure_storage_mock.dart';
import 'helpers/test_app.dart';

class _ProbeSession extends FakeSessionNotifier {
  _ProbeSession(super.session);

  @override
  Future<PublicSystemInfo> probeServer(String serverUrl) async =>
      const PublicSystemInfo(
          serverName: 'Srv', version: '10.9', id: 'x');
}

class _FixedDownloads extends DownloadsNotifier {
  _FixedDownloads(this.records);
  final List<DownloadRecord> records;

  @override
  List<DownloadRecord> build() => records;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectPage', () {
    testWidgets('rejects empty url', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final result = await TestHarness.create(signedIn: false);
      await tester.pumpWidget(testApp(
          overrides: result.overrides, child: const ConnectPage()));
      await tester.tap(find.text('Connect'));
      await tester.pump();
      expect(find.text('Enter a valid server address.'),
          findsOneWidget);
    });

    testWidgets('valid url navigates to login', (tester) async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      final result = await TestHarness.create(signedIn: false);
      final router = GoRouter(
        initialLocation: '/connect',
        routes: [
          GoRoute(
              path: '/connect',
              builder: (_, _) => const ConnectPage()),
          GoRoute(
              path: '/login',
              builder: (_, _) =>
                  const Scaffold(body: Text('LOGIN'))),
        ],
      );
      await tester.pumpWidget(routedTestApp(
        router: router,
        overrides: [
          ...result.overrides,
          sessionProvider
              .overrideWith(() => _ProbeSession(null)),
        ],
      ));
      await tester.enterText(
          find.byType(TextField), 'http://demo.local');
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);
    });
  });

  group('SearchPage', () {
    testWidgets('typing a query lists results', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final result = await TestHarness.create();
      result.harness.client.searchResults = [
        makeItem(id: 'r1', name: 'Result One'),
      ];
      await tester.pumpWidget(testApp(
        overrides: [
          ...result.overrides,
          sessionProvider.overrideWith(
              () => FakeSessionNotifier(testSession())),
        ],
        child: const SearchPage(),
      ));
      await tester.enterText(find.byType(TextField), 'result');
      await tester.pumpAndSettle();
      expect(find.text('Result One'), findsOneWidget);
    });

    testWidgets('empty result shows placeholder', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final result = await TestHarness.create();
      await tester.pumpWidget(testApp(
        overrides: result.overrides,
        child: const SearchPage(),
      ));
      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('No results found.'), findsOneWidget);
    });
  });

  group('FavoritesPage', () {
    testWidgets('shows favourite items', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final result = await TestHarness.create();
      result.harness.client.favorites = [
        makeItem(id: 'f1', name: 'Fav Movie', favorite: true),
      ];
      await tester.pumpWidget(testApp(
        overrides: result.overrides,
        child: const FavoritesPage(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Fav Movie'), findsOneWidget);
    });

    testWidgets('empty favourites shows hint', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final result = await TestHarness.create();
      await tester.pumpWidget(testApp(
        overrides: result.overrides,
        child: const FavoritesPage(),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('favourites'),
          findsWidgets);
    });
  });

  group('DownloadsPage', () {
    testWidgets('lists downloads with status', (tester) async {
      SharedPreferences.setMockInitialValues({});
      mockPathProvider();
      final result = await TestHarness.create();
      await tester.pumpWidget(testApp(
        overrides: [
          ...result.overrides,
          downloadsProvider.overrideWith(() => _FixedDownloads([
                const DownloadRecord(
                    itemId: 'd1',
                    name: 'Film',
                    type: 'Movie',
                    serverUrl: 'http://srv',
                    localPath: '/tmp/d1',
                    status: DownloadStatus.completed,
                    totalBytes: 1048576),
                const DownloadRecord(
                    itemId: 'd2',
                    name: 'Song',
                    type: 'Audio',
                    serverUrl: 'http://srv',
                    localPath: '/tmp/d2',
                    status: DownloadStatus.downloading,
                    progress: 0.4),
              ])),
        ],
        child: const DownloadsPage(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Film'), findsOneWidget);
      expect(find.text('Song'), findsOneWidget);
      expect(find.text('Downloaded'), findsOneWidget);
    });
  });

  group('DetailPage', () {
    testWidgets('favourite button calls the client',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      mockPathProvider();
      final result = await TestHarness.create();
      result.harness.client.items['m1'] =
          makeItem(id: 'm1', name: 'Detail Movie');
      await tester.pumpWidget(testApp(
        overrides: result.overrides,
        child: const DetailPage(itemId: 'm1'),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Detail Movie'), findsOneWidget);
      await tester.tap(find.text('Favourite'));
      await tester.pump();
      expect(result.harness.client.favoriteCalls, 1);
    });
  });

  group('SettingsPage', () {
    testWidgets('changing theme persists', (tester) async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      mockPackageInfo();
      final result = await TestHarness.create();
      await tester.pumpWidget(testApp(
        overrides: [
          ...result.overrides,
          sessionProvider.overrideWith(
              () => FakeSessionNotifier(testSession())),
        ],
        child: const SettingsPage(),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      expect(
          prefs.getString('settings.theme'), AppThemeMode.dark.name);
    });

    testWidgets('switching to zh changes language label',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      mockPackageInfo();
      final result = await TestHarness.create();
      await tester.pumpWidget(testApp(
        overrides: [
          ...result.overrides,
          sessionProvider.overrideWith(
              () => FakeSessionNotifier(testSession())),
        ],
        child: const SettingsPage(),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('简体中文').last);
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('settings.locale'), 'zh');
    });
  });
}
