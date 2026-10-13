import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/jellyfin_client.dart';
import '../../core/storage/session_store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/core_providers.dart';
import '../../providers/session_provider.dart';

class ProfilesPage extends ConsumerWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final profiles = ref.watch(profilesProvider);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                    width: 64,
                    height: 64,
                    child: SvgPicture.asset('icon.svg')),
                const SizedBox(height: 20),
                Text(l10n.whoIsWatching,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 28),
                if (profiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l10n.connectSubtitle,
                        style: TextStyle(
                            color: scheme.onSurfaceVariant)),
                  )
                else
                  Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: [
                      for (final profile in profiles)
                        _ProfileCard(profile: profile),
                      _AddProfileCard(label: l10n.addAccount),
                    ],
                  ),
                const SizedBox(height: 20),
                if (profiles.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => context.go('/connect'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addAccount),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.profile});

  final SavedProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final deviceId = ref.watch(deviceIdProvider).valueOrNull;
    final client = deviceId == null
        ? null
        : JellyfinClient(
            serverUrl: profile.serverUrl, deviceId: deviceId);
    final avatarUrl = profile.imageTag == null || client == null
        ? null
        : Uri.parse(
            '${profile.serverUrl}/Users/${profile.userId}/Images/Primary?tag=${profile.imageTag}&maxWidth=96');
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final ok = await ref
            .read(sessionProvider.notifier)
            .signInWithProfile(profile);
        if (!context.mounted) return;
        context.go(ok ? '/home' : '/connect');
      },
      onLongPress: () => ref
          .read(profilesProvider.notifier)
          .remove(profile),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                image: avatarUrl == null
                    ? null
                    : DecorationImage(
                        image: NetworkImage(avatarUrl.toString()),
                        fit: BoxFit.cover),
              ),
              child: avatarUrl == null
                  ? Icon(Icons.person_outline,
                      size: 36, color: scheme.outline)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(profile.userName,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(profile.serverName,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _AddProfileCard extends StatelessWidget {
  const _AddProfileCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.go('/connect'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  Icon(Icons.add, size: 32, color: scheme.outline),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
