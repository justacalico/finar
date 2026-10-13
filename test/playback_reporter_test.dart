import 'package:fake_async/fake_async.dart';
import 'package:finar/core/playback/playback_reporter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_client.dart';

void main() {
  test('reports start, progress and stop', () {
    fakeAsync((async) {
      final client = FakeJellyfinClient();
      final reporter = PlaybackReporter(client);
      final item = makeItem();
      reporter.start(item);
      reporter.updatePosition(const Duration(seconds: 5));
      async.elapse(const Duration(seconds: 21));
      reporter.stop();
      expect(client.playbackEvents.first, 'start:item1');
      expect(
          client.playbackEvents
              .where((e) => e == 'progress:item1')
              .length,
          2);
      expect(client.playbackEvents.last, 'stop:item1');
    });
  });

  test('stopping twice reports once', () {
    fakeAsync((async) {
      final client = FakeJellyfinClient();
      final reporter = PlaybackReporter(client);
      reporter.start(makeItem());
      reporter.stop();
      reporter.stop();
      expect(
          client.playbackEvents
              .where((e) => e.startsWith('stop'))
              .length,
          1);
    });
  });

  test('starting a new item stops reporting the old', () {
    fakeAsync((async) {
      final client = FakeJellyfinClient();
      final reporter = PlaybackReporter(client);
      reporter.start(makeItem(id: 'a'));
      reporter.start(makeItem(id: 'b'));
      reporter.stop();
      expect(client.playbackEvents, [
        'start:a',
        'stop:a',
        'start:b',
        'stop:b',
      ]);
    });
  });
}
