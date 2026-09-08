import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/settings_provider.dart';

void main() {
  group('AppColors', () {
    test('follows light mode', () {
      AppColors.set(
        brightness: Brightness.light,
        themeStyle: ThemeStyle.standard,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      expect(AppColors.brightness, Brightness.light);
      expect(AppColors.background, const Color(0xFFF2F2F7));
      expect(AppColors.textPrimary, const Color(0xFF1C1C1E));
    });

    test('OLED style uses pure black', () {
      AppColors.set(
        brightness: Brightness.dark,
        themeStyle: ThemeStyle.oled,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      expect(AppColors.background, Colors.black);
      expect(AppColors.surface, Colors.black);
    });

    test('coloured style tints background with theme color', () {
      AppColors.set(
        brightness: Brightness.dark,
        themeStyle: ThemeStyle.coloured,
        themeColor: const Color(0xFFFF0000),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      expect(AppColors.background, isNot(Colors.black));
      expect(AppColors.background, isNot(const Color(0xFF0D0D0F)));
    });

    test('primary follows theme color', () {
      AppColors.set(
        brightness: Brightness.dark,
        themeStyle: ThemeStyle.standard,
        themeColor: const Color(0xFFFF0000),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      expect(AppColors.primary, const Color(0xFFFF0000));
      expect(AppColors.accent, const Color(0xFF00B8D9));
    });

    test('useSystemAccent uses accent color for primary', () {
      AppColors.set(
        brightness: Brightness.dark,
        themeStyle: ThemeStyle.standard,
        themeColor: const Color(0xFFFF0000),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: true,
      );

      expect(AppColors.primary, const Color(0xFF00B8D9));
    });

    test('light mode glass colors switch to dark tints', () {
      AppColors.set(
        brightness: Brightness.light,
        themeStyle: ThemeStyle.standard,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      expect(AppColors.glassWhite, const Color(0x14000000));
    });
  });

  group('AppTheme', () {
    test('dark theme uses AppColors', () {
      AppColors.set(
        brightness: Brightness.dark,
        themeStyle: ThemeStyle.standard,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      final theme = AppTheme.darkThemeWithPrimary(AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.colorScheme.surface, AppColors.surface);
      expect(theme.colorScheme.primary, AppColors.primary);
    });

    test('light theme uses AppColors', () {
      AppColors.set(
        brightness: Brightness.light,
        themeStyle: ThemeStyle.standard,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      final theme = AppTheme.lightThemeWithPrimary(AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.colorScheme.surface, AppColors.surface);
      expect(theme.colorScheme.primary, AppColors.primary);
    });
  });

  group('ColorExtension', () {
    test('toARGB32 encodes full color values', () {
      expect(const Color(0xFFFFFFFF).toARGB32(), 0xFFFFFFFF);
      expect(const Color(0xFFFF0000).toARGB32(), 0xFFFF0000);
      expect(const Color(0x80000000).toARGB32(), 0x80000000);
    });
  });
}
