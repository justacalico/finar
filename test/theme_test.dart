import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/providers/settings_provider.dart';
import 'package:finar/widgets/animated_card.dart';

void main() {
  group('AppColors', () {
    test('follows light mode', () {
      AppColors.set(
        brightness: Brightness.light,
        oled: false,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      expect(AppColors.brightness, Brightness.light);
      expect(AppColors.background, const Color(0xFFF2F2F7));
      expect(AppColors.textPrimary, const Color(0xFF1C1C1E));
    });

    test('OLED mode uses pure black', () {
      AppColors.set(
        brightness: Brightness.dark,
        oled: true,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      expect(AppColors.background, Colors.black);
      expect(AppColors.surface, Colors.black);
    });

    test('primary follows theme color', () {
      AppColors.set(
        brightness: Brightness.dark,
        oled: false,
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
        oled: false,
        themeColor: const Color(0xFFFF0000),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: true,
      );

      expect(AppColors.primary, const Color(0xFF00B8D9));
    });

    test('light mode glass colors switch to dark tints', () {
      AppColors.set(
        brightness: Brightness.light,
        oled: false,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      expect(AppColors.glassWhite, const Color(0x14000000));
    });
  });

  group('AppThemeMode', () {
    test('maps to MaterialApp theme mode', () {
      expect(AppThemeMode.system.materialThemeMode, ThemeMode.system);
      expect(AppThemeMode.light.materialThemeMode, ThemeMode.light);
      expect(AppThemeMode.dark.materialThemeMode, ThemeMode.dark);
      expect(AppThemeMode.oled.materialThemeMode, ThemeMode.dark);
    });

    test('forced brightness follows the selection', () {
      expect(AppThemeMode.system.forcedBrightness, isNull);
      expect(AppThemeMode.light.forcedBrightness, Brightness.light);
      expect(AppThemeMode.dark.forcedBrightness, Brightness.dark);
      expect(AppThemeMode.oled.forcedBrightness, Brightness.dark);
      expect(AppThemeMode.oled.isOled, isTrue);
      expect(AppThemeMode.dark.isOled, isFalse);
    });

    test('migrates old themeMode/themeStyle saves', () {
      expect(
        AppSettings.fromJson({'themeMode': 1, 'themeStyle': 0}).appThemeMode,
        AppThemeMode.light,
      );
      // Old oled style wins over the old dark mode value.
      expect(
        AppSettings.fromJson({'themeMode': 2, 'themeStyle': 1}).appThemeMode,
        AppThemeMode.oled,
      );
      // Coloured has no replacement, falls back to the old mode.
      expect(
        AppSettings.fromJson({'themeMode': 0, 'themeStyle': 2}).appThemeMode,
        AppThemeMode.system,
      );
      expect(AppSettings.fromJson(const {}).appThemeMode, AppThemeMode.dark);
    });

    test('round trips through json', () {
      const settings = AppSettings(appThemeMode: AppThemeMode.oled);
      expect(
        AppSettings.fromJson(settings.toJson()).appThemeMode,
        AppThemeMode.oled,
      );
    });
  });

  group('AppTheme', () {
    test('dark theme uses AppColors', () {
      AppColors.set(
        brightness: Brightness.dark,
        oled: false,
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
        oled: false,
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

  group('AppTextStyles', () {
    test('text colors follow palette changes', () {
      AppColors.set(
        brightness: Brightness.dark,
        oled: false,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );
      final darkColor = AppTextStyles.bodyLarge.color;

      AppColors.set(brightness: Brightness.light);

      expect(darkColor, isNot(AppTextStyles.bodyLarge.color));
      expect(AppTextStyles.bodyLarge.color, AppColors.textPrimary);
      expect(AppTextStyles.bodySmall.color, AppColors.textSecondary);
    });
  });

  group('scheduleTreeRebuild', () {
    testWidgets('repaints widgets that read AppColors statically', (
      tester,
    ) async {
      AppColors.set(
        brightness: Brightness.dark,
        oled: false,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ColoredBox(
              key: const Key('theme-test-box'),
              color: AppColors.background,
            ),
          ),
        ),
      );
      final box = find.byKey(const Key('theme-test-box'));
      expect(
        tester.widget<ColoredBox>(box).color,
        const Color(0xFF0D0D0F),
      );

      AppColors.set(brightness: Brightness.light);
      AppTheme.scheduleTreeRebuild();
      await tester.pump();
      await tester.pump();

      expect(
        tester.widget<ColoredBox>(box).color,
        const Color(0xFFF2F2F7),
      );
    });
  });

  group('image overlay text', () {
    testWidgets('AnimatedCard title stays white in light mode', (tester) async {
      AppColors.set(
        brightness: Brightness.light,
        oled: false,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedCard(
                width: 120,
                title: 'Movie',
                subtitle: '2024',
                enableEntranceAnimation: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // The title sits on the card's dark gradient, so it must not follow
      // the light theme's dark textPrimary color.
      final title = tester.widget<Text>(find.text('Movie'));
      expect(title.style?.color, AppColors.white);
      final subtitle = tester.widget<Text>(find.text('2024'));
      expect(subtitle.style?.color, AppColors.white.withValues(alpha: 0.85));
    });

    testWidgets('HeroCard title stays white in light mode', (tester) async {
      AppColors.set(
        brightness: Brightness.light,
        oled: false,
        themeColor: const Color(0xFF00E5B8),
        accentColor: const Color(0xFF00B8D9),
        useSystemAccent: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeroCard(
              title: 'Featured',
              subtitle: 'Movie',
              height: 300,
            ),
          ),
        ),
      );
      await tester.pump();

      final title = tester.widget<Text>(find.text('Featured'));
      expect(title.style?.color, AppColors.white);
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
