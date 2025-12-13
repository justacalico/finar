import 'package:flutter/material.dart';

/// Finar color palette inspired by iOS 26 liquid glass design
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Base colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  
  // Background colors - Deep dark mode
  static const Color background = Color(0xFF0A0A0A);
  static const Color backgroundSecondary = Color(0xFF121212);
  static const Color backgroundTertiary = Color(0xFF1C1C1E);
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceElevated = Color(0xFF2C2C2E);
  
  // Glass colors - For glassmorphism effects
  static const Color glassWhite = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white
  static const Color glassHighlight = Color(0x4DFFFFFF); // 30% white
  static const Color glassDark = Color(0x1A000000); // 10% black
  
  // Primary colors - Vibrant teal/blue
  static const Color primary = Color(0xFF00D4AA);
  static const Color primaryLight = Color(0xFF5DFFDB);
  static const Color primaryDark = Color(0xFF00A67C);
  
  // Secondary colors - Purple accent
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryLight = Color(0xFFB794F6);
  static const Color secondaryDark = Color(0xFF6B21A8);
  
  // Accent colors - For highlights and interactions
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentYellow = Color(0xFFFBBF24);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textTertiary = Color(0xFF666666);
  static const Color textDisabled = Color(0xFF444444);
  
  // Semantic colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
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
      Color(0x20FFFFFF),
      Color(0x10FFFFFF),
    ],
  );
  
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1C1C1E),
      Color(0xFF0A0A0A),
    ],
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
      Color(0xCC000000),
    ],
    stops: [0.5, 1.0],
  );
  
  static const LinearGradient imageOverlayFull = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x66000000),
      Color(0x00000000),
      Color(0xB3000000),
    ],
    stops: [0.0, 0.4, 1.0],
  );

  // Platform-specific adjustments
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  // Shimmer colors for loading states
  static const Color shimmerBase = Color(0xFF1C1C1E);
  static const Color shimmerHighlight = Color(0xFF2C2C2E);
}
