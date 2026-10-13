import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/providers/update_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:finar/core/update/version_checker.dart';

void main() {
  test('check surfaces available update', () async {
    final checker = UpdateChecker(
        client: MockClient((_) async =>
            http.Response('[{"tag_name":"v9.9.9"}]', 200)));
    final container = ProviderContainer(overrides: [
      updateCheckerProvider.overrideWithValue(checker),
    ]);
    addTearDown(container.dispose);
    await container.read(updateProvider.notifier).check('6.0.0');
    final state = container.read(updateProvider);
    expect(state, isA<UpdateAvailable>());
    expect((state as UpdateAvailable).update.tag, 'v9.9.9');
  });

  test('check reports up to date', () async {
    final checker = UpdateChecker(
        client: MockClient((_) async =>
            http.Response('[{"tag_name":"v5.0.0"}]', 200)));
    final container = ProviderContainer(overrides: [
      updateCheckerProvider.overrideWithValue(checker),
    ]);
    addTearDown(container.dispose);
    await container.read(updateProvider.notifier).check('6.0.0');
    expect(container.read(updateProvider), isA<UpdateUpToDate>());
  });

  test('check reports failure', () async {
    final checker = UpdateChecker(
        client: MockClient((_) async => http.Response('', 500)));
    final container = ProviderContainer(overrides: [
      updateCheckerProvider.overrideWithValue(checker),
    ]);
    addTearDown(container.dispose);
    await container.read(updateProvider.notifier).check('6.0.0');
    expect(container.read(updateProvider), isA<UpdateFailed>());
  });
}
