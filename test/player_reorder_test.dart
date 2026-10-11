import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden/fake_services.dart';
import 'golden/golden_fixtures.dart';

GoldenPlayerNotifier _notifier(List<MediaItem> playlist, int playlistIndex) {
  return GoldenPlayerNotifier(
    FakeMediaService(),
    FakeDownloadService(),
    PlayerState(
      currentItem: playlist[playlistIndex],
      playlist: playlist,
      playlistIndex: playlistIndex,
    ),
  );
}

List<String> _ids(PlayerNotifier notifier) =>
    notifier.state.playlist!.map((e) => e.id).toList();

void main() {
  final playlist = [
    goldenMovie('a', 'A'),
    goldenMovie('b', 'B'),
    goldenMovie('c', 'C'),
    goldenMovie('d', 'D'),
    goldenMovie('e', 'E'),
  ];

  group('reorderQueue', () {
    test('moving down inserts at the given post-removal index', () {
      final notifier = _notifier(playlist, 0);

      notifier.reorderQueue(1, 4);

      expect(_ids(notifier), ['a', 'c', 'd', 'e', 'b']);
      expect(notifier.state.playlistIndex, 0);
    });

    test('moving up inserts at the given post-removal index', () {
      final notifier = _notifier(playlist, 0);

      notifier.reorderQueue(4, 1);

      expect(_ids(notifier), ['a', 'e', 'b', 'c', 'd']);
      expect(notifier.state.playlistIndex, 0);
    });

    test('moving the current item tracks its new position', () {
      final notifier = _notifier(playlist, 1);

      notifier.reorderQueue(1, 4);

      expect(_ids(notifier), ['a', 'c', 'd', 'e', 'b']);
      expect(notifier.state.playlistIndex, 4);
    });

    test('current index shifts when items move across it', () {
      final notifier = _notifier(playlist, 3);

      notifier.reorderQueue(1, 4);

      expect(_ids(notifier), ['a', 'c', 'd', 'e', 'b']);
      expect(notifier.state.playlistIndex, 2);

      notifier.reorderQueue(4, 1);

      expect(_ids(notifier), ['a', 'b', 'c', 'd', 'e']);
      expect(notifier.state.playlistIndex, 3);
    });

    test('does nothing without a playlist', () {
      final notifier = GoldenPlayerNotifier(
        FakeMediaService(),
        FakeDownloadService(),
        const PlayerState(),
      );

      notifier.reorderQueue(0, 1);

      expect(notifier.state.playlist, isNull);
    });
  });
}
