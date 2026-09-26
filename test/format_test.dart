import 'package:finar/core/api/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ticksToDuration / durationToTicks', () {
    test('converts seconds correctly', () {
      expect(ticksToDuration(10_000_000), const Duration(seconds: 1));
      expect(ticksToDuration(600_000_000), const Duration(minutes: 1));
      expect(ticksToDuration(null), Duration.zero);
      expect(ticksToDuration(0), Duration.zero);
    });

    test('round trips', () {
      const d = Duration(hours: 1, minutes: 23, seconds: 45);
      expect(ticksToDuration(durationToTicks(d)), d);
    });
  });

  group('formatRuntime', () {
    test('empty for null or zero', () {
      expect(formatRuntime(null), '');
      expect(formatRuntime(0), '');
    });

    test('minutes only under an hour', () {
      expect(formatRuntime(45 * 60 * 10_000_000), '45m');
    });

    test('hours and minutes', () {
      expect(formatRuntime(95 * 60 * 10_000_000), '1h 35m');
      expect(formatRuntime(120 * 60 * 10_000_000), '2h 0m');
    });
  });

  group('formatDuration', () {
    test('formats mm:ss', () {
      expect(formatDuration(const Duration(minutes: 5, seconds: 7)), '5:07');
      expect(formatDuration(Duration.zero), '0:00');
    });

    test('formats h:mm:ss', () {
      expect(
        formatDuration(const Duration(hours: 2, minutes: 3, seconds: 4)),
        '2:03:04',
      );
    });

    test('negative durations get a sign', () {
      expect(formatDuration(const Duration(seconds: -30)), '-0:30');
    });
  });

  group('formatBytes', () {
    test('empty for null and zero', () {
      expect(formatBytes(null), '');
      expect(formatBytes(0), '');
    });

    test('picks the right unit', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(2048), '2.0 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GB');
    });
  });
}
