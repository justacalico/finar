import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finar/core/api/api.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import '../../whos_watching_page.dart';
import 'settings_general_section.dart';
import 'settings_playback_section.dart';
import 'settings_subtitles_section.dart';
import 'settings_audio_section.dart';
import 'settings_network_section.dart';
import 'settings_about_section.dart';

class SettingsDesktop extends ConsumerStatefulWidget {
  /// When true, renders inside the home shell: no back button or account
  /// actions, since the app sidebar already provides them.
  final bool embedded;

  const SettingsDesktop({super.key, this.embedded = false});

  @override
  ConsumerState<SettingsDesktop> createState() => _SettingsDesktopState();
}

class _SettingsDesktopState extends ConsumerState<SettingsDesktop> {
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
          width: widget.embedded ? 220 : 280,
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
                    if (widget.embedded)
                      Icon(
                        Icons.settings_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 26,
                      )
                    else
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
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Settings',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selectedSection = index),
                          child: AnimatedContainer(
                            duration: AppTheme.durationFast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  section.$2,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : AppColors.textSecondary,
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    section.$1,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
              if (!widget.embedded)
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
                            final message = await Navigator.of(context)
                                .push<String?>(
                                  MaterialPageRoute<String?>(
                                    builder: (_) => const WhosWatchingPage(),
                                  ),
                                );
                            if (message != null && context.mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(message)));
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
                            backgroundColor: AppColors.error.withValues(
                              alpha: 0.12,
                            ),
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
    Widget content;
    switch (_selectedSection) {
      case 0:
        content = SettingsGeneralSection(onReset: _showResetConfirmation);
        break;
      case 1:
        content = const SettingsPlaybackSection();
        break;
      case 2:
        content = const SettingsSubtitlesSection();
        break;
      case 3:
        content = const SettingsAudioSection();
        break;
      case 4:
        content = const SettingsNetworkSection();
        break;
      case 5:
        content = const SettingsAboutSection();
        break;
      default:
        content = SettingsGeneralSection(onReset: _showResetConfirmation);
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: content,
    ).animate().fadeIn(duration: AppTheme.durationNormal);
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
              await ref
                  .read(authProvider.notifier)
                  .removeProfile(currentProfile!);
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
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
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
