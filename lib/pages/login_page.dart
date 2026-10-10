import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  final bool fromAddProfile;

  const LoginPage({super.key, this.fromAddProfile = false});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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
  bool _useHttps = true;
  int _stage = 1;
  String? _error;

  String _getServerUrl() {
    final host = _serverController.text.trim();
    final prefix = _useHttps ? 'https://' : 'http://';
    if (host.startsWith('http://') || host.startsWith('https://')) {
      return host;
    }
    return '$prefix$host';
  }

  bool _showQuickConnect = false;
  String? _quickConnectCode;
  Timer? _quickConnectTimer;
  Timer? _quickConnectTimeout;
  bool _quickConnectPolling = false;

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
    _quickConnectTimeout?.cancel();
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
            serverUrl: _getServerUrl(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        if (!success) {
          final authState = ref.read(authProvider);
          setState(() {
            _error = authState.errorMessage ?? 'Login failed. Check your credentials and try again.';
          });
        } else if (widget.fromAddProfile) {
          await ref.read(authProvider.notifier).clearCurrentSessionForProfilePicker();
          if (mounted) Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final msg = e.toString();
          if (msg.contains('XMLHttpRequest') || msg.contains('CORS')) {
            _error = 'Network request blocked. This may be a CORS issue with the server.';
          } else if (msg.contains('SocketException') || msg.contains('Connection refused')) {
            _error = 'Could not connect to server. Check the URL.';
          } else {
            _error = 'An unexpected error occurred: ${msg.length > 100 ? msg.substring(0, 100) : msg}';
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final connected = await ref
        .read(authProvider.notifier)
        .connectToServer(_getServerUrl());

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (connected) {
        _stage = 2;
      } else {
        _error = ref.read(authProvider).errorMessage ??
            'Could not connect to server';
      }
    });
  }

  Future<void> _initiateQuickConnect() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final connected = await ref
          .read(authProvider.notifier)
          .connectToServer(_getServerUrl());

      if (!connected) {
        setState(() {
          _error = 'Failed to connect to server';
          _isLoading = false;
        });
        return;
      }

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
      final success = await ref.read(authProvider.notifier).checkQuickConnect(code);
      if (success && mounted) _cancelQuickConnect();
    });

    _quickConnectTimeout = Timer(const Duration(minutes: 5), () {
      if (_quickConnectPolling && mounted) {
        _cancelQuickConnect();
        setState(() => _error = 'Quick Connect timed out');
      }
    });
  }

  void _cancelQuickConnect() {
    _quickConnectPolling = false;
    _quickConnectTimer?.cancel();
    _quickConnectTimeout?.cancel();
    setState(() {
      _showQuickConnect = false;
      _quickConnectCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTV = width >= 1200;
    final authState = ref.watch(authProvider);
    final displayedError = _error ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -140,
            left: -140,
            child: _buildGlow(AppColors.primary, isTV ? 480 : 400),
          ),
          Positioned(
            bottom: -160,
            right: -120,
            child: _buildGlow(AppColors.secondary, isTV ? 440 : 360),
          ),
          SafeArea(
            child: _showQuickConnect
                ? _buildQuickConnectView(isTV)
                : _buildLoginView(isTV, displayedError),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required bool isTV, required Widget child}) {
    return Container(
      constraints: BoxConstraints(maxWidth: isTV ? 480 : 420),
      padding: EdgeInsets.symmetric(
        horizontal: isTV ? 44 : 32,
        vertical: isTV ? 44 : 36,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.25),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLoginView(bool isTV, String? displayedError) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTV ? 80 : 20,
          vertical: 32,
        ),
        child: _buildCard(
          isTV: isTV,
          child: Form(
            key: _formKey,
            child: _stage == 1
                ? _buildServerStage(isTV, displayedError)
                : _buildCredentialsStage(isTV, displayedError),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTV, String subtitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SvgPicture.asset(
            'icon.svg',
            width: isTV ? 76 : 64,
            height: isTV ? 76 : 64,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Finar',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: isTV ? 32 : 28,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: isTV ? 16 : 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildServerStage(bool isTV, String? displayedError) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(isTV, 'Connect to your Jellyfin server'),
        SizedBox(height: isTV ? 36 : 32),

        _buildField(
          controller: _serverController,
          focusNode: _serverFocusNode,
          label: 'Server',
          hint: 'jellyfin.example.com',
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _continue(),
          isTV: isTV,
          prefixIcon: _buildSchemeToggle(isTV),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Enter your server URL';
            return null;
          },
        ),

        if (displayedError != null) ...[
          SizedBox(height: isTV ? 20 : 16),
          _buildErrorBanner(displayedError, isTV),
        ],

        SizedBox(height: isTV ? 32 : 28),

        _buildPrimaryButton(
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _continue,
          isTV: isTV,
        ),
      ],
    );
  }

  Widget _buildCredentialsStage(bool isTV, String? displayedError) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
              size: isTV ? 26 : 22,
            ),
            tooltip: 'Change server',
            onPressed: () => setState(() {
              _stage = 1;
              _error = null;
            }),
          ),
        ),
        _buildHeader(isTV, _getServerUrl()),
        SizedBox(height: isTV ? 36 : 32),

        _buildField(
          controller: _usernameController,
          focusNode: _usernameFocusNode,
          label: 'Username',
          hint: 'Enter your username',
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          isTV: isTV,
          prefixIcon: _buildFieldIcon(Icons.person_outline_rounded, isTV),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Enter your username';
            return null;
          },
        ),
        SizedBox(height: isTV ? 20 : 16),

        _buildField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: 'Password',
          hint: 'Enter your password',
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _login(),
          isTV: isTV,
          prefixIcon: _buildFieldIcon(Icons.lock_outline_rounded, isTV),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.textTertiary,
              size: isTV ? 24 : 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        if (displayedError != null) ...[
          SizedBox(height: isTV ? 20 : 16),
          _buildErrorBanner(displayedError, isTV),
        ],

        SizedBox(height: isTV ? 32 : 28),

        _buildPrimaryButton(
          label: 'Sign In',
          onPressed: _login,
          focusNode: _loginButtonFocusNode,
          isTV: isTV,
        ),
        SizedBox(height: isTV ? 24 : 20),

        Row(
          children: [
            Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'or',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: isTV ? 15 : 13,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        SizedBox(height: isTV ? 24 : 20),

        _buildButton(
          onPressed: _isLoading ? null : _initiateQuickConnect,
          label: 'Quick Connect',
          isOutlined: true,
          icon: Icons.bolt_outlined,
          focusNode: _quickConnectFocusNode,
          isTV: isTV,
        ),
      ],
    );
  }

  Widget _buildQuickConnectView(bool isTV) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isTV ? 80 : 20, vertical: 32),
        child: _buildCard(
          isTV: isTV,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: isTV ? 68 : 60,
                  height: isTV ? 68 : 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: isTV ? 36 : 32,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Connect',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontSize: isTV ? 28 : 24,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter this code in your Jellyfin dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTV ? 16 : 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: isTV ? 32 : 28),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: isTV ? 24 : 20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  _quickConnectCode ?? '------',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTV ? 44 : 38,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              SizedBox(height: isTV ? 28 : 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Waiting for authorization...',
                      style: TextStyle(
                        fontSize: isTV ? 16 : 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTV ? 32 : 28),
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
      ),
    );
  }

  Widget _buildErrorBanner(String message, bool isTV) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: isTV ? 22 : 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontSize: isTV ? 15 : 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldIcon(IconData icon, bool isTV) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: Icon(icon, color: AppColors.textTertiary, size: isTV ? 24 : 20),
    );
  }

  Widget _buildSchemeToggle(bool isTV) {
    return Tooltip(
      message: 'Tap to switch protocol',
      child: InkWell(
        onTap: () => setState(() => _useHttps = !_useHttps),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _useHttps ? 'https://' : 'http://',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: isTV ? 18 : 16,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.unfold_more_rounded,
                size: isTV ? 18 : 15,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isTV = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.divider),
    );
    return TextFormField(
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
        filled: true,
        fillColor: AppColors.backgroundTertiary,
        prefixIcon: prefixIcon,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: isTV ? 16 : 14),
        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: isTV ? 16 : 14),
        errorStyle: TextStyle(color: AppColors.error, fontSize: isTV ? 14 : 12),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isTV ? 20 : 16,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    FocusNode? focusNode,
    bool isTV = false,
  }) {
    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return SizedBox(
            width: double.infinity,
            height: isTV ? 56 : 52,
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _isLoading ? null : AppColors.primaryGradient,
                  color: _isLoading ? AppColors.surfaceHighlight : null,
                  borderRadius: BorderRadius.circular(14),
                  border: hasFocus
                      ? Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.7),
                          width: 1.5,
                        )
                      : null,
                ),
                child: InkWell(
                  onTap: _isLoading ? null : onPressed,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(AppColors.textOnPrimary),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: isTV ? 18 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                              if (icon != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  icon,
                                  size: isTV ? 22 : 19,
                                  color: AppColors.textOnPrimary,
                                ),
                              ],
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
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return SizedBox(
            width: double.infinity,
            height: isTV ? 56 : 52,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: isOutlined
                    ? Colors.transparent
                    : AppColors.primary,
                foregroundColor: isOutlined
                    ? (hasFocus ? AppColors.primary : AppColors.textPrimary)
                    : AppColors.textOnPrimary,
                side: BorderSide(
                  color: isOutlined
                      ? (hasFocus ? AppColors.primary : AppColors.divider)
                      : Colors.transparent,
                  width: hasFocus ? 1.5 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          isOutlined ? AppColors.primary : AppColors.textOnPrimary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: isTV ? 22 : 20),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: isTV ? 18 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
