import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_container.dart';

/// Hides scrollbars on the login page scrollables.
class _NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

/// Adaptive login page for TV, Mobile, and Desktop
class LoginPage extends ConsumerStatefulWidget {
  /// When true, after successful login navigate back to Who's watching (Add profile flow).
  final bool fromAddProfile;

  const LoginPage({super.key, this.fromAddProfile = false});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _serverFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _loginButtonFocusNode = FocusNode();
  final _quickConnectFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  // Quick Connect state
  bool _showQuickConnect = false;
  String? _quickConnectCode;
  Timer? _quickConnectTimer;
  bool _quickConnectPolling = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _serverFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _loginButtonFocusNode.dispose();
    _quickConnectFocusNode.dispose();
    _quickConnectTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await ref
          .read(authProvider.notifier)
          .login(
            serverUrl: _serverController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        if (!success) {
          final authState = ref.read(authProvider);
          setState(() {
            _error = authState.errorMessage ?? 'Login failed. Please check your credentials and try again.';
          });
        } else if (widget.fromAddProfile) {
          await ref.read(authProvider.notifier).clearCurrentSessionForProfilePicker();
          if (mounted) Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('XMLHttpRequest') || 
              e.toString().contains('CORS')) {
            _error = 'Network request blocked. This may be a CORS issue with the server.';
          } else if (e.toString().contains('SocketException') || 
                     e.toString().contains('Connection refused')) {
            _error = 'Could not connect to server. Please check the URL.';
          } else {
            _error = 'An unexpected error occurred: ${e.toString().length > 100 ? e.toString().substring(0, 100) : e.toString()}';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initiateQuickConnect() async {
    if (_serverController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter your server URL first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First connect to server
      final connected = await ref
          .read(authProvider.notifier)
          .connectToServer(_serverController.text.trim());

      if (!connected) {
        setState(() {
          _error = 'Failed to connect to server';
          _isLoading = false;
        });
        return;
      }

      // Initiate quick connect
      final code = await ref.read(authProvider.notifier).initiateQuickConnect();

      if (code != null) {
        setState(() {
          _quickConnectCode = code;
          _showQuickConnect = true;
          _isLoading = false;
        });
        _startQuickConnectPolling(code);
      } else {
        setState(() {
          _error = 'Quick Connect not available on this server';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initiate Quick Connect';
        _isLoading = false;
      });
    }
  }

  void _startQuickConnectPolling(String code) {
    _quickConnectPolling = true;
    _quickConnectTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!_quickConnectPolling) return;

      final success = await ref
          .read(authProvider.notifier)
          .checkQuickConnect(code);
      if (success && mounted) {
        _cancelQuickConnect();
      }
    });

    // Auto-cancel after 5 minutes
    Future.delayed(const Duration(minutes: 5), () {
      if (_quickConnectPolling && mounted) {
        _cancelQuickConnect();
        setState(() {
          _error = 'Quick Connect timed out';
        });
      }
    });
  }

  void _cancelQuickConnect() {
    _quickConnectPolling = false;
    _quickConnectTimer?.cancel();
    setState(() {
      _showQuickConnect = false;
      _quickConnectCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isLandscape = width > height;
    final authState = ref.watch(authProvider);
    final displayedError = _error ?? authState.errorMessage;

    // Size-based layout breakpoints
    // Mobile: width < 600
    // Tablet/Desktop: width >= 600 and < 1200
    // TV/Large: width >= 1200 or height >= 800 in landscape with width >= 1000
    final isMobileSize = width < 600;
    final isLargeSize =
        width >= 1200 || (isLandscape && width >= 1000 && height >= 600);
    final isDesktopSize = !isMobileSize && !isLargeSize;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),

          // Main content
          SafeArea(
            child: _showQuickConnect
                ? _buildQuickConnectView(isLargeSize)
                : isLargeSize
                ? _buildTVLayout(displayedError)
                : isDesktopSize
                ? _buildDesktopLayout(displayedError)
                : _buildMobileLayout(displayedError),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            const Color(0xFF0D1520),
            const Color(0xFF0F1A28),
            AppColors.background,
          ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle floating orbs
          Positioned(
            top: -80,
            right: -80,
            child: _buildGlowOrb(Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), 280),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: _buildGlowOrb(
              AppColors.secondary.withValues(alpha: 0.15),
              320,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            right: -30,
            child: _buildGlowOrb(AppColors.accent.withValues(alpha: 0.1), 180),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.08, 1.08),
          duration: const Duration(seconds: 5),
          curve: Curves.easeInOut,
        );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(String? displayedError) {
    return Center(
      child: ScrollConfiguration(
        behavior: _NoScrollbarScrollBehavior(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(scale: 1.0),
            const SizedBox(height: 48),
            _buildLoginForm(maxWidth: 400, displayedError: displayedError),
          ],
          ),
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout(String? displayedError) {
    return Row(
      children: [
        // Left side - Branding
        Expanded(
          flex: 5,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(scale: 1.5, alignment: CrossAxisAlignment.start),
                  const SizedBox(height: 48),
                  _buildFeatureList(),
                ],
              ),
            ),
          ),
        ),

        // Right side - Login form
        Expanded(
          flex: 4,
          child: Center(
            child: ScrollConfiguration(
              behavior: _NoScrollbarScrollBehavior(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: _buildLoginForm(maxWidth: 420, displayedError: displayedError),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== TV LAYOUT ====================
  Widget _buildTVLayout(String? displayedError) {
    return Focus(
      autofocus: true,
      child: Center(
        child: ScrollConfiguration(
          behavior: _NoScrollbarScrollBehavior(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 48),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left - Branding
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLogo(scale: 2.0),
                    const SizedBox(height: 32),
                    Text(
                      'Use the remote to navigate',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 80),

              // Right - Form
              Expanded(child: _buildLoginForm(maxWidth: 500, isTV: true, displayedError: displayedError)),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ==================== QUICK CONNECT VIEW ====================
  Widget _buildQuickConnectView(bool isTV) {
    return Center(
          child: GlassContainer(
            padding: EdgeInsets.all(isTV ? 64 : 48),
            borderRadius: AppTheme.radiusXl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                      Icons.phonelink,
                      size: isTV ? 80 : 64,
                      color: Theme.of(context).colorScheme.primary,
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1),
                      duration: const Duration(seconds: 1),
                    ),
                const SizedBox(height: 32),
                Text(
                  'Quick Connect',
                  style: TextStyle(
                    fontSize: isTV ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter this code in your Jellyfin dashboard',
                  style: TextStyle(
                    fontSize: isTV ? 18 : 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                GlassContainer(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTV ? 48 : 32,
                    vertical: isTV ? 24 : 16,
                  ),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppTheme.radiusLg,
                  child: Text(
                    _quickConnectCode ?? '------',
                    style: TextStyle(
                      fontSize: isTV ? 56 : 42,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for authorization...',
                      style: TextStyle(
                        fontSize: isTV ? 16 : 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildButton(
                  onPressed: _cancelQuickConnect,
                  label: 'Cancel',
                  isOutlined: true,
                  focusNode: _quickConnectFocusNode,
                  isTV: isTV,
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  // ==================== SHARED COMPONENTS ====================

  Widget _buildLogo({
    double scale = 1.0,
    CrossAxisAlignment alignment = CrossAxisAlignment.center,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        // App icon/logo with refined styling
        Container(
              width: 76 * scale,
              height: 76 * scale,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(18 * scale),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 44 * scale,
                color: AppColors.textOnPrimary,
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
              duration: 700.ms,
            ),

        SizedBox(height: 20 * scale),

        // App name with refined typography
        Text(
              'Finar',
              style: TextStyle(
                fontSize: 44 * scale,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
            .animate()
            .fadeIn(delay: 150.ms, duration: 500.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

        SizedBox(height: 6 * scale),

        // Tagline with improved styling
        Text(
          'Your Jellyfin Experience',
          style: TextStyle(
            fontSize: 14 * scale,
            color: AppColors.textTertiary,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildFeatureList() {
    final features = [
      (Icons.devices_rounded, 'Multi-Platform', 'Watch on any device'),
      (Icons.download_rounded, 'Offline Mode', 'Download for later'),
      (Icons.high_quality_rounded, 'High Quality', 'Stream in full resolution'),
      (Icons.sync_rounded, 'Sync Progress', 'Continue where you left off'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(feature.$1, color: Theme.of(context).colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.$2,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature.$3,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 600 + (index * 100)))
            .slideX(begin: -0.2, end: 0);
      }).toList(),
    );
  }

  Widget _buildLoginForm({required double maxWidth, bool isTV = false, String? displayedError}) {
    return GlassContainer(
          width: maxWidth,
          padding: EdgeInsets.all(isTV ? 40 : 32),
          borderRadius: AppTheme.radiusXl,
          blur: AppTheme.blurMedium,
          color: AppColors.surface,
          opacity: 0.95,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface, AppColors.surface],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isTV) ...[
                  Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your Jellyfin server',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Server URL field
                _buildTextField(
                  controller: _serverController,
                  focusNode: _serverFocusNode,
                  label: 'Server URL',
                  hint: 'https://jellyfin.example.com',
                  icon: Icons.dns_outlined,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _usernameFocusNode.requestFocus(),
                  isTV: isTV,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your server URL';
                    }
                    if (!value.startsWith('http://') &&
                        !value.startsWith('https://')) {
                      return 'URL must start with http:// or https://';
                    }
                    return null;
                  },
                ),

                SizedBox(height: isTV ? 24 : 20),

                // Username field
                _buildTextField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  label: 'Username',
                  hint: 'Enter your username',
                  icon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  isTV: isTV,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),

                SizedBox(height: isTV ? 24 : 20),

                // Password field
                _buildTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  isTV: isTV,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                SizedBox(height: isTV ? 16 : 12),

                // Error message
                if (displayedError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: isTV ? 24 : 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            displayedError,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: isTV ? 16 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().shake(),

                SizedBox(height: isTV ? 32 : 24),

                // Login button
                _buildButton(
                  onPressed: _isLoading ? null : _login,
                  label: 'Sign In',
                  isLoading: _isLoading,
                  focusNode: _loginButtonFocusNode,
                  isTV: isTV,
                ),

                SizedBox(height: isTV ? 20 : 16),

                // Quick Connect button
                _buildButton(
                  onPressed: _isLoading ? null : _initiateQuickConnect,
                  label: 'Quick Connect',
                  isOutlined: true,
                  icon: Icons.qr_code,
                  focusNode: _quickConnectFocusNode,
                  isTV: isTV,
                ),

                if (isTV) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Tip: Quick Connect is easier on TV! Enter the code on any device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    bool isTV = false,
  }) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        setState(() {}); // Rebuild to show focus state
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: hasFocus ? Theme.of(context).colorScheme.primary : AppColors.glassBorder,
                width: hasFocus ? 2 : 1,
              ),
              color: AppColors.surface.withValues(alpha: 0.5),
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onFieldSubmitted: onSubmitted,
              validator: validator,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isTV ? 18 : 16,
              ),
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                labelStyle: TextStyle(
                  color: hasFocus ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
                  fontSize: isTV ? 16 : 14,
                ),
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: isTV ? 16 : 14,
                ),
                prefixIcon: Icon(
                  icon,
                  color: hasFocus ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
                  size: isTV ? 28 : 24,
                ),
                suffixIcon: suffixIcon,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isTV ? 20 : 16,
                ),
                errorStyle: TextStyle(
                  color: AppColors.error,
                  fontSize: isTV ? 14 : 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback? onPressed,
    required String label,
    bool isOutlined = false,
    bool isLoading = false,
    IconData? icon,
    FocusNode? focusNode,
    bool isTV = false,
  }) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        setState(() {}); // Rebuild to show focus state
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.diagonal3Values(hasFocus ? 1.02 : 1.0, hasFocus ? 1.02 : 1.0, 1.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  height: isTV ? 64 : 56,
                  decoration: BoxDecoration(
                    gradient: isOutlined
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: isOutlined
                        ? Border.all(
                            color: hasFocus
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.glassBorder,
                            width: hasFocus ? 2 : 1,
                          )
                        : null,
                    boxShadow: !isOutlined && hasFocus
                        ? AppTheme.shadowGlow(Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                isOutlined ? Theme.of(context).colorScheme.primary : Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icon != null) ...[
                                Icon(
                                  icon,
                                  color: isOutlined
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                                  size: isTV ? 24 : 20,
                                ),
                                const SizedBox(width: 12),
                              ],
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: isTV ? 20 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: isOutlined
                                      ? (hasFocus
                                            ? Theme.of(context).colorScheme.primary
                                            : AppColors.textPrimary)
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
