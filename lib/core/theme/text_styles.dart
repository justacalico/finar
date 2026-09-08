import 'package:flutter/material.dart';
import 'colors.dart';

/// Text styles - Modern streaming app typography
/// Optimized for readability across all screen sizes
class AppTextStyles {
  // Private constructor
  AppTextStyles._();

  // Font family - System fonts for native feel, fallback to Inter
  static const String fontFamily = 'Inter';
  static const String textFontFamily = 'Inter';

  // Display styles - Large headlines for hero sections
  static TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    color: AppColors.textPrimary,
    height: 1.1,
    decoration: TextDecoration.none,
  );

  static TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.14,
    decoration: TextDecoration.none,
  );

  static TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
    height: 1.2,
    decoration: TextDecoration.none,
  );

  // Headline styles
  static TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.25,
    decoration: TextDecoration.none,
  );

  static TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.29,
    decoration: TextDecoration.none,
  );

  static TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  // Title styles
  static TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.27,
    decoration: TextDecoration.none,
  );

  static TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
    height: 1.5,
    decoration: TextDecoration.none,
  );

  static TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
    height: 1.43,
    decoration: TextDecoration.none,
  );

  // Body styles
  static TextStyle bodyLarge = TextStyle(
    fontFamily: textFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    height: 1.5,
    decoration: TextDecoration.none,
  );

  static TextStyle bodyMedium = TextStyle(
    fontFamily: textFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
    height: 1.43,
    decoration: TextDecoration.none,
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: textFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  // Label styles
  static TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
    height: 1.43,
    decoration: TextDecoration.none,
  );

  static TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  static TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
    height: 1.45,
    decoration: TextDecoration.none,
  );

  // Custom styles for Finar
  static TextStyle hero = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.1,
    decoration: TextDecoration.none,
  );

  static TextStyle subtitle = TextStyle(
    fontFamily: textFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    height: 1.4,
    decoration: TextDecoration.none,
  );

  static TextStyle caption = TextStyle(
    fontFamily: textFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textTertiary,
    height: 1.38,
    decoration: TextDecoration.none,
  );

  static TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    color: AppColors.textPrimary,
    height: 1.3,
    decoration: TextDecoration.none,
  );

  static TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24,
    color: AppColors.textPrimary,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  static TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.25,
    decoration: TextDecoration.none,
  );

  static TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    height: 1.2,
    decoration: TextDecoration.none,
  );

  static TextStyle rating = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.accentYellow,
    height: 1.2,
    decoration: TextDecoration.none,
  );

  static TextStyle metadata = TextStyle(
    fontFamily: textFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    height: 1.38,
    decoration: TextDecoration.none,
  );

  static TextStyle playerTime = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
    decoration: TextDecoration.none,
  );

  // Helper methods
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
}
