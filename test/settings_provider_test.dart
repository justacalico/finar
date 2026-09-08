import 'package:finar/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings', () {
    test('serialises only accentColorIndex, not themeColorIndex', () {
      const settings = AppSettings(accentColorIndex: 2);
      final json = settings.toJson();

      expect(json['accentColorIndex'], 2);
      expect(json.containsKey('themeColorIndex'), false);
    });

    test('defaults accentColorIndex to 0', () {
      const settings = AppSettings();
      expect(settings.accentColorIndex, 0);
    });

    test('migrates old themeColorIndex to accentColorIndex', () {
      final settings = AppSettings.fromJson({'themeColorIndex': 3});

      expect(settings.accentColorIndex, 3);
    });

    test('prefers accentColorIndex when both old and new keys exist', () {
      final settings = AppSettings.fromJson({
        'accentColorIndex': 2,
        'themeColorIndex': 4,
      });

      expect(settings.accentColorIndex, 2);
    });
  });
}
