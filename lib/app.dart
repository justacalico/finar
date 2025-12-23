import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'core/theme/text_styles.dart';
import 'providers/providers.dart';
import 'pages/desktop/desktop_home.dart';
import 'pages/mobile/mobile_home.dart';
import 'pages/login_page.dart';

class FinarApp extends ConsumerStatefulWidget {
  const FinarApp({super.key});

  @override
  ConsumerState<FinarApp> createState() => _FinarAppState();
}

class _FinarAppState extends ConsumerState<FinarApp> {
  @override
  void initState() {
    super.initState();
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Enable edge-to-edge on Android
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Defer auth restoration to after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  // Responsive breakpoint
  static const double mobileMaxWidth = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final forcedUiMode = ref.watch(forcedUiModeProvider);

    // Show loading while checking auth
    if (authState.isLoading) {
      return const _SplashScreen();
    }

    // Show login if not authenticated
    if (!authState.isAuthenticated) {
      return const LoginPage();
    }

    // Use LayoutBuilder for responsive UI based on window size
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildHomeForUiMode(forcedUiMode, constraints.maxWidth);
      },
    );
  }

  Widget _buildHomeForUiMode(UiMode mode, double screenWidth) {
    // If a specific mode is forced, use it
    if (mode != UiMode.auto) {
      switch (mode) {
        case UiMode.desktop:
          return const DesktopHome();
        case UiMode.mobile:
          return const MobileHome();
        case UiMode.auto:
          break; // Will fall through to responsive logic
      }
    }

    // Responsive UI based on window width
    if (screenWidth <= mobileMaxWidth) {
      // Small screens get mobile UI
      return const MobileHome();
    } else {
      // Large screens and tablets get desktop UI
      return const DesktopHome();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with gradient
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.textOnPrimary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Finar',
              style: AppTextStyles.displaySmall.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
