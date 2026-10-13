import 'package:finar/core/utils/version_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Version.tryParse', () {
    test('parses plain semver', () {
      expect(Version.tryParse('1.2.3'), const Version(1, 2, 3));
    });

    test('parses v-prefixed tags', () {
      expect(Version.tryParse('v6.0.0'), const Version(6, 0, 0));
      expect(Version.tryParse('V6.0.0'), const Version(6, 0, 0));
    });

    test('strips build metadata and prerelease', () {
      expect(Version.tryParse('6.0.0+42'), const Version(6, 0, 0));
      expect(Version.tryParse('6.0.0-rc1'), const Version(6, 0, 0));
    });

    test('rejects invalid input', () {
      expect(Version.tryParse('nightly'), isNull);
      expect(Version.tryParse('1.2'), isNull);
      expect(Version.tryParse('1.2.x'), isNull);
      expect(Version.tryParse(''), isNull);
    });
  });

  group('Version.compareTo', () {
    test('orders by major, minor, patch', () {
      expect(const Version(2, 0, 0)
          .isNewerThan(const Version(1, 9, 9)), isTrue);
      expect(const Version(1, 2, 0)
          .isNewerThan(const Version(1, 1, 9)), isTrue);
      expect(const Version(1, 1, 5)
          .isNewerThan(const Version(1, 1, 4)), isTrue);
      expect(const Version(1, 1, 4)
          .isNewerThan(const Version(1, 1, 4)), isFalse);
    });
  });
}
