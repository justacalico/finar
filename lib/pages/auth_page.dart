import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';
import '../core/storage/app_storage.dart';
import '../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../providers/session_provider.dart';
import '../widgets/focusable.dart';

/// Sign-in flow: server address -> username + password.
/// One page, internal steps, no routes.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _addressController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _scheme = 'https://';
  ServerInfo? _server;
  String? _error;
  bool _busy = false;
  bool _connecting = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _addressController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Full server URL from the scheme dropdown plus the typed address.
  /// A pasted URL keeps its own scheme.
  String _serverUrl() {
    var address = _addressController.text.trim();
    if (address.startsWith('http://') || address.startsWith('https://')) {
      return address;
    }
    return '$_scheme$address';
  }

  Future<void> _connect() async {
    final url = _serverUrl();
    if (url.isEmpty || url == _scheme) return;
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      final info = await ref.read(jellyfinClientProvider).testConnection(url);
      setState(() {
        _server = info;
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

  Future<void> _signIn() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Enter your Jellyfin username.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .signIn(
            serverUrl: _server!.serverUrl,
            serverName: _server!.name,
            username: username,
            password: _passwordController.text,
          );
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Sign in failed. Check your username and password.';
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
    final savedAccounts = ref.watch(sessionProvider) is SignedOut
        ? (ref.watch(sessionProvider) as SignedOut).accounts
        : const <SavedAccount>[];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Insets.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: Insets.xl),
                  Text(
                    'Finar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  SizedBox(height: Insets.xs),
                  Text(
                    'Your Jellyfin library, everywhere.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: Insets.xxl),
                  if (_server == null)
                    _serverStep(savedAccounts)
                  else
                    _credentialsStep(savedAccounts),
                  if (_error != null) ...[
                    SizedBox(height: Insets.md),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
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
        Text(
          'Connect to a server',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: Insets.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: _scheme,
              underline: SizedBox.shrink(),
              borderRadius: BorderRadius.circular(Radii.card),
              items: const [
                DropdownMenuItem(value: 'https://', child: Text('https://')),
                DropdownMenuItem(value: 'http://', child: Text('http://')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _scheme = v);
              },
            ),
            SizedBox(width: Insets.sm),
            Expanded(
              child: TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'jellyfin.example.com:8096',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                onSubmitted: (_) => _connect(),
              ),
            ),
          ],
        ),
        SizedBox(height: Insets.md),
        FilledButton(
          onPressed: _connecting ? null : _connect,
          child: _connecting
              ? SizedBox(
                  width: dim(18),
                  height: dim(18),
                  child: CircularProgressIndicator(strokeWidth: dim(2)),
                )
              : const Text('Connect'),
        ),
        if (accounts.isNotEmpty) ...[
          SizedBox(height: Insets.xl),
          Text(
            'Saved accounts',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          SizedBox(height: Insets.sm),
          for (final a in accounts) _accountTile(a),
        ],
      ],
    );
  }

  Widget _accountTile(SavedAccount account) {
    return Padding(
      padding: EdgeInsets.only(bottom: Insets.sm),
      child: Focusable(
        onTap: _busy ? null : () => _switchTo(account),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          title: Text(account.userName),
          subtitle: Text(
            '${account.serverName.isEmpty ? 'Jellyfin' : account.serverName}  •  ${account.serverUrl}',
          ),
          trailing: _busy
              ? SizedBox(
                  width: dim(18),
                  height: dim(18),
                  child: CircularProgressIndicator(strokeWidth: dim(2)),
                )
              : const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Widget _credentialsStep(List<SavedAccount> accounts) {
    final server = _server!;
    final localAccounts = accounts
        .where((a) => a.serverUrl == server.serverUrl)
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
                _error = null;
              }),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    server.serverUrl,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Insets.lg),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(hintText: 'Username'),
          autocorrect: false,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: Insets.sm),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: 'Password',
            suffixIcon: IconButton(
              tooltip: _hidePassword ? 'Show password' : 'Hide password',
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
          obscureText: _hidePassword,
          onSubmitted: (_) => _signIn(),
        ),
        SizedBox(height: Insets.md),
        FilledButton(
          onPressed: _busy ? null : _signIn,
          child: _busy
              ? SizedBox(
                  width: dim(18),
                  height: dim(18),
                  child: CircularProgressIndicator(strokeWidth: dim(2)),
                )
              : const Text('Sign in'),
        ),
        if (localAccounts.isNotEmpty) ...[
          SizedBox(height: Insets.xl),
          Text(
            'Saved accounts',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          SizedBox(height: Insets.sm),
          for (final a in localAccounts) _accountTile(a),
        ],
      ],
    );
  }
}
