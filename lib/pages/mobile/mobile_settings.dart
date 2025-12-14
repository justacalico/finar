import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/platform_detector.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // UI Mode Section
          _buildSectionHeader('Interface Mode'),
          const SizedBox(height: 8),
          _buildUiModeCard(settings),
          
          const SizedBox(height: 24),
          
          // Playback Section
          _buildSectionHeader('Playback'),
          const SizedBox(height: 8),
          _buildPlaybackCard(settings),
          
          const SizedBox(height: 24),
          
          // Subtitles Section
          _buildSectionHeader('Subtitles'),
          const SizedBox(height: 8),
          _buildSubtitlesCard(settings),
          
          const SizedBox(height: 24),
          
          // Audio Section
          _buildSectionHeader('Audio'),
          const SizedBox(height: 8),
          _buildAudioCard(settings),
          
          const SizedBox(height: 24),
          
          // Appearance Section
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 8),
          _buildAppearanceCard(settings),
          
          const SizedBox(height: 24),
          
          // Network Section
          _buildSectionHeader('Network'),
          const SizedBox(height: 8),
          _buildNetworkCard(settings),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader('About'),
          const SizedBox(height: 8),
          _buildAboutCard(),
          
          const SizedBox(height: 24),
          
          // Reset button
          Center(
            child: TextButton.icon(
              onPressed: () => _showResetConfirmation(),
              icon: const Icon(Icons.restore, color: AppColors.warning),
              label: const Text('Reset to Defaults', style: TextStyle(color: AppColors.warning)),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildUiModeCard(AppSettings settings) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Force a specific UI layout',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          ..._buildUiModeOptions(settings),
        ],
      ),
    );
  }

  List<Widget> _buildUiModeOptions(AppSettings settings) {
    final modes = [
      (UiMode.auto, 'Auto', Icons.auto_awesome, _getAutoModeDescription()),
      (UiMode.desktop, 'Desktop', Icons.desktop_windows, 'Wide layout with sidebar'),
      (UiMode.mobile, 'Mobile', Icons.phone_android, 'Compact touch layout'),
      (UiMode.tv, 'TV', Icons.tv, 'Large remote-friendly UI'),
    ];

    return modes.map((mode) {
      final isSelected = settings.forcedUiMode == mode.$1;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => ref.read(settingsProvider.notifier).setForcedUiMode(mode.$1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.glassBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  mode.$3,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.$2,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
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
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  String _getAutoModeDescription() {
    if (PlatformDetector.isTV) {
      return 'Currently: TV (detected)';
    } else if (PlatformDetector.isDesktop) {
      return 'Currently: Desktop (detected)';
    } else {
      return 'Currently: Mobile (detected)';
    }
  }

  Widget _buildPlaybackCard(AppSettings settings) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Auto Play Next',
            subtitle: 'Automatically play next episode',
            value: settings.autoPlayNext,
            onChanged: (v) => ref.read(settingsProvider.notifier).setAutoPlayNext(v),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSwitchTile(
            title: 'Skip Intros',
            subtitle: 'Automatically skip intros',
            value: settings.skipIntros,
            onChanged: (v) => ref.read(settingsProvider.notifier).setSkipIntros(v),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSwitchTile(
            title: 'Skip Credits',
            subtitle: 'Automatically skip credits',
            value: settings.skipCredits,
            onChanged: (v) => ref.read(settingsProvider.notifier).setSkipCredits(v),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildDropdownTile<int>(
            title: 'Default Quality',
            value: settings.defaultVideoQuality,
            items: videoQualityOptions.map((q) =>
              DropdownMenuItem(value: q.value, child: Text(q.label))
            ).toList(),
            onChanged: (v) {
              if (v != null) ref.read(settingsProvider.notifier).setDefaultVideoQuality(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitlesCard(AppSettings settings) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Enable Subtitles',
            subtitle: 'Show subtitles when available',
            value: settings.subtitlesEnabled,
            onChanged: (v) => ref.read(settingsProvider.notifier).setSubtitlesEnabled(v),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildDropdownTile<String>(
            title: 'Language',
            value: settings.subtitleLanguage,
            items: languageOptions.map((l) =>
              DropdownMenuItem(value: l.code, child: Text(l.name))
            ).toList(),
            onChanged: (v) {
              if (v != null) ref.read(settingsProvider.notifier).setSubtitleLanguage(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAudioCard(AppSettings settings) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildDropdownTile<String>(
            title: 'Preferred Language',
            value: settings.audioLanguage,
            items: languageOptions.map((l) =>
              DropdownMenuItem(value: l.code, child: Text(l.name))
            ).toList(),
            onChanged: (v) {
              if (v != null) ref.read(settingsProvider.notifier).setAudioLanguage(v);
            },
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSwitchTile(
            title: 'Normalize Volume',
            subtitle: 'Keep consistent volume levels',
            value: settings.normalizeVolume,
            onChanged: (v) => ref.read(settingsProvider.notifier).setNormalizeVolume(v),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(AppSettings settings) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Enable Animations',
            subtitle: 'Show smooth transitions',
            value: settings.enableAnimations,
            onChanged: (v) => ref.read(settingsProvider.notifier).setEnableAnimations(v),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSwitchTile(
            title: 'Reduced Motion',
            subtitle: 'Minimize animations',
            value: settings.reducedMotion,
            onChanged: (v) => ref.read(settingsProvider.notifier).setReducedMotion(v),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkCard(AppSettings settings) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Allow Cellular Streaming',
            subtitle: 'Stream over mobile data',
            value: settings.allowCellularStreaming,
            onChanged: (v) => ref.read(settingsProvider.notifier).setAllowCellularStreaming(v),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSwitchTile(
            title: 'Preload Next Episode',
            subtitle: 'Buffer upcoming content',
            value: settings.preloadNextEpisode,
            onChanged: (v) => ref.read(settingsProvider.notifier).setPreloadNextEpisode(v),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSwitchTile(
            title: 'Cache Images',
            subtitle: 'Store images locally',
            value: settings.cacheImages,
            onChanged: (v) => ref.read(settingsProvider.notifier).setCacheImages(v),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          const Divider(color: AppColors.glassBorder, height: 1),
          ListTile(
            title: const Text('Platform'),
            trailing: Text(
              PlatformDetector.current.name.toUpperCase(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
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
          const Divider(color: AppColors.glassBorder, height: 1),
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.primary),
            title: const Text('Website'),
            subtitle: Text(
              'openlyst.onrender.com',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => _launchUrl('https://openlyst.onrender.com'),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          ListTile(
            leading: const Icon(Icons.code, color: AppColors.accentOrange),
            title: const Text('Source Code'),
            subtitle: Text(
              'GitLab Repository',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => _launchUrl('https://gitlab.com/Openlyst/finar'),
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
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
