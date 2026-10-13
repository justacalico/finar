import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark, oled }

class Settings {
  const Settings({
    this.themeMode = AppThemeMode.system,
    this.accentColor = 0xFFAA5CC3,
    this.locale,
  });

  final AppThemeMode themeMode;
  final int accentColor;
  final String? locale;

  Settings copyWith(
          {AppThemeMode? themeMode,
          int? accentColor,
          String? Function()? locale}) =>
      Settings(
        themeMode: themeMode ?? this.themeMode,
        accentColor: accentColor ?? this.accentColor,
        locale: locale != null ? locale() : this.locale,
      );
}

class SettingsStore {
  const SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kTheme = 'settings.theme';
  static const _kAccent = 'settings.accent';
  static const _kLocale = 'settings.locale';

  Settings load() {
    final themeName = _prefs.getString(_kTheme);
    return Settings(
      themeMode: AppThemeMode.values
          .where((m) => m.name == themeName)
          .firstOrNull ??
          AppThemeMode.system,
      accentColor: _prefs.getInt(_kAccent) ?? 0xFFAA5CC3,
      locale: _prefs.getString(_kLocale),
    );
  }

  Future<void> save(Settings settings) async {
    await _prefs.setString(_kTheme, settings.themeMode.name);
    await _prefs.setInt(_kAccent, settings.accentColor);
    if (settings.locale == null) {
      await _prefs.remove(_kLocale);
    } else {
      await _prefs.setString(_kLocale, settings.locale!);
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
