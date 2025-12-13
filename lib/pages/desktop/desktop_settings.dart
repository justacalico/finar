import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/platform_detector.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/widgets.dart';

class DesktopSettings extends ConsumerStatefulWidget {
  const DesktopSettings({super.key});

  @override
  ConsumerState<DesktopSettings> createState() => _DesktopSettingsState();
}

class _DesktopSettingsState extends ConsumerState<DesktopSettings> {
  int _selectedSection = 0;

  final _sections = [
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
          // Settings sidebar
          _buildSidebar(),
          // Settings content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return GlassContainer(
      width: 280,
      blur: AppTheme.blurLight,
      opacity: 0.05,
      borderRadius: 0,
      showBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Settings',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.glassBorder),
          // Section list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                final isSelected = _selectedSection == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      onTap: () => setState(() => _selectedSection = index),
                      child: AnimatedContainer(
                        duration: AppTheme.durationFast,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              section.$2,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              section.$1,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          // Logout button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.2),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppTheme.durationNormal)
        .slideX(begin: -0.1, end: 0, duration: AppTheme.durationNormal);
  }

  Widget _buildContent() {
    final settings = ref.watch(settingsProvider);
    
    Widget content;
    switch (_selectedSection) {
      case 0:
        content = _buildGeneralSettings(settings);
        break;
      case 1:
        content = _buildPlaybackSettings(settings);
        break;
      case 2:
        content = _buildSubtitleSettings(settings);
        break;
      case 3:
        content = _buildAudioSettings(settings);
        break;
      case 4:
        content = _buildNetworkSettings(settings);
        break;
      case 5:
        content = _buildAboutSection();
        break;
      default:
        content = _buildGeneralSettings(settings);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: content,
    )
        .animate()
        .fadeIn(duration: AppTheme.durationNormal);
  }

  Widget _buildGeneralSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('General', 'Customize your app experience'),
        const SizedBox(height: 24),
        
        // UI Mode section
        _buildSettingsCard(
          title: 'Interface Mode',
          icon: Icons.devices,
          children: [
            _buildDescription(
              'Force a specific UI layout regardless of your current device. '
              'Useful for testing or personal preference.',
            ),
            const SizedBox(height: 16),
            _buildUiModeSelector(settings),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Appearance section
        _buildSettingsCard(
          title: 'Appearance',
          icon: Icons.palette_outlined,
          children: [
            _buildSwitchTile(
              title: 'Enable Animations',
              subtitle: 'Show smooth transitions and effects',
              value: settings.enableAnimations,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setEnableAnimations(value);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _buildSwitchTile(
              title: 'Reduced Motion',
              subtitle: 'Minimize animations for accessibility',
              value: settings.reducedMotion,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setReducedMotion(value);
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Reset section
        _buildSettingsCard(
          title: 'Reset',
          icon: Icons.restore,
          children: [
            _buildDescription('Reset all settings to their default values.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showResetConfirmation(),
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

  Widget _buildUiModeSelector(AppSettings settings) {
    final modes = [
      (UiMode.auto, 'Auto', Icons.auto_awesome, _getAutoModeDescription()),
      (UiMode.desktop, 'Desktop', Icons.desktop_windows, 'Wide layout with sidebar navigation'),
      (UiMode.mobile, 'Mobile', Icons.phone_android, 'Compact layout optimized for touch'),
      (UiMode.tv, 'TV', Icons.tv, 'Large elements for remote control navigation'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: modes.map((mode) {
        final isSelected = settings.forcedUiMode == mode.$1;
        return GestureDetector(
          onTap: () {
            ref.read(settingsProvider.notifier).setForcedUiMode(mode.$1);
          },
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            width: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.glassBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      mode.$3,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 24,
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  mode.$2,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mode.$4,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
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

  Widget _buildPlaybackSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Playback', 'Configure video playback preferences'),
        const SizedBox(height: 24),
        
        _buildSettingsCard(
          title: 'Quality',
          icon: Icons.high_quality,
          children: [
            _buildDropdownTile<int>(
              title: 'Default Video Quality',
              subtitle: 'Preferred resolution for streaming',
              value: settings.defaultVideoQuality,
              items: videoQualityOptions.map((q) => 
                DropdownMenuItem(value: q.value, child: Text(q.label))
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setDefaultVideoQuality(value);
                }
              },
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildSettingsCard(
          title: 'Auto Play',
          icon: Icons.play_arrow,
          children: [
            _buildSwitchTile(
              title: 'Auto Play Next Episode',
              subtitle: 'Automatically play the next episode when one ends',
              value: settings.autoPlayNext,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setAutoPlayNext(value);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _buildSwitchTile(
              title: 'Skip Intros',
              subtitle: 'Automatically skip intro sequences',
              value: settings.skipIntros,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setSkipIntros(value);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _buildSwitchTile(
              title: 'Skip Credits',
              subtitle: 'Automatically skip end credits',
              value: settings.skipCredits,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setSkipCredits(value);
              },
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildSettingsCard(
          title: 'Skip Duration',
          icon: Icons.fast_forward,
          children: [
            _buildSliderTile(
              title: 'Forward Skip',
              subtitle: '${settings.forwardSkipDuration} seconds',
              value: settings.forwardSkipDuration.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setForwardSkipDuration(value.toInt());
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _buildSliderTile(
              title: 'Rewind Skip',
              subtitle: '${settings.rewindSkipDuration} seconds',
              value: settings.rewindSkipDuration.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setRewindSkipDuration(value.toInt());
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubtitleSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Subtitles', 'Customize subtitle appearance'),
        const SizedBox(height: 24),
        
        _buildSettingsCard(
          title: 'Subtitle Options',
          icon: Icons.subtitles,
          children: [
            _buildSwitchTile(
              title: 'Enable Subtitles',
              subtitle: 'Show subtitles when available',
              value: settings.subtitlesEnabled,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setSubtitlesEnabled(value);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _buildDropdownTile<String>(
              title: 'Preferred Language',
              subtitle: 'Default subtitle language',
              value: settings.subtitleLanguage,
              items: languageOptions.map((l) => 
                DropdownMenuItem(value: l.code, child: Text(l.name))
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setSubtitleLanguage(value);
                }
              },
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildSettingsCard(
          title: 'Appearance',
          icon: Icons.text_fields,
          children: [
            _buildSliderTile(
              title: 'Subtitle Size',
              subtitle: '${(settings.subtitleSize * 100).toInt()}%',
              value: settings.subtitleSize,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setSubtitleSize(value);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudioSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Audio', 'Configure audio preferences'),
        const SizedBox(height: 24),
        
        _buildSettingsCard(
          title: 'Audio Options',
          icon: Icons.audiotrack,
          children: [
            _buildDropdownTile<String>(
              title: 'Preferred Language',
              subtitle: 'Default audio track language',
              value: settings.audioLanguage,
              items: languageOptions.map((l) => 
                DropdownMenuItem(value: l.code, child: Text(l.name))
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setAudioLanguage(value);
                }
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _buildSwitchTile(
              title: 'Normalize Volume',
              subtitle: 'Maintain consistent volume levels',
              value: settings.normalizeVolume,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setNormalizeVolume(value);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Network', 'Configure streaming and caching'),
        const SizedBox(height: 24),
        
        _buildSettingsCard(
          title: 'Streaming',
          icon: Icons.stream,
          children: [
            _buildDropdownTile<int>(
              title: 'Max Streaming Bitrate',
              subtitle: 'Limit bandwidth usage',
              value: settings.maxStreamingBitrate,
              items: videoQualityOptions.map((q) => 
                DropdownMenuItem(value: q.bitrate, child: Text('${q.label} (${(q.bitrate / 1000000).toStringAsFixed(0)} Mbps)'))
              ).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setMaxStreamingBitrate(value);
                }
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _buildSwitchTile(
              title: 'Allow Cellular Streaming',
              subtitle: 'Stream over mobile data',
              value: settings.allowCellularStreaming,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setAllowCellularStreaming(value);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _buildSwitchTile(
              title: 'Preload Next Episode',
              subtitle: 'Buffer upcoming content for smooth playback',
              value: settings.preloadNextEpisode,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setPreloadNextEpisode(value);
              },
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        _buildSettingsCard(
          title: 'Cache',
          icon: Icons.storage,
          children: [
            _buildSwitchTile(
              title: 'Cache Images',
              subtitle: 'Store images locally for faster loading',
              value: settings.cacheImages,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setCacheImages(value);
              },
            ),
            const Divider(color: AppColors.glassBorder),
            _buildSliderTile(
              title: 'Image Cache Size',
              subtitle: '${settings.imageCacheSize} MB',
              value: settings.imageCacheSize.toDouble(),
              min: 100,
              max: 2000,
              divisions: 19,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setImageCacheSize(value.toInt());
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('About', 'App information'),
        const SizedBox(height: 24),
        
        _buildSettingsCard(
          title: 'Finar',
          icon: Icons.play_circle_fill,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Version', style: AppTextStyles.bodyLarge),
              trailing: Text('1.0.0', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
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
        
        _buildSettingsCard(
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
      ],
    );
  }

  // Helper widgets
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSwitchTile({
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
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDropdownTile<T>({
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

  Widget _buildSliderTile({
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
          activeColor: AppColors.primary,
          inactiveColor: AppColors.glassBorder,
          onChanged: onChanged,
        ),
      ],
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
