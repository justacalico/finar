import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/widgets/widgets.dart';
import 'package:finar/core/utils/media_actions.dart';
import 'detail_tiles.dart';

class DetailMobileHeader extends ConsumerWidget {
  final MediaItem item;
  final String serverUrl;
  final void Function(MediaItem item) onMoreOptions;

  const DetailMobileHeader({
    super.key,
    required this.item,
    required this.serverUrl,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderRow(),
        const SizedBox(height: 24),
        _buildActionButtons(context, ref),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poster with refined styling
        Hero(
          tag: 'poster_${item.id}',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: item.getDisplayImageUrl(serverUrl, width: 300),
                memCacheWidth: 230,
                memCacheHeight: 344,
                fadeInDuration: const Duration(milliseconds: 150),
                width: 115,
                height: 172,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppColors.surface),
                errorWidget: (_, _, _) => Container(color: AppColors.surface),
              ),
            ),
          ),
        ),

        const SizedBox(width: 18),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              // Metadata with refined chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (item.productionYear != null)
                    DetailMetadataChip(text: item.productionYear.toString()),
                  if (item.officialRating != null)
                    DetailMetadataChip(text: item.officialRating!),
                  if (item.formattedRuntime.isNotEmpty)
                    DetailMetadataChip(text: item.formattedRuntime),
                ],
              ),
              const SizedBox(height: 12),
              // Rating with refined styling
              if (item.communityRating != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.accentYellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.communityRating!.toStringAsFixed(1),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.accentYellow,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.criticRating != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.reviews_rounded,
                              size: 14,
                              color: AppColors.accentRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.criticRating}%',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.accentRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              // Genres with refined styling
              if (item.genres?.isNotEmpty == true)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.genres!.take(3).map((genre) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        genre,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Primary play button
        if (item.type != MediaType.artist)
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => playDetailItem(ref, context, item),
                icon: Icon(Icons.play_arrow, size: 24),
                label: Text(
                  item.hasProgress ? 'Resume' : 'Play',
                  style: AppTextStyles.buttonLarge,
                ),
              ),
            ),
          ),

        // Trailer button
        if (item.hasTrailer) ...[
          const SizedBox(width: 12),
          GlassButton(
            onPressed: () => playDetailTrailer(ref, context, item),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_outlined, size: 18),
                SizedBox(width: 8),
                Text('Trailer'),
              ],
            ),
          ),
        ],

        const SizedBox(width: 12),

        // More options menu
        GlassIconButton(
          icon: Icons.more_vert,
          onPressed: () => onMoreOptions(item),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }
}
