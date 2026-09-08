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
  static TextStyle get displayLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    color: AppColors.textPrimary,
    height: 1.1,
    decoration: TextDecoration.none,
  );

  static TextStyle get displayMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.14,
    decoration: TextDecoration.none,
  );

  static TextStyle get displaySmall => TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
    height: 1.2,
    decoration: TextDecoration.none,
  );

  // Headline styles
  static TextStyle get headlineLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.25,
    decoration: TextDecoration.none,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.29,
    decoration: TextDecoration.none,
  );

  static TextStyle get headlineSmall => TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  // Title styles
  static TextStyle get titleLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
    height: 1.27,
    decoration: TextDecoration.none,
  );

  static TextStyle get titleMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
    height: 1.5,
    decoration: TextDecoration.none,
  );

  static TextStyle get titleSmall => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
    height: 1.43,
    decoration: TextDecoration.none,
  );

  // Body styles
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: textFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    height: 1.5,
    decoration: TextDecoration.none,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: textFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
    height: 1.43,
    decoration: TextDecoration.none,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: textFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  // Label styles
  static TextStyle get labelLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
    height: 1.43,
    decoration: TextDecoration.none,
  );

  static TextStyle get labelMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textTertiary,
    height: 1.45,
    decoration: TextDecoration.none,
  );

  // Custom styles for Finar
  static TextStyle get hero => TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.1,
    decoration: TextDecoration.none,
  );

  static TextStyle get subtitle => TextStyle(
    fontFamily: textFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    height: 1.4,
    decoration: TextDecoration.none,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: textFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textTertiary,
    height: 1.38,
    decoration: TextDecoration.none,
  );

  static TextStyle get button => TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    color: AppColors.textPrimary,
    height: 1.3,
    decoration: TextDecoration.none,
  );

  static TextStyle get buttonSmall => TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24,
    color: AppColors.textPrimary,
    height: 1.33,
    decoration: TextDecoration.none,
  );

  static TextStyle get buttonLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.25,
    decoration: TextDecoration.none,
  );

  static TextStyle get badge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
    height: 1.2,
    decoration: TextDecoration.none,
  );

  static TextStyle get rating => TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.accentYellow,
    height: 1.2,
    decoration: TextDecoration.none,
  );

  static TextStyle get metadata => TextStyle(
    fontFamily: textFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textSecondary,
    height: 1.38,
    decoration: TextDecoration.none,
  );

  static TextStyle get playerTime => TextStyle(
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
