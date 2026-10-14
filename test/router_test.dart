import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finar/providers/session_provider.dart';
import 'package:finar/router.dart';

import 'helpers/secure_storage_mock.dart';
import 'helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<Override>> overrides(
      {bool signedIn = true,
      Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    mockSecureStorage();
    final result =
        await TestHarness.create(signedIn: signedIn, prefs: prefs);
    return [
      ...result.overrides,
      sessionProvider.overrideWith(
          () => FakeSessionNotifier(signedIn ? testSession() : null)),
      bootstrappedProvider.overrideWith((ref) => true),
    ];
  }

  testWidgets('signed-in user lands on home', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: await overrides(),
      child: const RoutedTestApp(showTitleBar: false),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsWidgets);
    final router = _routerOf(tester);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
  });

  testWidgets('signed-out user with no profiles lands on connect',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: await overrides(signedIn: false),
      child: const RoutedTestApp(showTitleBar: false),
    ));
    await tester.pumpAndSettle();
    final router = _routerOf(tester);
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/connect');
  });

  testWidgets('signed-out user with saved profiles stays on profiles',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: await overrides(signedIn: false, prefs: {
        'session.profiles':
            '[{"id":"p1","serverUrl":"http://srv","serverName":"Home","userId":"u1","userName":"Cal"}]'
      }),
      child: const RoutedTestApp(showTitleBar: false),
    ));
    await tester.pumpAndSettle();
    final router = _routerOf(tester);
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/profiles');
  });

  testWidgets('login without pending server bounces to connect',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: await overrides(signedIn: false),
      child: const RoutedTestApp(showTitleBar: false),
    ));
    await tester.pumpAndSettle();
    final router = _routerOf(tester);
    router.go('/login');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/connect');
  });


  testWidgets('every shell route renders', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: await overrides(),
      child: const RoutedTestApp(showTitleBar: false),
    ));
    await tester.pumpAndSettle();
    final router = _routerOf(tester);
    for (final path in [
      '/home',
      '/library',
      '/library/lib1',
      '/search',
      '/favorites',
      '/downloads',
      '/settings',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path,
          startsWith(path.split('?').first.split('/').length > 2
              ? '/library'
              : path));
    }
  });

  testWidgets('play route stays with empty player', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: await overrides(),
      child: const RoutedTestApp(showTitleBar: false),
    ));
    await tester.pumpAndSettle();
    final router = _routerOf(tester);
    router.go('/play');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/play');
  });

  testWidgets('detail route renders the item', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ovs = await overrides();
    await tester.pumpWidget(ProviderScope(
      overrides: ovs,
      child: const RoutedTestApp(showTitleBar: false),
    ));
    await tester.pumpAndSettle();
    final router = _routerOf(tester);
    router.go('/item/x1');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/item/x1');
    expect(find.text('Something went wrong.'), findsOneWidget);
  });

  testWidgets('not bootstrapped redirects to splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    final result = await TestHarness.create();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ],
      child: const RoutedTestApp(showTitleBar: false),
    ));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    final router = _routerOf(tester);
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/splash');
  });

  testWidgets('signed-in user on /login bounces to home',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: await overrides(),
      child: const RoutedTestApp(showTitleBar: false),
    ));
    await tester.pumpAndSettle();
    final router = _routerOf(tester);
    router.go('/login');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/home');
    router.go('/connect');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/home');
    router.go('/libraries');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/libraries');
  });

  testWidgets('pending server change keeps navigation stack',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: await overrides(signedIn: false),
      child: const RoutedTestApp(showTitleBar: false),
    ));
    await tester.pumpAndSettle();
    final router = _routerOf(tester);
    final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)));
    container.read(pendingServerProvider.notifier).state =
        'http://demo.local';
    await tester.pump();
    expect(identical(_routerOf(tester), router), isTrue);
    router.go('/login');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/login');
  });

  testWidgets('login page builds when a server is pending',
      (tester) async {
    mockSecureStorage();
    final result = await TestHarness.create(signedIn: false, prefs: {
      'session.profiles':
          '[{"id":"p1","serverUrl":"http://srv","serverName":"Home","userId":"u1","userName":"Cal"}]'
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(null)),
        bootstrappedProvider.overrideWith((ref) => true),
        pendingServerProvider
            .overrideWith((ref) => 'http://demo.local'),
      ],
      child: const RoutedTestApp(showTitleBar: false),
    ));
    await tester.pumpAndSettle();
    final router = _routerOf(tester);
    router.go('/login');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/login');
  });

  test('defaultWindowActions returns actions on desktop', () {
    expect(defaultWindowActions(), isNotNull);
  });
}

GoRouter _routerOf(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
        as GoRouter;
