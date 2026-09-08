import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/utils/platform_detector.dart';
import 'package:finar/providers/providers.dart';
import 'settings_tiles.dart';

class SettingsAboutSection extends ConsumerWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionHeader('About', 'App information'),
        const SizedBox(height: 24),
        settingsCard(
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
            Divider(color: AppColors.glassBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Platform', style: AppTextStyles.bodyLarge),
              trailing: Text(
                PlatformDetector.current.name.toUpperCase(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Divider(color: AppColors.glassBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('OS Version', style: AppTextStyles.bodyLarge),
              trailing: Text(
                PlatformDetector.osVersion,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        settingsCard(
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
                      title: Text(
                        'Connected Server',
                        style: AppTextStyles.bodyLarge,
                      ),
                      subtitle: Text(
                        serverUrl ?? 'Not connected',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    Divider(color: AppColors.glassBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('User', style: AppTextStyles.bodyLarge),
                      subtitle: Text(
                        authState.user?.name ?? 'Unknown',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        settingsCard(
          context,
          title: 'Links',
          icon: Icons.link,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('Website', style: AppTextStyles.bodyLarge),
              subtitle: Text(
                'https://openlyst.ink/',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => _launchUrl('https://openlyst.ink/'),
            ),
            Divider(color: AppColors.glassBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.code,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('Source Code', style: AppTextStyles.bodyLarge),
              subtitle: Text(
                'GitLab Repository',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => _launchUrl('https://gitlab.com/Openlyst/finar'),
            ),
            Divider(color: AppColors.glassBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.privacy_tip_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text('Privacy Policy', style: AppTextStyles.bodyLarge),
              subtitle: Text(
                'We do not collect any data',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => _launchUrl(
                'https://gitlab.com/Openlyst/finar/-/blob/main/PRIVACY.md',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
