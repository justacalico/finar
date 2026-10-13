import 'package:flutter/material.dart';

import '../core/storage/settings_store.dart';

class AppTheme {
  static const accents = <int>[
    0xFFAA5CC3,
    0xFF4F8FED,
    0xFF38B58E,
    0xFFE8A33D,
    0xFFE0596B,
    0xFF8E7BF0,
  ];

  static ThemeData light(int accent) => _base(accent, Brightness.light);

  static ThemeData dark(int accent) => _base(accent, Brightness.dark);

  static ThemeData oled(int accent) => _base(accent, Brightness.dark).copyWith(
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xFF0A0A0A),
        dialogTheme:
            const DialogThemeData(backgroundColor: Color(0xFF0A0A0A)),
        drawerTheme:
            const DrawerThemeData(backgroundColor: Color(0xFF050505)),
      );

  static ThemeData _base(int accent, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Color(accent),
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor:
          dark ? const Color(0xFF10131A) : const Color(0xFFF6F7FA),
      cardTheme: const CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeMode materialThemeMode(AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.oled => ThemeMode.dark,
      };

  static ThemeData resolve(AppThemeMode mode, int accent,
          {required bool platformDark}) =>
      switch (mode) {
        AppThemeMode.system => platformDark ? dark(accent) : light(accent),
        AppThemeMode.light => light(accent),
        AppThemeMode.dark => dark(accent),
        AppThemeMode.oled => oled(accent),
      };
}
