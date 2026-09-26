import 'package:flutter/material.dart';

/// Design tokens shared by every screen. Spacing follows an 8pt grid.
class Insets {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class Radii {
  static const chip = 8.0;
  static const card = 12.0;
  static const sheet = 20.0;
}

/// Available accent colors shown in Settings > Appearance.
const kAccentOptions = <String, Color>{
  'System': Color(0xFF5E5CE6),
  'Blue': Color(0xFF0A84FF),
  'Teal': Color(0xFF64D2FF),
  'Green': Color(0xFF30D158),
  'Orange': Color(0xFFFF9F0A),
  'Pink': Color(0xFFFF375F),
  'Mono': Color(0xFFE8E8ED),
};

enum AppThemeMode { system, light, dark, oled }

AppThemeMode themeModeFromName(String? name) => switch (name) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      'oled' => AppThemeMode.oled,
      _ => AppThemeMode.system,
    };

extension AppThemeModeName on AppThemeMode {
  String get label => switch (this) {
        AppThemeMode.system => 'System',
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
        AppThemeMode.oled => 'OLED',
      };
}

class AppTheme {
  static ColorScheme scheme(Brightness brightness, Color accent,
      {bool oled = false}) {
    if (brightness == Brightness.light) {
      return ColorScheme.light(
        primary: accent == kAccentOptions['Mono']
            ? const Color(0xFF3A3A3C)
            : accent,
        surface: Colors.white,
        onSurface: const Color(0xFF1D1D1F),
        surfaceContainerHighest: const Color(0xFFF5F5F7),
        outline: const Color(0x22000000),
      );
    }
    final bg = oled ? Colors.black : const Color(0xFF0E0E13);
    return ColorScheme.dark(
      primary: accent,
      surface: bg,
      onSurface: const Color(0xFFF5F5F7),
      surfaceContainerHighest:
          oled ? const Color(0xFF141416) : const Color(0xFF1A1A21),
      outline: const Color(0x1FFFFFFF),
    );
  }

  static ThemeData build(Brightness brightness, Color accent,
      {bool oled = false}) {
    final scheme = AppTheme.scheme(brightness, accent, oled: oled);
    final onSurface = scheme.onSurface;
    final secondary = onSurface.withValues(alpha: 0.62);
    final tertiary = onSurface.withValues(alpha: 0.42);

    final textTheme = TextTheme(
      displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.19,
          color: onSurface),
      headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: onSurface),
      titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: onSurface),
      titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: onSurface),
      titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: onSurface),
      bodyLarge: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w400, height: 1.47, color: onSurface),
      bodyMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w400, height: 1.43, color: onSurface),
      bodySmall: TextStyle(fontSize: 13, height: 1.38, color: secondary),
      labelLarge: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
      labelMedium: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: secondary),
      labelSmall: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500, color: tertiary),
    );

    final dark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(
          color: scheme.outline, thickness: 0.5, space: 0.5),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: scheme.outline, width: dark ? 0.5 : 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size(40, 40),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: tertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: onSurface,
        iconColor: secondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minTileHeight: 48,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: Colors.white,
        inactiveTrackColor: onSurface.withValues(alpha: 0.15),
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: scheme.primary),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sheet)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outline),
        ),
        textStyle: textTheme.bodySmall,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: tertiary),
        selectedLabelTextStyle: TextStyle(
            color: scheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: tertiary, fontSize: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: onSurface)),
        labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onSurface)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: secondary,
        indicatorColor: scheme.primary,
        labelStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      switchTheme: SwitchThemeData(
        thumbColor:
            const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : onSurface.withValues(alpha: 0.2)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primary.withValues(alpha: 0.25),
        side: BorderSide(color: scheme.outline),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.chip)),
      ),
    );
  }
}
