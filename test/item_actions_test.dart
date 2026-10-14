import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finar/providers/item_actions.dart';
import 'package:finar/providers/session_provider.dart';

import 'helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('setFavorite and setPlayed reach the client', () async {
    SharedPreferences.setMockInitialValues({});
    final result = await TestHarness.create();
    final container = ProviderContainer(overrides: [
      ...result.overrides,
      sessionProvider
          .overrideWith(() => FakeSessionNotifier(testSession())),
    ]);
    addTearDown(container.dispose);
    final actions = container.read(itemActionsProvider);
    final fav = await actions.setFavorite('i1', true);
    expect(fav.isFavorite, isTrue);
    expect(result.harness.client.favoriteCalls, 1);
    final played = await actions.setPlayed('i1', true);
    expect(played.played, isTrue);
    expect(result.harness.client.playedCalls, 1);
  });

  test('actions fail when signed out', () async {
    SharedPreferences.setMockInitialValues({});
    final result = await TestHarness.create(signedIn: false);
    final container = ProviderContainer(overrides: result.overrides);
    addTearDown(container.dispose);
    final actions = container.read(itemActionsProvider);
    expect(() => actions.setFavorite('i1', true),
        throwsA(isA<StateError>()));
  });
}
