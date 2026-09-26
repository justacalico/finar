import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/page_header.dart';
import '../widgets/settings_widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _bitrates = {
    0: 'Auto',
    20000000: '20 Mbps',
    10000000: '10 Mbps',
    6000000: '6 Mbps',
    4000000: '4 Mbps',
    1500000: '1.5 Mbps',
    720000: '720 Kbps',
  };

  static const _themeNames = {
    AppThemeMode.system: 'System',
    AppThemeMode.light: 'Light',
    AppThemeMode.dark: 'Dark',
    AppThemeMode.oled: 'OLED',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final session = ref.watch(sessionProvider);
    final account =
        session is SignedIn ? session.account : null;

    return ListView(
      padding: const EdgeInsets.only(bottom: Insets.xl),
      children: [
        const PageHeader(title: 'Settings'),
        SettingsGroup(
          title: 'Appearance',
          children: [
            SettingDropdown<AppThemeMode>(
              title: 'Theme',
              value: settings.themeMode,
              options: _themeNames,
              onChanged: notifier.setThemeMode,
            ),
            SettingDropdown<String>(
              title: 'Accent color',
              value: settings.accentName,
              options: {
                for (final name in kAccentOptions.keys)
                  name: name
              },
              onChanged: notifier.setAccent,
            ),
            SettingSwitch(
              title: 'Show artwork',
              subtitle: 'Posters and backdrops across the app',
              value: settings.showThumbnails,
              onChanged: notifier.setShowThumbnails,
            ),
          ],
        ),
        SettingsGroup(
          title: 'Playback',
          children: [
            SettingSwitch(
              title: 'Autoplay next episode',
              value: settings.autoplayNext,
              onChanged: notifier.setAutoplayNext,
            ),
            SettingSwitch(
              title: 'Resume where you left off',
              value: settings.rememberPosition,
              onChanged: notifier.setRememberPosition,
            ),
            SettingDropdown<int>(
              title: 'Streaming quality',
              value: settings.maxStreamingBitrate,
              options: _bitrates,
              onChanged: notifier.setMaxBitrate,
            ),
          ],
        ),
        SettingsGroup(
          title: 'Subtitles',
          children: [
            SettingSwitch(
              title: 'Enabled by default',
              value: settings.subtitlesEnabled,
              onChanged: notifier.setSubtitlesEnabled,
            ),
            SettingSlider(
              title: 'Size',
              value: settings.subtitleSize,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              label: (v) => '${(v * 100).round()}%',
              onChanged: notifier.setSubtitleSize,
            ),
            SettingSlider(
              title: 'Background',
              value: settings.subtitleBackground,
              min: 0,
              max: 1,
              divisions: 10,
              label: (v) => '${(v * 100).round()}%',
              onChanged: notifier.setSubtitleBackground,
            ),
          ],
        ),
        SettingsGroup(
          title: 'Downloads',
          children: [
            SettingSwitch(
              title: 'Wi-Fi only',
              subtitle: 'Pause downloads on mobile data',
              value: settings.downloadWifiOnly,
              onChanged: notifier.setDownloadWifiOnly,
            ),
          ],
        ),
        SettingsGroup(
          title: 'Account',
          children: [
            if (account != null)
              SettingTile(
                icon: Icons.person_outline,
                title: account.userName,
                subtitle:
                    '${account.serverName.isEmpty ? 'Jellyfin server' : account.serverName}  •  ${account.serverUrl}',
              ),
            SettingTile(
              icon: Icons.switch_account_outlined,
              title: 'Switch account',
              subtitle: 'Sign in to another server or user',
              onTap: () => ref
                  .read(sessionProvider.notifier)
                  .signOut(),
            ),
            SettingTile(
              icon: Icons.logout,
              title: 'Sign out',
              destructive: true,
              onTap: () => ref
                  .read(sessionProvider.notifier)
                  .signOut(),
            ),
          ],
        ),
        SettingsGroup(
          title: 'About',
          children: [
            const _VersionTile(),
            SettingTile(
              icon: Icons.code,
              title: 'Source code',
              subtitle: 'gitlab.com/Openlyst/finar',
              onTap: () => launchUrl(
                  Uri.parse('https://gitlab.com/Openlyst/finar')),
            ),
            SettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              onTap: () => launchUrl(Uri.parse(
                  'https://gitlab.com/Openlyst/finar/-/blob/main/PRIVACY.md')),
            ),
            const SettingTile(
              icon: Icons.movie_outlined,
              title: 'Powered by Jellyfin',
              subtitle: 'The free software media system',
            ),
          ],
        ),
      ],
    );
  }
}

class _VersionTile extends StatefulWidget {
  const _VersionTile();

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) {
        setState(() =>
            _version = '${p.version}+${p.buildNumber}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      icon: Icons.info_outline,
      title: 'Finar',
      subtitle: _version.isEmpty ? 'Version' : 'Version $_version',
    );
  }
}
