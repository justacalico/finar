import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dpad/dpad.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'core/theme/text_styles.dart';
import 'core/services/controller_service.dart';
import 'providers/providers.dart';
import 'pages/adaptive_pages.dart';
import 'pages/login_page.dart';

class FinarApp extends ConsumerStatefulWidget {
  const FinarApp({super.key});

  @override
  ConsumerState<FinarApp> createState() => _FinarAppState();
}

class _FinarAppState extends ConsumerState<FinarApp> {
  StreamSubscription<ControllerAction>? _gamepadSubscription;

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

    // Defer auth restoration and gamepad setup to after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).restoreSession();
      _setupGamepadListener();
    });
  }

  void _setupGamepadListener() {
    // Listen for gamepad actions and convert them to focus navigation
    final gamepadNotifier = ref.read(gamepadStateProvider.notifier);
    _gamepadSubscription = gamepadNotifier.actionStream.listen(
      _handleGamepadAction,
    );

    // Also listen for keyboard events that might be gamepad buttons
    // This is important for Steam Deck where Steam Input can send
    // controller buttons as keyboard events
    HardwareKeyboard.instance.addHandler(_handleKeyboardGamepadInput);
  }

  /// Handle gamepad buttons sent as keyboard events (Steam Input support)
  bool _handleKeyboardGamepadInput(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // Get controller action from keyboard event
    final action = ControllerService.getAction(event);
    if (action != null) {
      // Don't process if this is a regular keyboard key that's already handled
      // Only process gamepad-specific keys
      final key = event.logicalKey;
      final isGamepadKey =
          key == LogicalKeyboardKey.gameButtonA ||
          key == LogicalKeyboardKey.gameButtonB ||
          key == LogicalKeyboardKey.gameButtonX ||
          key == LogicalKeyboardKey.gameButtonY ||
          key == LogicalKeyboardKey.gameButtonStart ||
          key == LogicalKeyboardKey.gameButtonSelect ||
          key == LogicalKeyboardKey.gameButtonLeft1 ||
          key == LogicalKeyboardKey.gameButtonRight1 ||
          key == LogicalKeyboardKey.gameButtonLeft2 ||
          key == LogicalKeyboardKey.gameButtonRight2 ||
          key == LogicalKeyboardKey.goBack ||
          key == LogicalKeyboardKey.browserBack ||
          key == LogicalKeyboardKey.select;

      if (isGamepadKey) {
        _handleGamepadAction(action);
        return true; // Event handled
      }
    }
    return false; // Let the event propagate
  }

  void _handleGamepadAction(ControllerAction action) {
    final context = this.context;
    if (!mounted) return;

    switch (action) {
      case ControllerAction.up:
        _moveFocus(context, TraversalDirection.up);
        break;
      case ControllerAction.down:
        _moveFocus(context, TraversalDirection.down);
        break;
      case ControllerAction.left:
        _moveFocus(context, TraversalDirection.left);
        break;
      case ControllerAction.right:
        _moveFocus(context, TraversalDirection.right);
        break;
      case ControllerAction.select:
        _activateFocusedWidget(context);
        break;
      case ControllerAction.back:
        _handleBack(context);
        break;
      default:
        break;
    }
  }

  void _moveFocus(BuildContext context, TraversalDirection direction) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null) {
      primaryFocus.focusInDirection(direction);
    }
  }

  void _activateFocusedWidget(BuildContext context) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null) {
      // Simulate Enter key press to activate focused widget
      final keyEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: Duration.zero,
      );
      primaryFocus.onKeyEvent?.call(primaryFocus, keyEvent);
    }
  }

  void _handleBack(BuildContext context) {
    // Try to pop the current route
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _gamepadSubscription?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyboardGamepadInput);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch gamepad state to keep the provider active
    ref.watch(gamepadStateProvider);

    return DpadNavigator(
      enabled: true,
      onBackPressed: () {
        _handleBack(context);
      },
      child: MaterialApp(
        title: 'Finar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const _AppRouter(),
      ),
    );
  }
}

class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show loading while checking auth
    if (authState.isLoading) {
      return const _SplashScreen();
    }

    // Show login if not authenticated
    if (!authState.isAuthenticated) {
      return const LoginPage();
    }

    return const AdaptiveHomePage();
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
