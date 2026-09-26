import 'dart:math';

import 'package:finar/core/api/models.dart';
import 'package:finar/providers/audio_provider.dart';
import 'package:flutter_test/flutter_test.dart';

MediaItem track(String id) => MediaItem(id: id, name: 'T$id');

void main() {
  final tracks = [for (var i = 0; i < 5; i++) track('$i')];

  group('PlayQueue', () {
    test('empty queue is safe', () {
      final q = PlayQueue(const [], 0);
      expect(q.isEmpty, isTrue);
      expect(q.current, isNull);
      expect(q.hasNext, isFalse);
    });

    test('start index clamps', () {
      final q = PlayQueue(tracks, 99);
      expect(q.current?.id, '4');
    });

    test('linear advance and back', () {
      var q = PlayQueue(tracks, 0);
      expect(q.hasNext, isTrue);
      expect(q.hasPrevious, isFalse);
      q = q.advance().advance();
      expect(q.current?.id, '2');
      q = q.back();
      expect(q.current?.id, '1');
    });

    test('advance stops at the end', () {
      var q = PlayQueue(tracks, 4);
      expect(q.hasNext, isFalse);
      q = q.advance();
      expect(q.current?.id, '4');
    });

    test('shuffle visits every track once', () {
      var q = PlayQueue(tracks, 0, shuffle: true, random: Random(1));
      final seen = <String>{q.current!.id};
      while (q.hasNext) {
        q = q.advance();
        seen.add(q.current!.id);
      }
      expect(seen.length, tracks.length);
    });

    test('shuffle toggle restores linear order', () {
      var q = PlayQueue(tracks, 2, shuffle: true, random: Random(2));
      expect(q.shuffle, isTrue);
      q = q.toggleShuffle();
      expect(q.shuffle, isFalse);
      expect(q.current?.id, '2');
      expect(q.nextIndex(), 3);
    });

    test('previous on first shuffled track returns null', () {
      final q = PlayQueue(tracks, 0, shuffle: true, random: Random(3));
      expect(q.previousIndex(), isNull);
    });

    test('jumpTo validates range', () {
      var q = PlayQueue(tracks, 0);
      q = q.jumpTo(3);
      expect(q.current?.id, '3');
      q = q.jumpTo(-1);
      expect(q.current?.id, '3');
      q = q.jumpTo(99);
      expect(q.current?.id, '3');
    });
  });
}
