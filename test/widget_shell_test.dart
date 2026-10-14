import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finar/providers/player_provider.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:finar/widgets/app_shell.dart';
import 'package:finar/widgets/title_bar.dart';

import 'helpers/fake_client.dart';
import 'helpers/test_app.dart';

GoRouter shellAt(String location) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          for (final route in [
            '/home',
            '/libraries',
            '/search',
            '/favorites',
            '/downloads',
            '/settings'
          ])
            GoRoute(
                path: route,
                builder: (_, _) =>
                    Center(child: Text('page:$route'))),
          GoRoute(
              path: '/library/:id',
              builder: (_, state) =>
                  Center(child: Text('lib:${state.pathParameters['id']}'))),
          GoRoute(
              path: '/item/:id',
              builder: (_, state) =>
                  Center(child: Text('item:${state.pathParameters['id']}'))),
          GoRoute(
              path: '/profiles',
              builder: (_, _) => const Center(child: Text('profiles'))),
        ],
      ),
    ],
  );
  return router;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop shows sidebar with selected row', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final result = await TestHarness.create();
    result.harness.client.libraries = [
      makeItem(
          id: 'lib1',
          name: 'Movies',
          type: 'CollectionFolder',
          collectionType: 'movies',
          isFolder: true),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ],
      child: routedTestApp(router: shellAt('/home')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('page:/home'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('page:/search'), findsOneWidget);
  });

  testWidgets('mobile shows bottom navigation and drawer',
      (tester) async {
    tester.view.physicalSize = const Size(420, 880);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final result = await TestHarness.create();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...result.overrides,
        sessionProvider
            .overrideWith(() => FakeSessionNotifier(testSession())),
      ],
      child: routedTestApp(router: shellAt('/home')),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('page:/settings'), findsOneWidget);
  });

  testWidgets('title bar shows traffic lights and title',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(testApp(
        overrides: (await TestHarness.create()).overrides,
        child: const Scaffold(body: TitleBar(actions: null))));
    expect(find.text('Finar'), findsOneWidget);
    expect(find.bySemanticsLabel('close'), findsOneWidget);
    expect(find.bySemanticsLabel('minimize'), findsOneWidget);
    expect(find.bySemanticsLabel('maximize'), findsOneWidget);
  });

  testWidgets('mini player shows for audio and toggles play',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final result = await TestHarness.create();
    final container = ProviderContainer(overrides: [
      ...result.overrides,
      sessionProvider
          .overrideWith(() => FakeSessionNotifier(testSession())),
    ]);
    await container.read(playerProvider.notifier).playItem(
        makeItem(id: 'a1', name: 'Song', type: 'Audio',
            albumArtist: 'Artist'));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: routedTestApp(router: shellAt('/home')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Song'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.pause));
    expect(result.harness.backend.isPlaying, isFalse);
    await container.read(playerProvider.notifier).stop();
    container.dispose();
  });
}
