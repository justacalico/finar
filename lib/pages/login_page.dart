import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_container.dart';

/// Adaptive login page for TV, Mobile, and Desktop
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

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

      if (!success && mounted) {
        final authState = ref.read(authProvider);
        setState(() {
          _error = authState.errorMessage ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred. Please try again.';
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
                ? _buildTVLayout()
                : isDesktopSize
                ? _buildDesktopLayout()
                : _buildMobileLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF0D1B2A),
            Color(0xFF1B263B),
            Color(0xFF0A0A0A),
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Floating orbs
          Positioned(
            top: -100,
            right: -100,
            child: _buildGlowOrb(AppColors.primary.withValues(alpha: 0.3), 300),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: _buildGlowOrb(
              AppColors.secondary.withValues(alpha: 0.2),
              350,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -50,
            child: _buildGlowOrb(AppColors.accent.withValues(alpha: 0.15), 200),
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
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.1, 1.1),
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
        );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(scale: 1.0),
            const SizedBox(height: 48),
            _buildLoginForm(maxWidth: 400),
          ],
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout() {
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: _buildLoginForm(maxWidth: 420),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== TV LAYOUT ====================
  Widget _buildTVLayout() {
    return Focus(
      autofocus: true,
      child: Center(
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
              Expanded(child: _buildLoginForm(maxWidth: 500, isTV: true)),
            ],
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
                      color: AppColors.primary,
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppTheme.radiusLg,
                  child: Text(
                    _quickConnectCode ?? '------',
                    style: TextStyle(
                      fontSize: isTV ? 56 : 42,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
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
        // App icon/logo
        Container(
              width: 80 * scale,
              height: 80 * scale,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20 * scale),
                boxShadow: AppTheme.shadowGlow(AppColors.primary),
              ),
              child: Icon(
                Icons.play_circle_filled,
                size: 48 * scale,
                color: Colors.white,
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              curve: Curves.elasticOut,
              duration: 800.ms,
            ),

        SizedBox(height: 24 * scale),

        // App name
        Text(
              'Finar',
              style: TextStyle(
                fontSize: 48 * scale,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = AppColors.primaryGradient.createShader(
                    Rect.fromLTWH(0, 0, 200 * scale, 60 * scale),
                  ),
              ),
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

        SizedBox(height: 8 * scale),

        // Tagline
        Text(
          'Your Jellyfin Experience',
          style: TextStyle(
            fontSize: 16 * scale,
            color: AppColors.textSecondary,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildFeatureList() {
    final features = [
      (Icons.devices, 'Multi-Platform', 'Watch on any device'),
      (Icons.download, 'Offline Mode', 'Download for later'),
      (Icons.high_quality, 'High Quality', 'Stream in full resolution'),
      (Icons.sync, 'Sync Progress', 'Continue where you left off'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(feature.$1, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.$2,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        feature.$3,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
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

  Widget _buildLoginForm({required double maxWidth, bool isTV = false}) {
    return GlassContainer(
          width: maxWidth,
          padding: EdgeInsets.all(isTV ? 40 : 32),
          borderRadius: AppTheme.radiusXl,
          blur: AppTheme.blurMedium,
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
                if (_error != null)
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
                            _error!,
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
                      color: AppColors.textTertiary,
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
                color: hasFocus ? AppColors.primary : AppColors.glassBorder,
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
                  color: hasFocus ? AppColors.primary : AppColors.textSecondary,
                  fontSize: isTV ? 16 : 14,
                ),
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: isTV ? 16 : 14,
                ),
                prefixIcon: Icon(
                  icon,
                  color: hasFocus ? AppColors.primary : AppColors.textSecondary,
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
            transform: Matrix4.identity()..scale(hasFocus ? 1.02 : 1.0, hasFocus ? 1.02 : 1.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  height: isTV ? 64 : 56,
                  decoration: BoxDecoration(
                    gradient: isOutlined ? null : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: isOutlined
                        ? Border.all(
                            color: hasFocus
                                ? AppColors.primary
                                : AppColors.glassBorder,
                            width: hasFocus ? 2 : 1,
                          )
                        : null,
                    boxShadow: !isOutlined && hasFocus
                        ? AppTheme.shadowGlow(AppColors.primary)
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
                                isOutlined ? AppColors.primary : Colors.white,
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
                                      ? AppColors.primary
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
                                            ? AppColors.primary
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
