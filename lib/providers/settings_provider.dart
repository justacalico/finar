import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/settings_store.dart';
import 'core_providers.dart';

final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() => ref.watch(settingsStoreProvider).load();

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setAccentColor(int color) =>
      _update(state.copyWith(accentColor: color));

  Future<void> setLocale(String? locale) =>
      _update(state.copyWith(locale: () => locale));

  Future<void> _update(Settings next) async {
    state = next;
    await ref.read(settingsStoreProvider).save(next);
  }
}
