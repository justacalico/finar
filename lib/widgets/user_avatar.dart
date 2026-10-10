import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:finar/core/api/models/user.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';

class UserAvatar extends StatelessWidget {
  final User? user;
  final String serverUrl;
  final double size;

  const UserAvatar({
    super.key,
    this.user,
    this.serverUrl = '',
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final userName = user?.name.trim();
    final fallbackLetter = userName != null && userName.isNotEmpty
        ? userName[0].toUpperCase()
        : '?';
    final avatarUrl = (user != null && serverUrl.isNotEmpty)
        ? user!.getAvatarUrl(serverUrl)
        : '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: avatarUrl.isEmpty
            ? Center(
                child: Text(
                  fallbackLetter,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: avatarUrl,
                memCacheWidth: (size * 2).round(),
                memCacheHeight: (size * 2).round(),
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) => Container(color: AppColors.surface),
                errorWidget: (_, _, _) => Center(
                  child: Text(
                    fallbackLetter,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}
