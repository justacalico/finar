import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/storage/settings_store.dart';
import 'package:finar/providers/core_providers.dart';
import 'package:finar/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('updates and persists theme, accent, locale', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
    final notifier = container.read(settingsProvider.notifier);
    await notifier.setThemeMode(AppThemeMode.dark);
    await notifier.setAccentColor(0xFF4F8FED);
    await notifier.setLocale('ga');
    final state = container.read(settingsProvider);
    expect(state.themeMode, AppThemeMode.dark);
    expect(state.accentColor, 0xFF4F8FED);
    expect(state.locale, 'ga');
    expect(SettingsStore(prefs).load().locale, 'ga');
    await notifier.setLocale(null);
    expect(container.read(settingsProvider).locale, isNull);
  });
}
