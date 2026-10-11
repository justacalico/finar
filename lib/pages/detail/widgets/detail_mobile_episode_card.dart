import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/widgets/widgets.dart';
import 'package:finar/core/utils/media_actions.dart';

class DetailMobileEpisodeCard extends ConsumerWidget {
  final MediaItem episode;
  final String serverUrl;
  final String seasonId;

  const DetailMobileEpisodeCard({
    super.key,
    required this.episode,
    required this.serverUrl,
    required this.seasonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWatched = episode.isPlayed == true;

    return GlassCard(
      onTap: () => playDetailItem(ref, context, episode),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Stack(
              children: [
                ColorFiltered(
                  colorFilter: isWatched
                      ? ColorFilter.mode(
                          AppColors.black.withValues(alpha: 0.3),
                          BlendMode.darken,
                        )
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        ),
                  child: CachedNetworkImage(
                    imageUrl: episode.getPrimaryImageUrl(serverUrl, width: 250),
                    memCacheWidth: 260,
                    memCacheHeight: 150,
                    fadeInDuration: const Duration(milliseconds: 150),
                    width: 130,
                    height: 75,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.surface),
                    errorWidget: (_, _, _) =>
                        Container(color: AppColors.surface),
                  ),
                ),
                // Watched indicator
                if (isWatched)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                // Progress bar
                if (episode.hasProgress && !isWatched)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: episode.progressPercent,
                      backgroundColor: AppColors.black.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary,
                      ),
                      minHeight: 3,
                    ),
                  ),
                // Play icon
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      isWatched ? Icons.replay : Icons.play_circle_outline,
                      size: 32,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'E${episode.indexNumber} - ${episode.name}',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isWatched
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isWatched)
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (episode.overview != null)
                  Text(
                    episode.overview!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                if (episode.formattedRuntime.isNotEmpty)
                  Text(
                    episode.formattedRuntime,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),

          // Mark watched button
          IconButton(
            icon: Icon(
              isWatched ? Icons.visibility_off : Icons.visibility,
              color: isWatched
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.textSecondary,
            ),
            onPressed: () => toggleEpisodeWatched(ref, episode, seasonId),
          ),
        ],
      ),
    );
  }
}
