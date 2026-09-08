import 'package:flutter/material.dart';
import '../../providers/settings_provider.dart';

/// Finar color palette, now reactive to theme settings.
///
/// Call [AppColors.set] from [app.dart] with the current brightness/style
/// before building [MaterialApp] so the rest of the UI uses the right colors.
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.dark;
  static bool _oled = false;
  static Color _themeColor = accentColorOptions[0].$3;
  static Color _accentColor = accentColorOptions[0].$3;
  static bool _useSystemAccent = false;

  /// Called once per build to sync the static palette with the user's settings.
  static void set({
    Brightness? brightness,
    bool? oled,
    Color? themeColor,
    Color? accentColor,
    bool? useSystemAccent,
  }) {
    if (brightness != null) _brightness = brightness;
    if (oled != null) _oled = oled;
    if (themeColor != null) _themeColor = themeColor;
    if (accentColor != null) _accentColor = accentColor;
    if (useSystemAccent != null) _useSystemAccent = useSystemAccent;
  }

  static bool get _isLight => _brightness == Brightness.light;

  /// The current brightness the palette is configured for.
  static Brightness get brightness => _brightness;

  // Base colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Background colors
  static Color get background {
    if (_isLight) return const Color(0xFFF2F2F7);
    return _oled ? Colors.black : const Color(0xFF0D0D0F);
  }

  static Color get backgroundSecondary {
    if (_isLight) return const Color(0xFFFFFFFF);
    return _oled ? Colors.black : const Color(0xFF141416);
  }

  static Color get backgroundTertiary {
    if (_isLight) return const Color(0xFFE5E5EA);
    return _oled ? Colors.black : const Color(0xFF1A1A1E);
  }

  static Color get surface {
    if (_isLight) return const Color(0xFFF5F5F7);
    return _oled ? Colors.black : const Color(0xFF1A1A1E);
  }

  static Color get surfaceElevated {
    if (_isLight) return const Color(0xFFFFFFFF);
    return _oled ? const Color(0xFF0A0A0A) : const Color(0xFF242428);
  }

  static Color get surfaceHighlight {
    if (_isLight) return const Color(0xFFF2F2F7);
    return _oled ? const Color(0xFF141414) : const Color(0xFF2E2E34);
  }

  // Glass colors - white on dark UI, black on light UI
  static Color get glassWhite =>
      _isLight ? const Color(0x14000000) : const Color(0x14FFFFFF);

  static Color get glassBorder =>
      _isLight ? const Color(0x28000000) : const Color(0x28FFFFFF);

  static Color get glassHighlight =>
      _isLight ? const Color(0x40000000) : const Color(0x40FFFFFF);

  static Color get glassDark =>
      _isLight ? const Color(0x14FFFFFF) : const Color(0x14000000);

  static Color get glassActive =>
      _isLight ? const Color(0x20000000) : const Color(0x20FFFFFF);

  // Primary - theme color, optionally overridden by accent when using "system accent"
  static Color get primary =>
      _useSystemAccent ? _accentColor : _themeColor;

  static Color get primaryLight {
    final base = primary;
    return Color.alphaBlend(
      white.withValues(alpha: 0.35),
      base,
    );
  }

  static Color get primaryDark {
    final base = primary;
    return Color.alphaBlend(
      black.withValues(alpha: 0.3),
      base,
    );
  }

  static Color get primaryMuted {
    final base = primary;
    return Color.alphaBlend(
      _isLight ? white.withValues(alpha: 0.5) : black.withValues(alpha: 0.35),
      base,
    );
  }

  // Secondary - kept as purple
  static const Color secondary = Color(0xFF9D7EF7);

  static Color get secondaryLight {
    return Color.alphaBlend(
      white.withValues(alpha: 0.25),
      secondary,
    );
  }

  static Color get secondaryDark {
    return Color.alphaBlend(
      black.withValues(alpha: 0.25),
      secondary,
    );
  }

  // Accent colors
  static Color get accent => _accentColor;

  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentOrange = Color(0xFFFF9F43);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentRed = Color(0xFFFF6B6B);
  static const Color accentBlue = Color(0xFF5B8DEF);

  // Glass background for player and overlays
  static Color get glassBackground =>
      _isLight ? const Color(0xB3FFFFFF) : const Color(0xB3000000);

  static Color get glassBackgroundLight =>
      _isLight ? const Color(0x66FFFFFF) : const Color(0x66000000);

  // Divider color
  static Color get divider =>
      _isLight ? const Color(0xFFE5E5EA) : const Color(0xFF2A2A2E);

  static Color get dividerLight =>
      _isLight ? const Color(0xFFF2F2F7) : const Color(0xFF3A3A3E);

  // Text colors
  static Color get textPrimary =>
      _isLight ? const Color(0xFF1C1C1E) : const Color(0xFFFAFAFA);

  static Color get textSecondary =>
      _isLight ? const Color(0xFF636366) : const Color(0xFFB0B0B0);

  static Color get textTertiary =>
      _isLight ? const Color(0xFF8E8E93) : const Color(0xFF707070);

  static Color get textDisabled =>
      _isLight ? const Color(0xFFC6C6C8) : const Color(0xFF4A4A4A);

  static Color get textOnPrimary {
    final base = primary;
    return ThemeData.estimateBrightnessForColor(base) == Brightness.light
        ? black
        : white;
  }

  // Semantic colors
  static const Color success = Color(0xFF2DD4BF);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF5B8DEF);

  // Gradient colors
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static LinearGradient get primarySoftGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accentBlue],
  );

  static const LinearGradient purplePinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9D7EF7), Color(0xFFFF6B9D)],
  );

  static LinearGradient get tealBlueGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, const Color(0xFF0891B2)],
  );

  static LinearGradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _isLight
        ? [const Color(0x18000000), const Color(0x08000000)]
        : [const Color(0x18FFFFFF), const Color(0x08FFFFFF)],
  );

  static LinearGradient get surfaceGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, background],
  );

  // Hero gradient for featured content
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x40000000), Color(0xE6000000)],
    stops: [0.0, 0.5, 1.0],
  );

  // Overlay gradients for images
  static const LinearGradient imageOverlayTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xCC000000), Color(0x00000000)],
    stops: [0.0, 0.5],
  );

  static const LinearGradient imageOverlayBottom = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0xE6000000)],
    stops: [0.4, 1.0],
  );

  static const LinearGradient imageOverlayFull = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x4D000000), Color(0x00000000), Color(0xCC000000)],
    stops: [0.0, 0.35, 1.0],
  );

  // Card overlay gradients
  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x80000000), Color(0xE6000000)],
    stops: [0.3, 0.7, 1.0],
  );

  // Platform-specific adjustments
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // Shimmer colors
  static Color get shimmerBase =>
      _isLight ? const Color(0xFFE5E5EA) : const Color(0xFF1A1A1E);

  static Color get shimmerHighlight =>
      _isLight ? const Color(0xFFF2F2F7) : const Color(0xFF2A2A2E);

  // Skeleton loading colors
  static Color get skeletonBase =>
      _isLight ? const Color(0xFFE5E5EA) : const Color(0xFF242428);

  static Color get skeletonHighlight =>
      _isLight ? const Color(0xFFF2F2F7) : const Color(0xFF2E2E34);
}
