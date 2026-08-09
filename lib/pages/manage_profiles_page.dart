import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api/auth_service.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../providers/providers.dart';

/// List saved profiles with option to remove each.
class ManageProfilesPage extends ConsumerWidget {
  const ManageProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(savedProfilesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'Manage profiles',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return _ProfileTile(
            profile: profile,
            onRemove: () => _confirmRemove(context, ref, profile),
          );
        },
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, SavedProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Remove profile?',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          '${profile.userName} will be removed from this device. You can sign in again later.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(authProvider.notifier).removeProfile(profile);
    if (!context.mounted) return;
    if (ref.read(savedProfilesProvider).isEmpty) {
      Navigator.of(context).pop();
    }
  }
}

class _ProfileTile extends StatelessWidget {
  final SavedProfile profile;
  final VoidCallback onRemove;

  const _ProfileTile({
    required this.profile,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: profile.avatarUrl.isEmpty
              ? Container(
                  width: 48,
                  height: 48,
                  color: AppColors.backgroundTertiary,
                  child: Center(
                    child: Text(
                      profile.displayLetter,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: profile.avatarUrl,
                  memCacheWidth: 96,
                  fadeInDuration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.surface),
                  errorWidget: (_, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    color: AppColors.backgroundTertiary,
                    child: Center(
                      child: Text(
                        profile.displayLetter,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        title: Text(
          profile.userName,
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
        ),
        subtitle: profile.serverName != null
            ? Text(
                profile.serverName!,
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: onRemove,
          color: AppColors.textTertiary,
          tooltip: 'Remove profile',
        ),
      ),
    );
  }
}
