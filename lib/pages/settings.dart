import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/platform_detector.dart';
import '../../core/api/auth_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'whos_watching_page.dart';

/// Cross-platform Settings page. Uses sidebar on desktop and single-column list on mobile.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveLayout(
      desktopBuilder: () => const _SettingsDesktop(),
      mobileBuilder: () => const _SettingsMobile(),
    );
  }
}

// --- Desktop layout: sidebar + content ---

class _SettingsDesktop extends ConsumerStatefulWidget {
  const _SettingsDesktop();

  @override
  ConsumerState<_SettingsDesktop> createState() => _SettingsDesktopState();
}

class _SettingsDesktopState extends ConsumerState<_SettingsDesktop> {
  int _selectedSection = 0;

  static const _sections = [
    ('General', Icons.tune),
    ('Playback', Icons.play_circle_outline),
    ('Subtitles', Icons.subtitles_outlined),
    ('Audio', Icons.volume_up_outlined),
    ('Network', Icons.wifi_outlined),
    ('About', Icons.info_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          right: BorderSide(
            color: AppColors.divider.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Settings',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: AppColors.divider.withValues(alpha: 0.5),
            height: 1,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                final isSelected = _selectedSection == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedSection = index),
                      child: AnimatedContainer(
                        duration: AppTheme.durationFast,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              section.$2,
                              color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.textSecondary,
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              section.$1,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final message = await Navigator.of(context).push<String?>(
                        MaterialPageRoute<String?>(
                          builder: (_) => const WhosWatchingPage(),
                        ),
                      );
                      if (message != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                    label: const Text('Switch profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSignOutDialog(context),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Sign out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.12),
                      foregroundColor: AppColors.error,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppTheme.durationNormal)
        .slideX(begin: -0.05, end: 0, duration: AppTheme.durationNormal);
  }

  Widget _buildContent() {
    final settings = ref.watch(settingsProvider);

    Widget content;
    switch (_selectedSection) {
      case 0:
        content = _SettingsContentDesktop.buildGeneral(context, ref, settings, _showResetConfirmation);
        break;
      case 1:
        content = _SettingsContentDesktop.buildPlayback(context, ref, settings);
        break;
      case 2:
        content = _SettingsContentDesktop.buildSubtitles(context, ref, settings);
        break;
      case 3:
        content = _SettingsContentDesktop.buildAudio(context, ref, settings);
        break;
      case 4:
        content = _SettingsContentDesktop.buildNetwork(context, ref, settings);
        break;
      case 5:
        content = _SettingsContentDesktop.buildAbout(context, ref);
        break;
      default:
        content = _SettingsContentDesktop.buildGeneral(context, ref, settings, _showResetConfirmation);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: content,
    )
        .animate()
        .fadeIn(duration: AppTheme.durationNormal);
  }

  void _showSignOutDialog(BuildContext context) {
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
      Navigator.pop(context);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
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
              Navigator.pop(context);
              await ref.read(authProvider.notifier).removeProfile(currentProfile!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// Static helpers for desktop settings content (shared structure)
class _SettingsContentDesktop {
  static Widget buildGeneral(BuildContext context, WidgetRef ref, AppSettings settings, VoidCallback onReset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('General', 'Customize your app experience'),
        const SizedBox(height: 24),
        _settingsCard(
          context,
          title: 'Appearance',
          icon: Icons.palette_outlined,
          children: [
            _dropdownTile<ThemeMode>(
              ref,
              title: 'Theme',
              subtitle: settings.themeMode == ThemeMode.system
                  ? 'Follow system'
                  : settings.themeMode == ThemeMode.light
                  ? 'Light'
                  : 'Dark',
              value: settings.themeMode,
              items: [
                const DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                const DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                const DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (v) {
                if (v != null) ref.read(settingsProvider.notifier).setThemeMode(v);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _dropdownTile<ThemeStyle>(
              ref,
              title: 'Theme style',
              subtitle: switch (settings.themeStyle) {
                ThemeStyle.standard => 'Glass dark',
                ThemeStyle.oled => 'Pure black for OLED displays',
                ThemeStyle.coloured => 'Use a separate theme color across the UI',
              },
              value: settings.themeStyle,
              items: const [
                DropdownMenuItem(value: ThemeStyle.standard, child: Text('Default')),
                DropdownMenuItem(value: ThemeStyle.oled, child: Text('OLED')),
                DropdownMenuItem(value: ThemeStyle.coloured, child: Text('Coloured')),
              ],
              onChanged: (v) {
                if (v != null) ref.read(settingsProvider.notifier).setThemeStyle(v);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _dropdownTile<int>(
              ref,
              title: 'Theme color',
              subtitle: accentColorOptions[
                settings.themeColorIndex.clamp(0, accentColorOptions.length - 1)
              ].$2,
              value: settings.themeColorIndex,
              items: accentColorOptions
                  .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                  .toList(),
              onChanged: (v) {
                if (v != null) ref.read(settingsProvider.notifier).setThemeColorIndex(v);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _switchTile(
              context,
              ref,
              title: 'Use system accent',
              subtitle: 'Use device accent color when available',
              value: settings.useSystemAccent,
              onChanged: (v) => ref.read(settingsProvider.notifier).setUseSystemAccent(v),
            ),
            const Divider(color: AppColors.glassBorder),
            _dropdownTile<int>(
              ref,
              title: 'Accent color',
              subtitle: settings.useSystemAccent
                  ? 'Using system'
                  : accentColorOptions[settings.accentColorIndex.clamp(0, accentColorOptions.length - 1)].$2,
              value: settings.accentColorIndex,
              items: accentColorOptions
                  .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                  .toList(),
              onChanged: (v) {
                if (v != null) ref.read(settingsProvider.notifier).setAccentColorIndex(v);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _switchTile(
              context,
              ref,
              title: 'Enable Animations',
              subtitle: 'Show smooth transitions and effects',
              value: settings.enableAnimations,
              onChanged: (v) => ref.read(settingsProvider.notifier).setEnableAnimations(v),
            ),
            const Divider(color: AppColors.glassBorder),
            _switchTile(
              context,
              ref,
              title: 'Reduced Motion',
              subtitle: 'Minimize animations for accessibility',
              value: settings.reducedMotion,
              onChanged: (v) => ref.read(settingsProvider.notifier).setReducedMotion(v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _settingsCard(
          context,
          title: 'Reset',
          icon: Icons.restore,
          children: [
            Text(
              'Reset all settings to their default values.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restore, size: 20),
              label: const Text('Reset to Defaults'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                foregroundColor: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  static Widget _settingsCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  static Widget _switchTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  static Widget _dropdownTile<T>(
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
      ),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: AppColors.surfaceElevated,
        underline: const SizedBox(),
        style: AppTextStyles.bodyMedium,
      ),
    );
  }

  static Widget _sliderTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title, style: AppTextStyles.bodyLarge),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: AppColors.glassBorder,
          onChanged: onChanged,
        ),
      ],
    );
  }

  static Widget buildPlayback(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Playback', 'Configure video playback preferences'),
        const SizedBox(height: 24),
        _settingsCard(
          context,
          title: 'Quality',
          icon: Icons.high_quality,
          children: [
            _dropdownTile<int>(
              ref,
              title: 'Default Video Quality',
              subtitle: 'Preferred resolution for streaming',
              value: settings.defaultVideoQuality,
              items: videoQualityOptions
                  .map((q) => DropdownMenuItem(value: q.value, child: Text(q.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) ref.read(settingsProvider.notifier).setDefaultVideoQuality(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _settingsCard(
          context,
          title: 'Auto Play',
          icon: Icons.play_arrow,
          children: [
            _switchTile(
              context,
              ref,
              title: 'Auto Play Next Episode',
              subtitle: 'Automatically play the next episode when one ends',
              value: settings.autoPlayNext,
              onChanged: (v) => ref.read(settingsProvider.notifier).setAutoPlayNext(v),
            ),
            const Divider(color: AppColors.glassBorder),
            _switchTile(
              context,
              ref,
              title: 'Skip Intros',
              subtitle: 'Automatically skip intro sequences',
              value: settings.skipIntros,
              onChanged: (v) => ref.read(settingsProvider.notifier).setSkipIntros(v),
            ),
            const Divider(color: AppColors.glassBorder),
            _switchTile(
              context,
              ref,
              title: 'Skip Credits',
              subtitle: 'Automatically skip end credits',
              value: settings.skipCredits,
              onChanged: (v) => ref.read(settingsProvider.notifier).setSkipCredits(v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _settingsCard(
          context,
          title: 'Skip Duration',
          icon: Icons.fast_forward,
          children: [
            _sliderTile(
              context,
              ref,
              title: 'Forward Skip',
              subtitle: '${settings.forwardSkipDuration} seconds',
              value: settings.forwardSkipDuration.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (v) => ref.read(settingsProvider.notifier).setForwardSkipDuration(v.toInt()),
            ),
            const Divider(color: AppColors.glassBorder),
            _sliderTile(
              context,
              ref,
              title: 'Rewind Skip',
              subtitle: '${settings.rewindSkipDuration} seconds',
              value: settings.rewindSkipDuration.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (v) => ref.read(settingsProvider.notifier).setRewindSkipDuration(v.toInt()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _settingsCard(
          context,
          title: 'Sleep Timer',
          icon: Icons.timer_outlined,
          children: [
            _dropdownTile<int>(
              ref,
              title: 'Stop playback after',
              subtitle: sleepTimerOptions
                  .firstWhere((o) => o.value == settings.sleepTimerMinutes, orElse: () => sleepTimerOptions.first)
                  .label,
              value: settings.sleepTimerMinutes,
              items: sleepTimerOptions
                  .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) ref.read(settingsProvider.notifier).setSleepTimerMinutes(v);
              },
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildSubtitles(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Subtitles', 'Customize subtitle appearance'),
        const SizedBox(height: 24),
        _settingsCard(
          context,
          title: 'Subtitle Options',
          icon: Icons.subtitles,
          children: [
            _switchTile(
              context,
              ref,
              title: 'Enable Subtitles',
              subtitle: 'Show subtitles when available',
              value: settings.subtitlesEnabled,
              onChanged: (v) => ref.read(settingsProvider.notifier).setSubtitlesEnabled(v),
            ),
            const Divider(color: AppColors.glassBorder),
            _dropdownTile<String>(
              ref,
              title: 'Preferred Language',
              subtitle: 'Default subtitle language',
              value: settings.subtitleLanguage,
              items: languageOptions
                  .map((l) => DropdownMenuItem(value: l.code, child: Text(l.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) ref.read(settingsProvider.notifier).setSubtitleLanguage(v);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _settingsCard(
          context,
          title: 'Appearance',
          icon: Icons.text_fields,
          children: [
            _sliderTile(
              context,
              ref,
              title: 'Subtitle Size',
              subtitle: '${(settings.subtitleSize * 100).toInt()}%',
              value: settings.subtitleSize,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (v) => ref.read(settingsProvider.notifier).setSubtitleSize(v),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildAudio(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Audio', 'Configure audio preferences'),
        const SizedBox(height: 24),
        _settingsCard(
          context,
          title: 'Audio Options',
          icon: Icons.audiotrack,
          children: [
            _dropdownTile<String>(
              ref,
              title: 'Preferred Language',
              subtitle: 'Default audio track language',
              value: settings.audioLanguage,
              items: languageOptions
                  .map((l) => DropdownMenuItem(value: l.code, child: Text(l.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) ref.read(settingsProvider.notifier).setAudioLanguage(v);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _switchTile(
              context,
              ref,
              title: 'Normalize Volume',
              subtitle: 'Maintain consistent volume levels',
              value: settings.normalizeVolume,
              onChanged: (v) => ref.read(settingsProvider.notifier).setNormalizeVolume(v),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildNetwork(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Network', 'Configure streaming and caching'),
        const SizedBox(height: 24),
        _settingsCard(
          context,
          title: 'Streaming',
          icon: Icons.stream,
          children: [
            _dropdownTile<int>(
              ref,
              title: 'Max Streaming Bitrate',
              subtitle: 'Limit bandwidth usage',
              value: settings.maxStreamingBitrate,
              items: videoQualityOptions
                  .map((q) => DropdownMenuItem(
                        value: q.bitrate,
                        child: Text('${q.label} (${(q.bitrate / 1000000).toStringAsFixed(0)} Mbps)'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) ref.read(settingsProvider.notifier).setMaxStreamingBitrate(v);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _switchTile(
              context,
              ref,
              title: 'Allow Cellular Streaming',
              subtitle: 'Stream over mobile data',
              value: settings.allowCellularStreaming,
              onChanged: (v) => ref.read(settingsProvider.notifier).setAllowCellularStreaming(v),
            ),
            const Divider(color: AppColors.glassBorder),
            _switchTile(
              context,
              ref,
              title: 'Preload Next Episode',
              subtitle: 'Buffer upcoming content for smooth playback',
              value: settings.preloadNextEpisode,
              onChanged: (v) => ref.read(settingsProvider.notifier).setPreloadNextEpisode(v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _settingsCard(
          context,
          title: 'Cache',
          icon: Icons.storage,
          children: [
            _switchTile(
              context,
              ref,
              title: 'Cache Images',
              subtitle: 'Store images locally for faster loading',
              value: settings.cacheImages,
              onChanged: (v) => ref.read(settingsProvider.notifier).setCacheImages(v),
            ),
            const Divider(color: AppColors.glassBorder),
            _sliderTile(
              context,
              ref,
              title: 'Image Cache Size',
              subtitle: '${settings.imageCacheSize} MB',
              value: settings.imageCacheSize.toDouble(),
              min: 100,
              max: 2000,
              divisions: 19,
              onChanged: (v) => ref.read(settingsProvider.notifier).setImageCacheSize(v.toInt()),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildAbout(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('About', 'App information'),
        const SizedBox(height: 24),
        _settingsCard(
          context,
          title: 'Finar',
          icon: Icons.play_circle_fill,
          children: [
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '...';
                final buildNumber = snapshot.data?.buildNumber ?? '';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Version', style: AppTextStyles.bodyLarge),
                  trailing: Text(
                    buildNumber.isNotEmpty ? '$version+$buildNumber' : version,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                );
              },
            ),
            const Divider(color: AppColors.glassBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Platform', style: AppTextStyles.bodyLarge),
              trailing: Text(
                PlatformDetector.current.name.toUpperCase(),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const Divider(color: AppColors.glassBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('OS Version', style: AppTextStyles.bodyLarge),
              trailing: Text(
                PlatformDetector.osVersion,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _settingsCard(
          context,
          title: 'Server',
          icon: Icons.dns_outlined,
          children: [
            Consumer(
              builder: (context, ref, _) {
                final authState = ref.watch(authProvider);
                final serverUrl = ref.read(authProvider.notifier).serverUrl;
                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Connected Server', style: AppTextStyles.bodyLarge),
                      subtitle: Text(
                        serverUrl ?? 'Not connected',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                    const Divider(color: AppColors.glassBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('User', style: AppTextStyles.bodyLarge),
                      subtitle: Text(
                        authState.user?.name ?? 'Unknown',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _settingsCard(
          context,
          title: 'Links',
          icon: Icons.link,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
              title: Text('Website', style: AppTextStyles.bodyLarge),
              subtitle: Text(
                'https://openlyst.ink/',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => _launchUrl('https://openlyst.ink/'),
            ),
            const Divider(color: AppColors.glassBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code, color: AppColors.accentOrange),
              title: Text('Source Code', style: AppTextStyles.bodyLarge),
              subtitle: Text(
                'GitLab Repository',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => _launchUrl('https://gitlab.com/Openlyst/finar'),
            ),
            const Divider(color: AppColors.glassBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).colorScheme.primary),
              title: Text('Privacy Policy', style: AppTextStyles.bodyLarge),
              subtitle: Text(
                'We do not collect any data',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => _launchUrl('https://gitlab.com/Openlyst/finar/-/blob/main/PRIVACY.md'),
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// --- Mobile layout: AppBar + single list ---

class _SettingsMobile extends ConsumerStatefulWidget {
  const _SettingsMobile();

  @override
  ConsumerState<_SettingsMobile> createState() => _SettingsMobileState();
}

class _SettingsMobileState extends ConsumerState<_SettingsMobile> {
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
          _buildSectionHeader('Playback'),
          const SizedBox(height: 10),
          _buildPlaybackCard(settings),
          const SizedBox(height: 28),
          _buildSectionHeader('Subtitles'),
          const SizedBox(height: 10),
          _buildSubtitlesCard(settings),
          const SizedBox(height: 28),
          _buildSectionHeader('Audio'),
          const SizedBox(height: 10),
          _buildAudioCard(settings),
          const SizedBox(height: 28),
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 10),
          _buildAppearanceCard(settings),
          const SizedBox(height: 28),
          _buildSectionHeader('Network'),
          const SizedBox(height: 10),
          _buildNetworkCard(settings),
          const SizedBox(height: 28),
          _buildSectionHeader('Account'),
          const SizedBox(height: 10),
          _buildAccountCard(),
          const SizedBox(height: 28),
          _buildSectionHeader('About'),
          const SizedBox(height: 10),
          _buildAboutCard(),
          const SizedBox(height: 28),
          Center(
            child: TextButton.icon(
              onPressed: _showResetConfirmation,
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

  Widget _buildPlaybackCard(AppSettings settings) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _switchTile('Auto Play Next', 'Automatically play next episode', settings.autoPlayNext,
              (v) => ref.read(settingsProvider.notifier).setAutoPlayNext(v)),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _switchTile('Skip Intros', 'Automatically skip intros', settings.skipIntros,
              (v) => ref.read(settingsProvider.notifier).setSkipIntros(v)),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _switchTile('Skip Credits', 'Automatically skip credits', settings.skipCredits,
              (v) => ref.read(settingsProvider.notifier).setSkipCredits(v)),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _dropdownTile<int>(
            'Default Quality',
            settings.defaultVideoQuality,
            videoQualityOptions
                .map((q) => DropdownMenuItem(value: q.value, child: Text(q.label)))
                .toList(),
            (v) {
              if (v != null) ref.read(settingsProvider.notifier).setDefaultVideoQuality(v);
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _dropdownTile<int>(
            'Sleep Timer',
            settings.sleepTimerMinutes,
            sleepTimerOptions
                .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
                .toList(),
            (v) {
              if (v != null) ref.read(settingsProvider.notifier).setSleepTimerMinutes(v);
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
          _switchTile('Enable Subtitles', 'Show subtitles when available', settings.subtitlesEnabled,
              (v) => ref.read(settingsProvider.notifier).setSubtitlesEnabled(v)),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _dropdownTile<String>(
            'Language',
            settings.subtitleLanguage,
            languageOptions
                .map((l) => DropdownMenuItem(value: l.code, child: Text(l.name)))
                .toList(),
            (v) {
              if (v != null) ref.read(settingsProvider.notifier).setSubtitleLanguage(v);
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
          _dropdownTile<String>(
            'Preferred Language',
            settings.audioLanguage,
            languageOptions
                .map((l) => DropdownMenuItem(value: l.code, child: Text(l.name)))
                .toList(),
            (v) {
              if (v != null) ref.read(settingsProvider.notifier).setAudioLanguage(v);
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _switchTile('Normalize Volume', 'Keep consistent volume levels', settings.normalizeVolume,
              (v) => ref.read(settingsProvider.notifier).setNormalizeVolume(v)),
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
          _dropdownTile<ThemeMode>(
            'Theme',
            settings.themeMode,
            [
              const DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              const DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              const DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
            (v) {
              if (v != null) ref.read(settingsProvider.notifier).setThemeMode(v);
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _dropdownTile<ThemeStyle>(
            'Theme style',
            settings.themeStyle,
            const [
              DropdownMenuItem(value: ThemeStyle.standard, child: Text('Default')),
              DropdownMenuItem(value: ThemeStyle.oled, child: Text('OLED')),
              DropdownMenuItem(value: ThemeStyle.coloured, child: Text('Coloured')),
            ],
            (v) {
              if (v != null) ref.read(settingsProvider.notifier).setThemeStyle(v);
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _dropdownTile<int>(
            'Theme color',
            settings.themeColorIndex,
            accentColorOptions
                .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                .toList(),
            (v) {
              if (v != null) ref.read(settingsProvider.notifier).setThemeColorIndex(v);
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _switchTile('Use system accent', 'Use device accent', settings.useSystemAccent,
              (v) => ref.read(settingsProvider.notifier).setUseSystemAccent(v)),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _dropdownTile<int>(
            'Accent color',
            settings.accentColorIndex,
            accentColorOptions
                .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                .toList(),
            (v) {
              if (v != null) ref.read(settingsProvider.notifier).setAccentColorIndex(v);
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _switchTile('Enable Animations', 'Show smooth transitions', settings.enableAnimations,
              (v) => ref.read(settingsProvider.notifier).setEnableAnimations(v)),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _switchTile('Reduced Motion', 'Minimize animations', settings.reducedMotion,
              (v) => ref.read(settingsProvider.notifier).setReducedMotion(v)),
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
          _switchTile('Allow Cellular Streaming', 'Stream over mobile data',
              settings.allowCellularStreaming,
              (v) => ref.read(settingsProvider.notifier).setAllowCellularStreaming(v)),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _switchTile('Preload Next Episode', 'Buffer upcoming content', settings.preloadNextEpisode,
              (v) => ref.read(settingsProvider.notifier).setPreloadNextEpisode(v)),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          _switchTile('Cache Images', 'Store images locally', settings.cacheImages,
              (v) => ref.read(settingsProvider.notifier).setCacheImages(v)),
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
            leading: Icon(Icons.swap_horiz_rounded, color: Theme.of(context).colorScheme.primary),
            title: const Text('Switch profile'),
            subtitle: Text(
              'Choose a different account',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 22),
            onTap: () async {
              final message = await Navigator.of(context).push<String?>(
                MaterialPageRoute<String?>(builder: (_) => const WhosWatchingPage()),
              );
              if (message != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
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
            onTap: _showSignOutDialog,
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
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              );
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          ListTile(
            title: const Text('Platform'),
            trailing: Text(
              PlatformDetector.current.name.toUpperCase(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
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
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              );
            },
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          ListTile(
            leading: Icon(Icons.language_rounded, color: Theme.of(context).colorScheme.primary),
            title: const Text('Website'),
            subtitle: Text(
              'https://openlyst.ink/',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, size: 20),
            onTap: () => _launchUrl('https://openlyst.ink/'),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          ListTile(
            leading: const Icon(Icons.code_rounded, color: AppColors.accentOrange),
            title: const Text('Source Code'),
            subtitle: Text(
              'GitLab Repository',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, size: 20),
            onTap: () => _launchUrl('https://gitlab.com/Openlyst/finar'),
          ),
          Divider(color: AppColors.divider.withValues(alpha: 0.5), height: 1),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).colorScheme.primary),
            title: const Text('Privacy Policy'),
            subtitle: Text(
              'We do not collect any data',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
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

  Widget _switchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      inactiveThumbColor: AppColors.textSecondary,
      inactiveTrackColor: AppColors.divider.withValues(alpha: 0.3),
    );
  }

  Widget _dropdownTile<T>(
    String title,
    T value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> onChanged,
  ) {
    return ListTile(
      title: Text(title, style: AppTextStyles.bodyLarge),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: AppColors.surfaceElevated,
        underline: const SizedBox(),
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
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
              child: const Icon(Icons.refresh_rounded, color: AppColors.warning, size: 24),
            ),
            const SizedBox(width: 14),
            const Text('Reset Settings'),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
