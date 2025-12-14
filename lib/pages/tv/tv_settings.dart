import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/platform_detector.dart';
import '../../providers/providers.dart';

class TvSettings extends ConsumerStatefulWidget {
  const TvSettings({super.key});

  @override
  ConsumerState<TvSettings> createState() => _TvSettingsState();
}

class _TvSettingsState extends ConsumerState<TvSettings> {
  final FocusNode _focusNode = FocusNode();
  int _selectedCategoryIndex = 0;
  int _selectedItemIndex = 0;

  final _categories = [
    ('Interface', Icons.devices),
    ('Playback', Icons.play_circle_outline),
    ('Subtitles', Icons.subtitles_outlined),
    ('Audio', Icons.volume_up_outlined),
    ('Network', Icons.wifi_outlined),
    ('About', Icons.info_outline),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Row(
          children: [
            // Categories sidebar
            _buildCategoriesSidebar(),
            // Settings content
            Expanded(
              child: _buildSettingsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSidebar() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.background,
            AppColors.background.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                'Settings',
                style: AppTextStyles.displaySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Categories
          ...List.generate(_categories.length, (index) {
            final category = _categories[index];
            final isSelected = _selectedCategoryIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      category.$2,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      category.$1,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const Spacer(),

          // Sign out button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.logout, color: AppColors.error, size: 28),
                const SizedBox(width: 16),
                Text(
                  'Sign Out',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    final settings = ref.watch(settingsProvider);

    Widget content;
    switch (_selectedCategoryIndex) {
      case 0:
        content = _buildInterfaceSettings(settings);
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
        content = _buildInterfaceSettings(settings);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: content,
    );
  }

  Widget _buildInterfaceSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Interface Mode'),
        const SizedBox(height: 8),
        Text(
          'Choose which UI layout to use. This will take effect immediately.',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        _buildUiModeSelector(settings),
        const SizedBox(height: 48),
        _buildSectionTitle('Appearance'),
        const SizedBox(height: 24),
        _buildTvSwitchItem(
          title: 'Enable Animations',
          subtitle: 'Show smooth transitions and effects',
          value: settings.enableAnimations,
          isSelected: _selectedItemIndex == 4,
          onToggle: () => ref.read(settingsProvider.notifier).setEnableAnimations(!settings.enableAnimations),
        ),
        const SizedBox(height: 16),
        _buildTvSwitchItem(
          title: 'Reduced Motion',
          subtitle: 'Minimize animations for accessibility',
          value: settings.reducedMotion,
          isSelected: _selectedItemIndex == 5,
          onToggle: () => ref.read(settingsProvider.notifier).setReducedMotion(!settings.reducedMotion),
        ),
      ],
    );
  }

  Widget _buildUiModeSelector(AppSettings settings) {
    final modes = [
      (UiMode.auto, 'Auto', Icons.auto_awesome, _getAutoModeDescription()),
      (UiMode.desktop, 'Desktop', Icons.desktop_windows, 'Sidebar navigation layout'),
      (UiMode.mobile, 'Mobile', Icons.phone_android, 'Touch-optimized compact layout'),
      (UiMode.tv, 'TV', Icons.tv, 'Remote-friendly large elements'),
    ];

    return Row(
      children: modes.asMap().entries.map((entry) {
        final index = entry.key;
        final mode = entry.value;
        final isSelected = settings.forcedUiMode == mode.$1;
        final isFocused = _selectedItemIndex == index;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < modes.length - 1 ? 16 : 0),
            child: GestureDetector(
              onTap: () => ref.read(settingsProvider.notifier).setForcedUiMode(mode.$1),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primary
                        : isSelected
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.glassBorder,
                    width: isFocused ? 3 : isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      mode.$3,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      mode.$2,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mode.$4,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 12),
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 28),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getAutoModeDescription() {
    if (PlatformDetector.isTV) {
      return 'Currently: TV';
    } else if (PlatformDetector.isDesktop) {
      return 'Currently: Desktop';
    } else {
      return 'Currently: Mobile';
    }
  }

  Widget _buildPlaybackSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Playback'),
        const SizedBox(height: 32),
        _buildTvSwitchItem(
          title: 'Auto Play Next Episode',
          subtitle: 'Automatically continue to the next episode',
          value: settings.autoPlayNext,
          isSelected: _selectedItemIndex == 0,
          onToggle: () => ref.read(settingsProvider.notifier).setAutoPlayNext(!settings.autoPlayNext),
        ),
        const SizedBox(height: 16),
        _buildTvSwitchItem(
          title: 'Skip Intros',
          subtitle: 'Automatically skip intro sequences',
          value: settings.skipIntros,
          isSelected: _selectedItemIndex == 1,
          onToggle: () => ref.read(settingsProvider.notifier).setSkipIntros(!settings.skipIntros),
        ),
        const SizedBox(height: 16),
        _buildTvSwitchItem(
          title: 'Skip Credits',
          subtitle: 'Automatically skip end credits',
          value: settings.skipCredits,
          isSelected: _selectedItemIndex == 2,
          onToggle: () => ref.read(settingsProvider.notifier).setSkipCredits(!settings.skipCredits),
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('Quality'),
        const SizedBox(height: 24),
        _buildTvDropdownItem<int>(
          title: 'Default Video Quality',
          value: settings.defaultVideoQuality,
          items: videoQualityOptions.map((q) => (q.value, q.label)).toList(),
          isSelected: _selectedItemIndex == 3,
          onChanged: (v) => ref.read(settingsProvider.notifier).setDefaultVideoQuality(v),
        ),
      ],
    );
  }

  Widget _buildSubtitleSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Subtitles'),
        const SizedBox(height: 32),
        _buildTvSwitchItem(
          title: 'Enable Subtitles',
          subtitle: 'Show subtitles when available',
          value: settings.subtitlesEnabled,
          isSelected: _selectedItemIndex == 0,
          onToggle: () => ref.read(settingsProvider.notifier).setSubtitlesEnabled(!settings.subtitlesEnabled),
        ),
        const SizedBox(height: 16),
        _buildTvDropdownItem<String>(
          title: 'Preferred Language',
          value: settings.subtitleLanguage,
          items: languageOptions.map((l) => (l.code, l.name)).toList(),
          isSelected: _selectedItemIndex == 1,
          onChanged: (v) => ref.read(settingsProvider.notifier).setSubtitleLanguage(v),
        ),
      ],
    );
  }

  Widget _buildAudioSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Audio'),
        const SizedBox(height: 32),
        _buildTvDropdownItem<String>(
          title: 'Preferred Language',
          value: settings.audioLanguage,
          items: languageOptions.map((l) => (l.code, l.name)).toList(),
          isSelected: _selectedItemIndex == 0,
          onChanged: (v) => ref.read(settingsProvider.notifier).setAudioLanguage(v),
        ),
        const SizedBox(height: 16),
        _buildTvSwitchItem(
          title: 'Normalize Volume',
          subtitle: 'Keep consistent volume levels',
          value: settings.normalizeVolume,
          isSelected: _selectedItemIndex == 1,
          onToggle: () => ref.read(settingsProvider.notifier).setNormalizeVolume(!settings.normalizeVolume),
        ),
      ],
    );
  }

  Widget _buildNetworkSettings(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Network'),
        const SizedBox(height: 32),
        _buildTvSwitchItem(
          title: 'Preload Next Episode',
          subtitle: 'Buffer upcoming content for smooth playback',
          value: settings.preloadNextEpisode,
          isSelected: _selectedItemIndex == 0,
          onToggle: () => ref.read(settingsProvider.notifier).setPreloadNextEpisode(!settings.preloadNextEpisode),
        ),
        const SizedBox(height: 16),
        _buildTvSwitchItem(
          title: 'Cache Images',
          subtitle: 'Store images locally for faster loading',
          value: settings.cacheImages,
          isSelected: _selectedItemIndex == 1,
          onToggle: () => ref.read(settingsProvider.notifier).setCacheImages(!settings.cacheImages),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final serverUrl = ref.read(authProvider.notifier).serverUrl;
    final user = ref.watch(authProvider).user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About'),
        const SizedBox(height: 32),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '...';
            final buildNumber = snapshot.data?.buildNumber ?? '';
            return _buildTvInfoItem(
              title: 'App Version',
              value: buildNumber.isNotEmpty ? '$version+$buildNumber' : version,
            );
          },
        ),
        const SizedBox(height: 16),
        _buildTvInfoItem(title: 'Platform', value: PlatformDetector.current.name.toUpperCase()),
        const SizedBox(height: 16),
        _buildTvInfoItem(title: 'Server', value: serverUrl ?? 'Not connected'),
        const SizedBox(height: 16),
        _buildTvInfoItem(title: 'User', value: user?.name ?? 'Unknown'),
        const SizedBox(height: 32),
        _buildSectionTitle('Links'),
        const SizedBox(height: 16),
        _buildTvLinkItem(
          title: 'Website',
          subtitle: 'openlyst.onrender.com',
          icon: Icons.language,
          iconColor: AppColors.primary,
          onTap: () => _launchUrl('https://openlyst.onrender.com'),
        ),
        const SizedBox(height: 16),
        _buildTvLinkItem(
          title: 'Source Code',
          subtitle: 'GitLab Repository',
          icon: Icons.code,
          iconColor: AppColors.accentOrange,
          onTap: () => _launchUrl('https://gitlab.com/Openlyst/finar'),
        ),
      ],
    );
  }

  Widget _buildTvLinkItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTvSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required bool isSelected,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.glassBorder,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) => onToggle(),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTvDropdownItem<T>({
    required String title,
    required T value,
    required List<(T, String)> items,
    required bool isSelected,
    required ValueChanged<T> onChanged,
  }) {
    final selectedLabel = items.firstWhere((i) => i.$1 == value, orElse: () => items.first).$2;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.glassBorder,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedLabel,
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.unfold_more, color: AppColors.primary, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvInfoItem({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_selectedCategoryIndex > 0) {
          _selectedCategoryIndex--;
          _selectedItemIndex = 0;
        }
      });
    } else if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_selectedCategoryIndex < _categories.length - 1) {
          _selectedCategoryIndex++;
          _selectedItemIndex = 0;
        }
      });
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      // Navigate within content
      setState(() {
        if (_selectedItemIndex > 0) {
          _selectedItemIndex--;
        }
      });
    } else if (key == LogicalKeyboardKey.arrowRight) {
      // Navigate within content
      setState(() {
        _selectedItemIndex++;
      });
    } else if (key == LogicalKeyboardKey.select ||
               key == LogicalKeyboardKey.enter) {
      // Toggle/select current item
      _handleSelect();
    } else if (key == LogicalKeyboardKey.escape ||
               key == LogicalKeyboardKey.goBack) {
      Navigator.pop(context);
    }
  }

  void _handleSelect() {
    // Handle selection based on current category and item
    final settings = ref.read(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    switch (_selectedCategoryIndex) {
      case 0: // Interface
        if (_selectedItemIndex < 4) {
          // UI Mode selection
          final modes = [UiMode.auto, UiMode.desktop, UiMode.mobile, UiMode.tv];
          if (_selectedItemIndex < modes.length) {
            notifier.setForcedUiMode(modes[_selectedItemIndex]);
          }
        } else if (_selectedItemIndex == 4) {
          notifier.setEnableAnimations(!settings.enableAnimations);
        } else if (_selectedItemIndex == 5) {
          notifier.setReducedMotion(!settings.reducedMotion);
        }
        break;
      case 1: // Playback
        if (_selectedItemIndex == 0) {
          notifier.setAutoPlayNext(!settings.autoPlayNext);
        } else if (_selectedItemIndex == 1) {
          notifier.setSkipIntros(!settings.skipIntros);
        } else if (_selectedItemIndex == 2) {
          notifier.setSkipCredits(!settings.skipCredits);
        }
        break;
      case 2: // Subtitles
        if (_selectedItemIndex == 0) {
          notifier.setSubtitlesEnabled(!settings.subtitlesEnabled);
        }
        break;
      case 3: // Audio
        if (_selectedItemIndex == 1) {
          notifier.setNormalizeVolume(!settings.normalizeVolume);
        }
        break;
      case 4: // Network
        if (_selectedItemIndex == 0) {
          notifier.setPreloadNextEpisode(!settings.preloadNextEpisode);
        } else if (_selectedItemIndex == 1) {
          notifier.setCacheImages(!settings.cacheImages);
        }
        break;
    }
  }
}
