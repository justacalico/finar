import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/jellyfin_client.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _username = TextEditingController();
  final _password = TextEditingController();
  late final TabController _tabs;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    final serverUrl = ref.read(pendingServerProvider);
    if (serverUrl == null) {
      context.go('/connect');
      return;
    }
    if (_username.text.trim().isEmpty) {
      setState(() => _error = l10n.usernameRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = await ref
          .read(sessionProvider.notifier)
          .unauthenticatedClient(serverUrl);
      final result = await client.authenticateByName(
          _username.text.trim(), _password.text);
      final authed = await ref
          .read(sessionProvider.notifier)
          .clientFor(serverUrl,
              accessToken: result.accessToken,
              userId: result.user.id);
      final info = await authed.getPublicSystemInfo();
      await ref
          .read(sessionProvider.notifier)
          .signIn(serverUrl, info.serverName, result);
      if (mounted) context.go('/home');
    } on JellyfinException catch (e) {
      setState(() {
        _loading = false;
        _error = e.isAuthError || e.statusCode == 400
            ? l10n.invalidCredentials
            : l10n.signInFailed;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = l10n.signInFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final serverUrl = ref.watch(pendingServerProvider);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: scheme.outlineVariant
                        .withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: l10n.back,
                        onPressed: () => context.go('/connect'),
                      ),
                      Expanded(
                        child: Text(l10n.signIn,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(serverUrl ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabs,
                    tabs: [
                      Tab(text: l10n.signIn),
                      Tab(text: l10n.quickConnect),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 260,
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _passwordForm(l10n, scheme),
                        const _QuickConnectPane(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordForm(AppLocalizations l10n, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _username,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: l10n.username,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          onSubmitted: (_) => _signIn(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.password,
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          onSubmitted: (_) => _signIn(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    size: 18, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!,
                      style: TextStyle(
                          color: scheme.onErrorContainer)),
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        FilledButton(
          onPressed: _loading ? null : _signIn,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child:
                      CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.signIn),
        ),
      ],
    );
  }
}

class _QuickConnectPane extends ConsumerStatefulWidget {
  const _QuickConnectPane();

  @override
  ConsumerState<_QuickConnectPane> createState() =>
      _QuickConnectPaneState();
}

class _QuickConnectPaneState extends ConsumerState<_QuickConnectPane> {
  String? _code;
  String? _secret;
  String? _error;
  bool _loading = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    final serverUrl = ref.read(pendingServerProvider);
    if (serverUrl == null) return;
    try {
      final client = await ref
          .read(sessionProvider.notifier)
          .unauthenticatedClient(serverUrl);
      if (!await client.quickConnectEnabled()) {
        setState(() {
          _loading = false;
          _error = l10n.quickConnectUnavailable;
        });
        return;
      }
      final result = await client.quickConnectInitiate();
      if (!mounted) return;
      setState(() {
        _code = result.code;
        _secret = result.secret;
        _loading = false;
      });
      _poll = Timer.periodic(
          const Duration(seconds: 2), (_) => _check());
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = l10n.quickConnectUnavailable;
        });
      }
    }
  }

  Future<void> _check() async {
    final serverUrl = ref.read(pendingServerProvider);
    final secret = _secret;
    if (serverUrl == null || secret == null) return;
    final client = await ref
        .read(sessionProvider.notifier)
        .unauthenticatedClient(serverUrl);
    try {
      if (await client.quickConnectCheck(secret)) {
        _poll?.cancel();
        final result =
            await client.authenticateWithQuickConnect(secret);
        final authed = await ref
            .read(sessionProvider.notifier)
            .clientFor(serverUrl,
                accessToken: result.accessToken,
                userId: result.user.id);
        final info = await authed.getPublicSystemInfo();
        await ref
            .read(sessionProvider.notifier)
            .signIn(serverUrl, info.serverName, result);
        if (mounted) context.go('/home');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 40, color: scheme.outline),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(l10n.quickConnectCode,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(_code ?? '',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6)),
        ),
        const SizedBox(height: 14),
        Text(l10n.waitingForApproval,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}
