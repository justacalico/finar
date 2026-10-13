import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/server_url.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';

final connectStateProvider =
    StateProvider<({bool loading, String? error})>(
        (ref) => (loading: false, error: null));

class ConnectPage extends ConsumerStatefulWidget {
  const ConnectPage({super.key});

  @override
  ConsumerState<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends ConsumerState<ConnectPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final l10n = AppLocalizations.of(context);
    final url = ServerUrl.normalize(_controller.text);
    final status = ref.read(connectStateProvider.notifier);
    if (url == null) {
      status.state = (loading: false, error: l10n.invalidServerUrl);
      return;
    }
    status.state = (loading: true, error: null);
    try {
      await ref.read(sessionProvider.notifier).probeServer(url);
      ref.read(pendingServerProvider.notifier).state = url;
      status.state = (loading: false, error: null);
      if (mounted) context.go('/login');
    } catch (_) {
      status.state =
          (loading: false, error: l10n.couldNotReachServer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final status = ref.watch(connectStateProvider);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                      Center(
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: SvgPicture.asset('icon.svg'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.connectToServer,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(l10n.connectSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: l10n.serverUrl,
                          hintText: l10n.serverUrlHint,
                          prefixIcon: const Icon(Icons.dns_outlined),
                        ),
                        onSubmitted: (_) => _connect(),
                      ),
                      if (status.error != null) ...[
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
                                  size: 18,
                                  color: scheme.onErrorContainer),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(status.error!,
                                    style: TextStyle(
                                        color: scheme
                                            .onErrorContainer)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed:
                            status.loading ? null : _connect,
                        child: status.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : Text(l10n.connect),
                      ),
                      TextButton(
                        onPressed: () => context.go('/profiles'),
                        child: Text(l10n.whoIsWatching),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
