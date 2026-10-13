import 'package:finar/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatTicks renders hours and minutes', () {
    expect(formatTicks(72000000000), '2h 0m');
    expect(formatTicks(5400000000), '9m');
    expect(formatTicks(0), '0m');
  });

  test('formatDuration renders m:ss and h:mm:ss', () {
    expect(formatDuration(const Duration(minutes: 5, seconds: 4)),
        '05:04');
    expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03');
  });

  test('formatBytes renders human sizes', () {
    expect(formatBytes(512), '512 B');
    expect(formatBytes(2048), '2.0 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GB');
  });
}
