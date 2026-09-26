import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';
import '../core/storage/app_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/platform.dart';
import '../providers/providers.dart';
import '../providers/session_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/focusable.dart';

/// Sign-in flow: server address -> who's watching -> password.
/// One page, internal steps, no routes.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _serverController = TextEditingController();
  final _passwordController = TextEditingController();

  ServerInfo? _server;
  List<JfUser> _users = [];
  JfUser? _selectedUser;
  String? _error;
  bool _busy = false;
  bool _connecting = false;

  @override
  void dispose() {
    _serverController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _serverController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final info =
          await ref.read(jellyfinClientProvider).testConnection(url);
      List<JfUser> users = [];
      try {
        users = await ref.read(jellyfinClientProvider).getPublicUsers();
      } catch (_) {}
      setState(() {
        _server = info;
        _users = users;
        _connecting = false;
      });
    } catch (_) {
      setState(() {
        _connecting = false;
        _error =
            'Could not reach that server. Check the address and try again.';
      });
    }
  }

  Future<void> _signIn(JfUser user, String password) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).signIn(
            serverUrl: _server!.serverUrl,
            serverName: _server!.name,
            username: user.name,
            password: password,
            imageTag: user.primaryImageTag,
          );
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Sign in failed. Check your password and try again.';
      });
    }
  }

  Future<void> _switchTo(SavedAccount account) async {
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).switchAccount(account);
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Could not sign in to that account.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedAccounts =
        ref.watch(sessionProvider) is SignedOut
            ? (ref.watch(sessionProvider) as SignedOut).accounts
            : const <SavedAccount>[];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Insets.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Insets.xl),
                  Text('Finar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: Insets.xs),
                  Text(
                    'Your Jellyfin library, everywhere.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: Insets.xxl),
                  if (_server == null) ...[
                    _serverStep(savedAccounts),
                  ] else if (_selectedUser == null) ...[
                    _usersStep(savedAccounts),
                  ] else ...[
                    _passwordStep(),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: Insets.md),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _serverStep(List<SavedAccount> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Connect to a server',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Insets.sm),
        TextField(
          controller: _serverController,
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.10:8096',
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
          onSubmitted: (_) => _connect(),
        ),
        const SizedBox(height: Insets.md),
        FilledButton(
          onPressed: _connecting ? null : _connect,
          child: _connecting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Connect'),
        ),
        if (accounts.isNotEmpty) ...[
          const SizedBox(height: Insets.xl),
          Text('Saved accounts',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: Insets.sm),
          for (final a in accounts)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Focusable(
                onTap: _busy ? null : () => _switchTo(a),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Radii.card)),
                  tileColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  title: Text(a.userName),
                  subtitle: Text(
                      '${a.serverName.isEmpty ? 'Jellyfin' : a.serverName}  •  ${a.serverUrl}'),
                  trailing: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _usersStep(List<SavedAccount> accounts) {
    final localAccounts = accounts
        .where((a) => a.serverUrl == _server!.serverUrl)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                      _server = null;
                      _users = [];
                      _error = null;
                    })),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_server!.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(_server!.serverUrl,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.lg),
        if (_users.isEmpty && localAccounts.isEmpty)
          Text('No public users on this server.',
              style: Theme.of(context).textTheme.bodySmall),
        if (localAccounts.isNotEmpty) ...[
          Text('Saved accounts',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: Insets.sm),
          for (final a in localAccounts)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Focusable(
                onTap: _busy ? null : () => _switchTo(a),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Radii.card)),
                  tileColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  title: Text(a.userName),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          const SizedBox(height: Insets.md),
        ],
        if (_users.isNotEmpty) ...[
          Text("Who's watching?",
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: Insets.sm),
          Wrap(
            spacing: Insets.md,
            runSpacing: Insets.md,
            children: [
              for (final u in _users) _userTile(u),
            ],
          ),
        ],
      ],
    );
  }

  Widget _userTile(JfUser user) {
    final client = ref.read(jellyfinClientProvider);
    return Focusable(
      onTap: () => setState(() {
        _selectedUser = user;
        _passwordController.clear();
        _error = null;
      }),
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            AppImage(
              client.userImageUrl(user, maxWidth: 192),
              shape: ArtShape.avatar,
            ),
            const SizedBox(height: Insets.sm),
            Text(user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }

  Widget _passwordStep() {
    final user = _selectedUser!;
    final client = ref.read(jellyfinClientProvider);
    final needsPassword =
        user.hasPassword || user.hasConfiguredPassword;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedUser = null)),
            SizedBox(
                width: 56,
                child: AppImage(
                    client.userImageUrl(user, maxWidth: 112),
                    shape: ArtShape.avatar)),
            const SizedBox(width: Insets.sm),
            Text(user.name,
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: Insets.lg),
        if (needsPassword)
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(hintText: 'Password'),
            obscureText: true,
            autofocus: !isDesktopPlatform,
            onSubmitted: (_) =>
                _signIn(user, _passwordController.text),
          ),
        const SizedBox(height: Insets.md),
        FilledButton(
          onPressed: _busy
              ? null
              : () => _signIn(user, _passwordController.text),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Sign in'),
        ),
      ],
    );
  }
}
