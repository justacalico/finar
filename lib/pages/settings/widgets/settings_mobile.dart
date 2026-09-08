import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'settings_playback_mobile_section.dart';
import 'settings_subtitles_mobile_section.dart';
import 'settings_audio_mobile_section.dart';
import 'settings_appearance_mobile_section.dart';
import 'settings_network_mobile_section.dart';
import 'settings_account_mobile_section.dart';
import 'settings_about_mobile_section.dart';

class SettingsMobile extends ConsumerStatefulWidget {
  const SettingsMobile({super.key});

  @override
  ConsumerState<SettingsMobile> createState() => _SettingsMobileState();
}

class _SettingsMobileState extends ConsumerState<SettingsMobile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(title: 'Settings'),
            Expanded(child: _buildSections()),
          ],
        ),
      ),
    );
  }

  Widget _buildSections() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SettingsPlaybackMobileSection(),
        const SizedBox(height: 28),
        const SettingsSubtitlesMobileSection(),
        const SizedBox(height: 28),
        const SettingsAudioMobileSection(),
        const SizedBox(height: 28),
        const SettingsAppearanceMobileSection(),
        const SizedBox(height: 28),
        const SettingsNetworkMobileSection(),
        const SizedBox(height: 28),
        const SettingsAccountMobileSection(),
        const SizedBox(height: 28),
        const SettingsAboutMobileSection(),
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
