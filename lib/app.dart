import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/platform_detector.dart';
import 'providers/providers.dart';
import 'pages/desktop/desktop_home.dart';
import 'pages/mobile/mobile_home.dart';
import 'pages/tv/tv_home.dart';
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

    // Show appropriate UI based on forced mode or platform
    return _buildHomeForUiMode(forcedUiMode);
  }

  Widget _buildHomeForUiMode(UiMode mode) {
    switch (mode) {
      case UiMode.desktop:
        return const DesktopHome();
      case UiMode.mobile:
        return const MobileHome();
      case UiMode.tv:
        return const TvHome();
      case UiMode.auto:
        // Use platform detection
        if (PlatformDetector.isTV) {
          return const TvHome();
        } else if (PlatformDetector.isDesktop) {
          return const DesktopHome();
        } else {
          return const MobileHome();
        }
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Finar',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
