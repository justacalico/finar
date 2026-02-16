import 'package:flutter/material.dart';

/// Finar color palette - Modern streaming app design
/// Inspired by premium streaming services with a refined dark theme
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Base colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  
  // Background colors - Refined deep dark mode
  static const Color background = Color(0xFF0D0D0F);
  static const Color backgroundSecondary = Color(0xFF141416);
  static const Color backgroundTertiary = Color(0xFF1A1A1E);
  static const Color surface = Color(0xFF1A1A1E);
  static const Color surfaceElevated = Color(0xFF242428);
  static const Color surfaceHighlight = Color(0xFF2E2E34);
  
  // Glass colors - Refined glassmorphism
  static const Color glassWhite = Color(0x14FFFFFF); // 8% white
  static const Color glassBorder = Color(0x28FFFFFF); // 16% white
  static const Color glassHighlight = Color(0x40FFFFFF); // 25% white
  static const Color glassDark = Color(0x14000000); // 8% black
  static const Color glassActive = Color(0x20FFFFFF); // 12% white for hover states
  
  // Primary colors - Refined teal with better contrast
  static const Color primary = Color(0xFF00E5B8);
  static const Color primaryLight = Color(0xFF5FFFDD);
  static const Color primaryDark = Color(0xFF00B894);
  static const Color primaryMuted = Color(0xFF00997A);
  
  // Secondary colors - Refined purple
  static const Color secondary = Color(0xFF9D7EF7);
  static const Color secondaryLight = Color(0xFFBDA4F9);
  static const Color secondaryDark = Color(0xFF7C5CE5);
  
  // Accent colors - For highlights and interactions
  static const Color accent = Color(0xFF00B8D9);
  static const Color accentPink = Color(0xFFFF6B9D);
  static const Color accentOrange = Color(0xFFFF9F43);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentRed = Color(0xFFFF6B6B);
  static const Color accentBlue = Color(0xFF5B8DEF);
  
  // Glass background for player and overlays
  static const Color glassBackground = Color(0xB3000000); // 70% black
  static const Color glassBackgroundLight = Color(0x66000000); // 40% black
  
  // Divider color
  static const Color divider = Color(0xFF2A2A2E);
  static const Color dividerLight = Color(0xFF3A3A3E);
  
  // Text colors - Improved hierarchy
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF707070);
  static const Color textDisabled = Color(0xFF4A4A4A);
  static const Color textOnPrimary = Color(0xFF0D0D0F);
  
  // Semantic colors - Refined
  static const Color success = Color(0xFF2DD4BF);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF5B8DEF);
  
  // Gradient colors - Refined
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );
  
  static const LinearGradient primarySoftGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5B8), Color(0xFF00B8D9)],
  );
  
  static const LinearGradient purplePinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, accentPink],
  );
  
  static const LinearGradient tealBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF0891B2)],
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x18FFFFFF),
      Color(0x08FFFFFF),
    ],
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1A1E),
      Color(0xFF0D0D0F),
    ],
  );
  
  // Hero gradient for featured content
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x40000000),
      Color(0xE6000000),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Overlay gradients for images
  static const LinearGradient imageOverlayTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xCC000000),
      Color(0x00000000),
    ],
    stops: [0.0, 0.5],
  );
  
  static const LinearGradient imageOverlayBottom = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0xE6000000),
    ],
    stops: [0.4, 1.0],
  );
  
  static const LinearGradient imageOverlayFull = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x4D000000),
      Color(0x00000000),
      Color(0xCC000000),
    ],
    stops: [0.0, 0.35, 1.0],
  );
  
  // Card overlay gradients
  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x80000000),
      Color(0xE6000000),
    ],
    stops: [0.3, 0.7, 1.0],
  );

  // Platform-specific adjustments
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // Shimmer colors for loading states
  static const Color shimmerBase = Color(0xFF1A1A1E);
  static const Color shimmerHighlight = Color(0xFF2A2A2E);
  
  // Skeleton loading colors
  static const Color skeletonBase = Color(0xFF242428);
  static const Color skeletonHighlight = Color(0xFF2E2E34);
}
