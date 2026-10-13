import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:finar/providers/core_providers.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_backend.dart';
import 'helpers/fake_client.dart';
import 'helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakePlayerBackend backend;
  late FakeJellyfinClient client;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final result = await TestHarness.create();
    backend = result.harness.backend;
    client = result.harness.client;
    container = ProviderContainer(overrides: [
      ...result.overrides,
      sharedPrefsProvider.overrideWithValue(
          await SharedPreferences.getInstance()),
      sessionProvider
          .overrideWith(() => FakeSessionNotifier(testSession())),
    ]);
    addTearDown(container.dispose);
  });

  test('playItem opens stream and updates state', () async {
    final notifier = container.read(playerProvider.notifier);
    final item = makeItem(id: 'm1', name: 'Movie');
    await notifier.playItem(item);
    expect(backend.opened, isTrue);
    expect(backend.lastUri.toString(),
        'http://test.local/stream/m1');
    expect(container.read(playerProvider).item!.id, 'm1');
    expect(client.playbackEvents, contains('start:m1'));
  });

  test('toggle pauses and resumes', () async {
    final notifier = container.read(playerProvider.notifier);
    await notifier.playItem(makeItem());
    await notifier.toggle();
    expect(backend.isPlaying, isFalse);
    await notifier.toggle();
    expect(backend.isPlaying, isTrue);
  });

  test('seek and volume forward to backend', () async {
    final notifier = container.read(playerProvider.notifier);
    await notifier.playItem(makeItem());
    await notifier.seek(const Duration(minutes: 4));
    expect(backend.currentPosition, const Duration(minutes: 4));
    await notifier.setVolume(40);
    expect(backend.currentVolume, 40);
    await notifier.setRate(1.5);
    expect(backend.currentRate, 1.5);
  });

  test('track selection forwards stream indexes', () async {
    final notifier = container.read(playerProvider.notifier);
    await notifier.playItem(makeItem());
    await notifier.selectSubtitle(2);
    expect(backend.lastSubtitle, 2);
    await notifier.selectAudio(1);
    expect(backend.lastAudio, 1);
    await notifier.selectSubtitle(null);
    expect(backend.lastSubtitle, isNull);
  });

  test('queue advances on completion', () async {
    final notifier = container.read(playerProvider.notifier);
    final queue = [makeItem(id: 't1', name: 'One'), makeItem(id: 't2', name: 'Two')];
    await notifier.playQueue(queue, 0);
    expect(container.read(playerProvider).queueIndex, 0);
    backend.emitCompleted();
    await pumpEventQueue();
    expect(container.read(playerProvider).item!.id, 't2');
    expect(container.read(playerProvider).queueIndex, 1);
    backend.emitCompleted();
    await pumpEventQueue();
    expect(container.read(playerProvider).playing, isFalse);
  });

  test('local files bypass stream url', () async {
    final notifier = container.read(playerProvider.notifier);
    await notifier.playItem(makeItem(),
        localFile: '/tmp/movie.mkv');
    expect(backend.lastUri.toString(), 'file:///tmp/movie.mkv');
    expect(container.read(playerProvider).localFile,
        '/tmp/movie.mkv');
  });

  test('stop clears state and reports stop', () async {
    final notifier = container.read(playerProvider.notifier);
    await notifier.playItem(makeItem(id: 'm1'));
    await notifier.stop();
    expect(container.read(playerProvider).item, isNull);
    expect(client.playbackEvents.last, 'stop:m1');
  });
}
