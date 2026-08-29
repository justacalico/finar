import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/api/api.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/providers/providers.dart';
import 'settings_mobile_tiles.dart';
import '../../whos_watching_page.dart';

class SettingsAccountMobileSection extends ConsumerWidget {
  const SettingsAccountMobileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mobileSectionHeader('Account'),
        const SizedBox(height: 10),
        mobileCard(
          children: [
            ListTile(
              leading: Icon(
                Icons.swap_horiz_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Switch profile'),
              subtitle: Text(
                'Choose a different account',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 22),
              onTap: () async {
                final message = await Navigator.of(context).push<String?>(
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
            ),
            mobileDivider(),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(
                'Sign out',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
              ),
              subtitle: Text(
                'Remove this profile from device',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              onTap: () => _showSignOutDialog(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
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
}
