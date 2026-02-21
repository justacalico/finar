import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/auth_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/platform_detector.dart';
import '../../providers/providers.dart';
import '../whos_watching_page.dart';

class MobileSettings extends ConsumerStatefulWidget {
  const MobileSettings({super.key});

  @override
  ConsumerState<MobileSettings> createState() => _MobileSettingsState();
}

class _MobileSettingsState extends ConsumerState<MobileSettings> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        title: Text(
          'Settings',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // UI Mode Section
          _buildSectionHeader('Interface Mode'),
          const SizedBox(height: 10),
          _buildUiModeCard(settings),

          const SizedBox(height: 28),

          // Playback Section
          _buildSectionHeader('Playback'),
          const SizedBox(height: 10),
          _buildPlaybackCard(settings),

          const SizedBox(height: 28),

          // Subtitles Section
          _buildSectionHeader('Subtitles'),
          const SizedBox(height: 10),
          _buildSubtitlesCard(settings),

          const SizedBox(height: 28),

          // Audio Section
          _buildSectionHeader('Audio'),
          const SizedBox(height: 10),
          _buildAudioCard(settings),

          const SizedBox(height: 28),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 10),
          _buildAppearanceCard(settings),

          const SizedBox(height: 28),

          // Network Section
          _buildSectionHeader('Network'),
          const SizedBox(height: 10),
          _buildNetworkCard(settings),

          const SizedBox(height: 28),

          // Account Section
          _buildSectionHeader('Account'),
          const SizedBox(height: 10),
          _buildAccountCard(),

          const SizedBox(height: 28),

          // About Section
          _buildSectionHeader('About'),
          const SizedBox(height: 10),
          _buildAboutCard(),

          const SizedBox(height: 28),

          // Reset button
          Center(
            child: TextButton.icon(
              onPressed: () => _showResetConfirmation(),
              icon: const Icon(Icons.restore_rounded, color: AppColors.warning),
              label: const Text(
                'Reset to Defaults',
                style: TextStyle(color: AppColors.warning),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildUiModeCard(AppSettings settings) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Force a specific UI layout',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 18),
          ..._buildUiModeOptions(settings),
        ],
      ),
    );
  }

  List<Widget> _buildUiModeOptions(AppSettings settings) {
    final modes = [
      (
        UiMode.auto,
        'Auto',
        Icons.auto_awesome_rounded,
        _getAutoModeDescription(),
      ),
      (
        UiMode.desktop,
        'Desktop',
        Icons.desktop_windows_rounded,
        'Wide layout with sidebar',
      ),
      (
        UiMode.mobile,
        'Mobile',
        Icons.phone_android_rounded,
        'Compact touch layout',
      ),
    ];

    return modes.map((mode) {
      final isSelected = settings.forcedUiMode == mode.$1;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () =>
              ref.read(settingsProvider.notifier).setForcedUiMode(mode.$1),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.divider.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    mode.$3,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.$2,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.$4,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  String _getAutoModeDescription() {
    if (PlatformDetector.isDesktop) {
      return 'Currently: Desktop (detected)';
    } else {
      return 'Currently: Mobile (detected)';
    }
  }

  Widget _buildPlaybackCard(AppSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Auto Play Next',
            subtitle: 'Automatically play next episode',
            value: settings.autoPlayNext,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setAutoPlayNext(v),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _buildSwitchTile(
            title: 'Skip Intros',
            subtitle: 'Automatically skip intros',
            value: settings.skipIntros,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setSkipIntros(v),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _buildSwitchTile(
            title: 'Skip Credits',
            subtitle: 'Automatically skip credits',
            value: settings.skipCredits,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setSkipCredits(v),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _buildDropdownTile<int>(
            title: 'Default Quality',
            value: settings.defaultVideoQuality,
            items: videoQualityOptions
                .map(
                  (q) => DropdownMenuItem(value: q.value, child: Text(q.label)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ref.read(settingsProvider.notifier).setDefaultVideoQuality(v);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitlesCard(AppSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Enable Subtitles',
            subtitle: 'Show subtitles when available',
            value: settings.subtitlesEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setSubtitlesEnabled(v),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _buildDropdownTile<String>(
            title: 'Language',
            value: settings.subtitleLanguage,
            items: languageOptions
                .map(
                  (l) => DropdownMenuItem(value: l.code, child: Text(l.name)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ref.read(settingsProvider.notifier).setSubtitleLanguage(v);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCard(AppSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildDropdownTile<String>(
            title: 'Preferred Language',
            value: settings.audioLanguage,
            items: languageOptions
                .map(
                  (l) => DropdownMenuItem(value: l.code, child: Text(l.name)),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) {
                ref.read(settingsProvider.notifier).setAudioLanguage(v);
              }
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _buildSwitchTile(
            title: 'Normalize Volume',
            subtitle: 'Keep consistent volume levels',
            value: settings.normalizeVolume,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setNormalizeVolume(v),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(AppSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Enable Animations',
            subtitle: 'Show smooth transitions',
            value: settings.enableAnimations,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setEnableAnimations(v),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _buildSwitchTile(
            title: 'Reduced Motion',
            subtitle: 'Minimize animations',
            value: settings.reducedMotion,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setReducedMotion(v),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkCard(AppSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Allow Cellular Streaming',
            subtitle: 'Stream over mobile data',
            value: settings.allowCellularStreaming,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .setAllowCellularStreaming(v),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _buildSwitchTile(
            title: 'Preload Next Episode',
            subtitle: 'Buffer upcoming content',
            value: settings.preloadNextEpisode,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setPreloadNextEpisode(v),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _buildSwitchTile(
            title: 'Cache Images',
            subtitle: 'Store images locally',
            value: settings.cacheImages,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setCacheImages(v),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
            title: const Text('Switch profile'),
            subtitle: Text(
              'Choose a different account',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 22),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WhosWatchingPage(),
                ),
              );
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: AppColors.error),
            title: Text(
              'Sign out',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
            ),
            subtitle: Text(
              'Remove this profile from device',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            onTap: () => _showSignOutDialog(),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    final profiles = ref.read(savedProfilesProvider);
    final user = ref.read(currentUserProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl;
    if (user == null || serverUrl == null) return;
    SavedProfile? currentProfile;
    for (final p in profiles) {
      if (p.userId == user.id && p.serverUrl == serverUrl) {
        currentProfile = p;
        break;
      }
    }
    if (currentProfile == null) {
      ref.read(authProvider.notifier).logout();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign out'),
        content: const Text(
          'Sign out and remove this profile from this device? You can add it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).removeProfile(currentProfile!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '...';
              final buildNumber = snapshot.data?.buildNumber ?? '';
              return ListTile(
                title: const Text('Version'),
                trailing: Text(
                  buildNumber.isNotEmpty ? '$version+$buildNumber' : version,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          ListTile(
            title: const Text('Platform'),
            trailing: Text(
              PlatformDetector.current.name.toUpperCase(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          Consumer(
            builder: (context, ref, _) {
              final serverUrl = ref.read(authProvider.notifier).serverUrl;
              return ListTile(
                title: const Text('Server'),
                subtitle: Text(
                  serverUrl ?? 'Not connected',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          ListTile(
            leading: const Icon(
              Icons.language_rounded,
              color: AppColors.primary,
            ),
            title: const Text('Website'),
            subtitle: Text(
              'https://openlyst.ink/',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, size: 20),
            onTap: () => _launchUrl('https://openlyst.ink/'),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          ListTile(
            leading: const Icon(
              Icons.code_rounded,
              color: AppColors.accentOrange,
            ),
            title: const Text('Source Code'),
            subtitle: Text(
              'GitLab Repository',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, size: 20),
            onTap: () => _launchUrl('https://gitlab.com/Openlyst/finar'),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          ListTile(
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: AppColors.primary,
            ),
            title: const Text('Privacy Policy'),
            subtitle: Text(
              'We do not collect any data',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, size: 20),
            onTap: () => _launchUrl('https://gitlab.com/Openlyst/finar/-/blob/main/PRIVACY.md'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
      inactiveThumbColor: AppColors.textSecondary,
      inactiveTrackColor: AppColors.divider.withValues(alpha: 0.3),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: AppTextStyles.bodyLarge),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: AppColors.surfaceElevated,
        underline: const SizedBox(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Text('Reset Settings'),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Settings reset to defaults'),
                  backgroundColor: AppColors.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
