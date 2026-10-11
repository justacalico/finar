import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/widgets/widgets.dart';
import 'package:finar/core/utils/media_actions.dart';
import 'detail_desktop_download.dart';
import 'detail_focusable_action_button.dart';

class DetailHeroSection extends ConsumerWidget {
  final MediaItem item;
  final String serverUrl;
  final void Function(MediaItem item) onMoreOptions;

  const DetailHeroSection({
    super.key,
    required this.item,
    required this.serverUrl,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 500,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(64, 120, 64, 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Poster
            Hero(
              tag: 'poster_${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: CachedNetworkImage(
                  imageUrl: item.getDisplayImageUrl(serverUrl, width: 400),
                  memCacheWidth: 500,
                  memCacheHeight: 750,
                  fadeInDuration: const Duration(milliseconds: 150),
                  width: 250,
                  height: 375,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.surface),
                  errorWidget: (_, _, _) => Container(color: AppColors.surface),
                ),
              ),
            ).animate().fadeIn().scale(
              begin: const Offset(0.9, 0.9),
              duration: AppTheme.durationNormal,
            ),

            const SizedBox(width: 40),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo or title
                  if (item.logoImageTag != null)
                    CachedNetworkImage(
                      imageUrl:
                          '$serverUrl/Items/${item.id}/Images/Logo?maxWidth=500&tag=${item.logoImageTag}',
                      memCacheWidth: 1000,
                      fadeInDuration: const Duration(milliseconds: 150),
                      height: 80,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      placeholder: (_, _) =>
                          Container(color: AppColors.surface),
                      errorWidget: (_, _, _) =>
                          Text(item.name, style: AppTextStyles.displayMedium),
                    )
                  else
                    Text(item.name, style: AppTextStyles.displayMedium),

                  const SizedBox(height: 16),

                  // Metadata row
                  _buildMetadataRow(item),

                  const SizedBox(height: 16),

                  // Genres
                  if (item.genres?.isNotEmpty == true)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.genres!.take(5).map((genre) {
                        return GlassChip(label: genre);
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActionButtons(context, ref, item),
                ],
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(MediaItem item) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (item.productionYear != null)
          Text(item.productionYear.toString(), style: AppTextStyles.bodyLarge),
        if (item.officialRating != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(item.officialRating!, style: AppTextStyles.labelSmall),
          ),
        if (item.formattedRuntime.isNotEmpty)
          Text(item.formattedRuntime, style: AppTextStyles.bodyLarge),
        if (item.communityRating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 18, color: AppColors.accentYellow),
              const SizedBox(width: 4),
              Text(
                item.communityRating!.toStringAsFixed(1),
                style: AppTextStyles.rating,
              ),
            ],
          ),
        if (item.criticRating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.reviews, size: 16, color: AppColors.accentRed),
              const SizedBox(width: 4),
              Text('${item.criticRating}%', style: AppTextStyles.bodyMedium),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
  ) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play button with controller focus support
            if (item.type != MediaType.artist)
              FocusTraversalOrder(
                order: const NumericFocusOrder(0),
                child: DetailFocusableActionButton(
                  width: 200,
                  height: 54,
                  autofocus: true,
                  onPressed: () => playDetailItem(ref, context, item),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 26,
                        color: AppColors.textOnPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.hasProgress ? 'Resume' : 'Play',
                        style: AppTextStyles.buttonLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Trailer button
            if (item.hasTrailer) ...[
              const SizedBox(width: 14),
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: DetailFocusableActionButton(
                  height: 54,
                  onPressed: () => playDetailTrailer(ref, context, item),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.movie_outlined,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text('Trailer', style: AppTextStyles.labelMedium),
                    ],
                  ),
                ),
              ),
            ],

            // Favorite button
            const SizedBox(width: 10),
            FocusTraversalOrder(
              order: NumericFocusOrder(item.hasTrailer ? 2 : 1),
              child: Consumer(
                builder: (context, ref, _) {
                  final isFavorite = item.isFavorite == true;
                  return GlassIconButton(
                    icon: isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    iconColor: isFavorite
                        ? AppColors.accentRed
                        : AppColors.textSecondary,
                    size: 54,
                    onPressed: () => toggleFavoriteItem(ref, item),
                  );
                },
              ),
            ),

            // Mark watched button
            const SizedBox(width: 10),
            FocusTraversalOrder(
              order: NumericFocusOrder(item.hasTrailer ? 3 : 2),
              child: GlassIconButton(
                icon: (item.isPlayed == true)
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                iconColor: (item.isPlayed == true)
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.textSecondary,
                size: 54,
                onPressed: () => toggleWatchedItem(ref, item),
              ),
            ),

            // Download button (hide on web)
            if (!kIsWeb) ...[
              const SizedBox(width: 10),
              FocusTraversalOrder(
                order: NumericFocusOrder(item.hasTrailer ? 4 : 3),
                child: DetailDownloadButton(item: item),
              ),
            ],

            // More options
            const SizedBox(width: 10),
            FocusTraversalOrder(
              order: NumericFocusOrder(
                item.hasTrailer ? (kIsWeb ? 4 : 5) : (kIsWeb ? 3 : 4),
              ),
              child: GlassIconButton(
                icon: Icons.more_horiz_rounded,
                size: 54,
                onPressed: () => onMoreOptions(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
