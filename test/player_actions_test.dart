import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finar/core/models/models.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:finar/providers/session_provider.dart';

import 'helpers/fake_backend.dart';
import 'helpers/fake_client.dart';
import 'helpers/secure_storage_mock.dart';
import 'helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ProviderContainer, FakePlayerBackend, TestHarness)>
      makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    final result = await TestHarness.create();
    final c = ProviderContainer(overrides: [
      ...result.overrides,
      sessionProvider
          .overrideWith(() => FakeSessionNotifier(testSession())),
    ]);
    addTearDown(c.dispose);
    return (c, result.harness.backend, result.harness);
  }

  test('seek, volume, rate and toggle reach the backend', () async {
    final (c, backend, _) = await makeContainer();
    final notifier = c.read(playerProvider.notifier);
    await notifier.playItem(makeItem(
        id: 'v1', type: 'Audio'));
    await notifier.seek(const Duration(seconds: 42));
    expect(backend.currentPosition, const Duration(seconds: 42));
    await pumpEventQueue();
    await notifier.seekBy(const Duration(seconds: -2));
    expect(backend.currentPosition, const Duration(seconds: 40));
    await notifier.setVolume(0.4);
    expect(backend.currentVolume, 0.4);
    await notifier.setRate(1.5);
    expect(backend.currentRate, 1.5);
    await notifier.toggle();
    expect(backend.isPlaying, isFalse);
    await notifier.toggle();
    expect(backend.isPlaying, isTrue);
  });

  test('queue navigation tracks index', () async {
    final (c, _, harness) = await makeContainer();
    final notifier = c.read(playerProvider.notifier);
    final queue = [
      makeItem(id: 'a', type: 'Audio', name: 'A'),
      makeItem(id: 'b', type: 'Audio', name: 'B'),
      makeItem(id: 'd', type: 'Audio', name: 'D'),
    ];
    await notifier.playQueue(queue, 1);
    expect(c.read(playerProvider).item!.id, 'b');
    await notifier.next();
    expect(c.read(playerProvider).item!.id, 'd');
    await notifier.previous();
    expect(c.read(playerProvider).item!.id, 'b');
    await notifier.previous();
    expect(c.read(playerProvider).item!.id, 'a');
  });

  test('completing the last item stops playback', () async {
    final (c, backend, _) = await makeContainer();
    final notifier = c.read(playerProvider.notifier);
    await notifier.playItem(makeItem(id: 'a', type: 'Audio'));
    backend.emitCompleted();
    await pumpEventQueue();
    expect(c.read(playerProvider).playing, isFalse);
  });

  test('completing an item auto-advances the queue', () async {
    final (c, backend, _) = await makeContainer();
    final notifier = c.read(playerProvider.notifier);
    final queue = [
      makeItem(id: 'a', type: 'Audio'),
      makeItem(id: 'b', type: 'Audio'),
    ];
    await notifier.playQueue(queue, 0);
    backend.emitCompleted();
    await pumpEventQueue();
    expect(c.read(playerProvider).item!.id, 'b');
  });

  test('track pickers update state', () async {
    final (c, _, harness) = await makeContainer();
    final notifier = c.read(playerProvider.notifier);
    await notifier.playItem(makeItem(id: 'm1', type: 'Movie'));
    expect(c.read(playerProvider).subtitleTracks, isNotEmpty);
    expect(c.read(playerProvider).audioTracks, isNotEmpty);
    await notifier.selectSubtitle(2);
    expect(c.read(playerProvider).subtitleTrack, 2);
    await notifier.selectSubtitle(null);
    expect(c.read(playerProvider).subtitleTrack, isNull);
    await notifier.selectAudio(1);
    expect(c.read(playerProvider).audioTrack, 1);
  });

  test('signed-out playItem falls back to a blank uri', () async {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    final result = await TestHarness.create(signedIn: false);
    final c = ProviderContainer(overrides: result.overrides);
    addTearDown(c.dispose);
    await c.read(playerProvider.notifier).playItem(makeItem(id: 'x'));
    expect(result.harness.backend.lastUri, Uri.parse('about:blank'));
  });

  test('item-level media streams feed the track lists', () async {
    final (c, _, harness) = await makeContainer();
    final notifier = c.read(playerProvider.notifier);
    final item = BaseItem.fromJson({
      'Id': 'm2',
      'Name': 'Clip',
      'Type': 'Movie',
      'MediaStreams': [
        {'Index': 5, 'Type': 'Audio', 'DisplayTitle': 'DTS'},
        {'Index': 6, 'Type': 'Subtitle', 'DisplayTitle': 'Subs'},
      ],
    });
    await notifier.playItem(item);
    expect(
        c.read(playerProvider).audioTracks.map((t) => t.index),
        contains(5));
    expect(
        c.read(playerProvider).subtitleTracks.map((t) => t.index),
        contains(6));
  });

  test('resume position feeds startAt', () async {
    final (c, backend, harness) = await makeContainer();
    final notifier = c.read(playerProvider.notifier);
    await notifier.playItem(
        makeItem(id: 'r1', type: 'Audio', positionTicks: 420000000));
    expect(backend.currentPosition, const Duration(seconds: 42));
  });

  test('local file playback bypasses stream url', () async {
    final (c, backend, _) = await makeContainer();
    final notifier = c.read(playerProvider.notifier);
    await notifier.playItem(makeItem(id: 'x', type: 'Audio'),
        localFile: '/tmp/song.mp3');
    expect(backend.lastUri, Uri.file('/tmp/song.mp3'));
    expect(c.read(playerProvider).localFile, '/tmp/song.mp3');
  });
}
