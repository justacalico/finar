import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/colors.dart';
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
  String? _error;

  bool _showQuickConnect = false;
  String? _quickConnectCode;
  Timer? _quickConnectTimer;
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

  Future<void> _initiateQuickConnect() async {
    if (_serverController.text.trim().isEmpty) {
      setState(() => _error = 'Enter your server URL first');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
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

    Future.delayed(const Duration(minutes: 5), () {
      if (_quickConnectPolling && mounted) {
        _cancelQuickConnect();
        setState(() => _error = 'Quick Connect timed out');
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
    final width = MediaQuery.of(context).size.width;
    final isTV = width >= 1200;
    final authState = ref.watch(authProvider);
    final displayedError = _error ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _showQuickConnect
            ? _buildQuickConnectView(isTV)
            : _buildLoginView(isTV, displayedError),
      ),
    );
  }

  Widget _buildLoginView(bool isTV, String? displayedError) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTV ? 80 : 24,
          vertical: 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTV ? 460 : 400,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'icon.svg',
                    width: isTV ? 88 : 72,
                    height: isTV ? 88 : 72,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Finar',
                    style: TextStyle(
                      fontSize: isTV ? 32 : 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: isTV ? 48 : 40),

                  _buildField(
                    controller: _serverController,
                    focusNode: _serverFocusNode,
                    label: 'Server URL',
                    hint: 'https://jellyfin.example.com',
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _usernameFocusNode.requestFocus(),
                    isTV: isTV,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter your server URL';
                      if (!value.startsWith('http://') && !value.startsWith('https://')) {
                        return 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: isTV ? 20 : 16),

                  _buildField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    label: 'Username',
                    hint: 'Enter your username',
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    isTV: isTV,
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
                    Text(
                      displayedError,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: isTV ? 16 : 14,
                      ),
                    ),
                  ],

                  SizedBox(height: isTV ? 32 : 28),

                  _buildButton(
                    onPressed: _isLoading ? null : _login,
                    label: 'Sign In',
                    isLoading: _isLoading,
                    focusNode: _loginButtonFocusNode,
                    isTV: isTV,
                  ),
                  SizedBox(height: isTV ? 16 : 12),

                  _buildButton(
                    onPressed: _isLoading ? null : _initiateQuickConnect,
                    label: 'Quick Connect',
                    isOutlined: true,
                    icon: Icons.qr_code_outlined,
                    focusNode: _quickConnectFocusNode,
                    isTV: isTV,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickConnectView(bool isTV) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTV ? 480 : 400),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTV ? 80 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phonelink_outlined,
                size: isTV ? 64 : 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Quick Connect',
                style: TextStyle(
                  fontSize: isTV ? 28 : 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter this code in your Jellyfin dashboard',
                style: TextStyle(
                  fontSize: isTV ? 16 : 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                _quickConnectCode ?? '------',
                style: TextStyle(
                  fontSize: isTV ? 48 : 40,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 8,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
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
    Widget? suffixIcon,
    bool isTV = false,
  }) {
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
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
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
