import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/storage/settings_store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/update_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/media_image.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _AppearanceSection(),
        const _LanguageSection(),
        const _AccountSection(),
        const _AboutSection(),
        const SizedBox(height: 24),
        Center(
          child: Text(kAppName,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title,
                style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700)),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return _Section(
      title: l10n.appearance,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Icon(Icons.brightness_6_outlined,
                  size: 20,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Text(l10n.themeMode,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppThemeMode>(
              segments: [
                ButtonSegment(
                    value: AppThemeMode.system,
                    label: Text(l10n.system),
                    icon: const Icon(Icons.settings_suggest_outlined)),
                ButtonSegment(
                    value: AppThemeMode.light,
                    label: Text(l10n.light),
                    icon: const Icon(Icons.light_mode_outlined)),
                ButtonSegment(
                    value: AppThemeMode.dark,
                    label: Text(l10n.dark),
                    icon: const Icon(Icons.dark_mode_outlined)),
                ButtonSegment(
                    value: AppThemeMode.oled,
                    label: Text(l10n.oled),
                    icon: const Icon(Icons.contrast)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) =>
                  notifier.setThemeMode(s.first),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Icon(Icons.palette_outlined,
                  size: 20,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 14),
              Text(l10n.accentColour,
                  style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              for (final color in AppTheme.accents)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => notifier.setAccentColor(color),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: settings.accentColor == color
                            ? Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                                width: 2)
                            : null,
                      ),
                      child: settings.accentColor == color
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageSection extends ConsumerWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return _Section(
      title: l10n.language,
      children: [
        ListTile(
          leading: const Icon(Icons.translate),
          title: Text(l10n.language),
          trailing: DropdownButton<String?>(
            value: settings.locale,
            underline: const SizedBox.shrink(),
            onChanged: (v) => notifier.setLocale(v),
            items: [
              DropdownMenuItem(
                  value: null, child: Text(l10n.systemDefault)),
              const DropdownMenuItem(
                  value: 'en_GB', child: Text('Traditional English')),
              const DropdownMenuItem(
                  value: 'zh', child: Text('简体中文')),
              const DropdownMenuItem(
                  value: 'ru', child: Text('Русский')),
              const DropdownMenuItem(
                  value: 'ga', child: Text('Gaeilge')),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final client = ref.watch(jellyfinClientProvider);
    if (session == null) return const SizedBox.shrink();
    return _Section(
      title: l10n.account,
      children: [
        ListTile(
          leading: SizedBox(
            width: 40,
            height: 40,
            child: MediaImage(
              url: client?.userImageUrl(session.user, maxWidth: 80),
              icon: Icons.person_outline,
            ),
          ),
          title: Text(session.user.name),
          subtitle:
              Text(l10n.signedInAs(session.user.name)),
        ),
        ListTile(
          leading: const Icon(Icons.dns_outlined),
          title: Text(session.serverName.isEmpty
              ? session.serverUrl
              : session.serverName),
          subtitle: Text(session.serverUrl),
        ),
        ListTile(
          leading: const Icon(Icons.switch_account_outlined),
          title: Text(l10n.switchProfile),
          onTap: () => context.go('/profiles'),
        ),
        ListTile(
          leading: Icon(Icons.logout,
              color: Theme.of(context).colorScheme.error),
          title: Text(l10n.signOut,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error)),
          onTap: () async {
            await ref.read(sessionProvider.notifier).signOut();
            if (context.mounted) context.go('/connect');
          },
        ),
      ],
    );
  }
}

class _AboutSection extends ConsumerStatefulWidget {
  const _AboutSection();

  @override
  ConsumerState<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends ConsumerState<_AboutSection> {
  String _version = kAppVersion;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted && info.version.isNotEmpty) {
        setState(() => _version = info.version);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final update = ref.watch(updateProvider);
    final scheme = Theme.of(context).colorScheme;
    return _Section(
      title: l10n.about,
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(kAppName),
          subtitle: Text('${l10n.version} $_version'),
        ),
        ListTile(
          leading: const Icon(Icons.system_update_alt),
          title: Text(l10n.checkForUpdates),
          subtitle: switch (update) {
            UpdateChecking() => Text(l10n.checkingForUpdates),
            UpdateUpToDate() => Text(l10n.upToDate),
            UpdateAvailable(:final update) => Text(
                l10n.updateAvailable(update.version.toString()),
                style: TextStyle(color: scheme.primary)),
            UpdateFailed() => Text(l10n.updateCheckFailed,
                style: TextStyle(color: scheme.error)),
            _ => null,
          },
          trailing: switch (update) {
            UpdateChecking() => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            UpdateAvailable() => null,
            _ => null,
          },
          onTap: update is UpdateChecking
              ? null
              : () =>
                  ref.read(updateProvider.notifier).check(_version),
        ),
        if (update is UpdateAvailable)
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(l10n.viewRelease),
            subtitle: Text(update.update.url.toString()),
            onTap: () =>
                launchUrl(update.update.url,
                    mode: LaunchMode.externalApplication),
          ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(l10n.allReleases),
          onTap: () => launchUrl(Uri.parse(kGitLabReleases),
              mode: LaunchMode.externalApplication),
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: Text(l10n.sourceCode),
          onTap: () => launchUrl(Uri.parse(kGitLabRepo),
              mode: LaunchMode.externalApplication),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l10n.privacyPolicy),
          onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl),
              mode: LaunchMode.externalApplication),
        ),
        ListTile(
          leading: const Icon(Icons.article_outlined),
          title: Text(l10n.licenses),
          onTap: () => showLicensePage(
              context: context,
              applicationName: kAppName,
              applicationVersion: _version),
        ),
      ],
    );
  }
}
