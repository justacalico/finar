import 'package:finar/core/storage/settings_store.dart';
import 'package:finar/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const accent = 0xFFAA5CC3;

  test('light and dark themes differ in brightness', () {
    expect(AppTheme.light(accent).brightness, Brightness.light);
    expect(AppTheme.dark(accent).brightness, Brightness.dark);
  });

  test('oled theme is black', () {
    expect(AppTheme.oled(accent).scaffoldBackgroundColor, Colors.black);
  });

  test('accent colour feeds the color scheme', () {
    final theme = AppTheme.light(0xFF4F8FED);
    expect(theme.colorScheme.primary.computeLuminance(),
        isNot(equals(AppTheme.light(0xFFE0596B).colorScheme.primary.computeLuminance())));
  });

  test('resolve maps every theme mode', () {
    expect(
        AppTheme.resolve(AppThemeMode.system, accent, platformDark: true)
            .scaffoldBackgroundColor,
        AppTheme.dark(accent).scaffoldBackgroundColor);
    expect(
        AppTheme.resolve(AppThemeMode.system, accent, platformDark: false)
            .scaffoldBackgroundColor,
        AppTheme.light(accent).scaffoldBackgroundColor);
    expect(AppTheme.resolve(AppThemeMode.oled, accent, platformDark: false)
        .scaffoldBackgroundColor, Colors.black);
  });

  test('materialThemeMode maps to Material modes', () {
    expect(AppTheme.materialThemeMode(AppThemeMode.oled), ThemeMode.dark);
    expect(AppTheme.materialThemeMode(AppThemeMode.light), ThemeMode.light);
    expect(AppTheme.materialThemeMode(AppThemeMode.system), ThemeMode.system);
  });
}
