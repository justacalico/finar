import 'package:finar/core/storage/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults when nothing stored', () async {
    SharedPreferences.setMockInitialValues({});
    final store =
        SettingsStore(await SharedPreferences.getInstance());
    final settings = store.load();
    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.accentColor, 0xFFAA5CC3);
    expect(settings.locale, isNull);
  });

  test('round trips settings', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = SettingsStore(prefs);
    await store.save(const Settings(
        themeMode: AppThemeMode.oled,
        accentColor: 0xFF4F8FED,
        locale: 'zh'));
    final loaded = SettingsStore(prefs).load();
    expect(loaded.themeMode, AppThemeMode.oled);
    expect(loaded.accentColor, 0xFF4F8FED);
    expect(loaded.locale, 'zh');
  });

  test('clears locale back to system', () async {
    SharedPreferences.setMockInitialValues({'settings.locale': 'ru'});
    final prefs = await SharedPreferences.getInstance();
    final store = SettingsStore(prefs);
    await store.save(const Settings(locale: null));
    expect(store.load().locale, isNull);
  });
}
