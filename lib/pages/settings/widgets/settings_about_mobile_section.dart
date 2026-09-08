import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/utils/platform_detector.dart';
import 'package:finar/providers/providers.dart';
import 'settings_mobile_tiles.dart';

class SettingsAboutMobileSection extends ConsumerWidget {
  const SettingsAboutMobileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mobileSectionHeader('About'),
        const SizedBox(height: 10),
        mobileCard(
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
            mobileDivider(),
            ListTile(
              title: const Text('Platform'),
              trailing: Text(
                PlatformDetector.current.name.toUpperCase(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            mobileDivider(),
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
            mobileDivider(),
            ListTile(
              leading: Icon(
                Icons.language_rounded,
                color: Theme.of(context).colorScheme.primary,
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
            mobileDivider(),
            ListTile(
              leading: Icon(
                Icons.code_rounded,
                color: Theme.of(context).colorScheme.primary,
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
            mobileDivider(),
            ListTile(
              leading: Icon(
                Icons.privacy_tip_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Privacy Policy'),
              subtitle: Text(
                'We do not collect any data',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              trailing: const Icon(Icons.open_in_new_rounded, size: 20),
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
