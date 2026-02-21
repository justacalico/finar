import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/auth_service.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../providers/providers.dart';
import 'login_page.dart';
import 'manage_profiles_page.dart';

/// Netflix-style "Who's watching?" screen for multiple Jellyfin accounts.
class WhosWatchingPage extends ConsumerWidget {
  const WhosWatchingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(savedProfilesProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Who's watching?",
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 40),
                if (authState.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const cardSize = 140.0;
                      const spacing = 24.0;
                      final count = profiles.length + 1; // +1 for Add profile
                      final totalWidth = count * cardSize + (count - 1) * spacing;
                      final wrap = constraints.maxWidth < totalWidth;
                      return wrap
                          ? Wrap(
                              alignment: WrapAlignment.center,
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                ...profiles.map((p) => _ProfileCard(
                                      profile: p,
                                      size: cardSize,
                                      onTap: () => _selectProfile(context, ref, p),
                                    )),
                                _AddProfileCard(
                                  size: cardSize,
                                  onTap: () => _openAddProfile(context),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ...profiles.map((p) => Padding(
                                      padding: const EdgeInsets.only(right: spacing),
                                      child: _ProfileCard(
                                        profile: p,
                                        size: cardSize,
                                        onTap: () => _selectProfile(context, ref, p),
                                      ),
                                    )),
                                _AddProfileCard(
                                  size: cardSize,
                                  onTap: () => _openAddProfile(context),
                                ),
                              ],
                            );
                    },
                  ),
                if (profiles.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  OutlinedButton(
                    onPressed: () => _openManageProfiles(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                    child: Text(
                      'MANAGE PROFILES',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectProfile(BuildContext context, WidgetRef ref, SavedProfile profile) async {
    final success = await ref.read(authProvider.notifier).selectProfile(profile);
    if (!context.mounted) return;
    if (success && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _openAddProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LoginPage(fromAddProfile: true),
      ),
    );
  }

  void _openManageProfiles(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ManageProfilesPage(),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final SavedProfile profile;
  final double size;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.profile,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: profile.avatarUrl.isEmpty
                      ? Center(
                          child: Text(
                            profile.displayLetter,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : Image.network(
                          profile.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => Center(
                            child: Text(
                              profile.displayLetter,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.userName,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProfileCard extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _AddProfileCard({
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 56,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add Profile',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
