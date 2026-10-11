import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/widgets/widgets.dart';
import 'detail_tiles.dart';

class DetailInfoSection extends StatelessWidget {
  final MediaItem item;

  const DetailInfoSection({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final hasOverview = item.overview != null;
    final hasDetails =
        item.studios?.isNotEmpty == true ||
        item.productionYear != null ||
        item.container != null ||
        (item.mediaStreams?.isNotEmpty == true);

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasOverview) ...[
            // Overview
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.overview!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      height: 1.7,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  if (item.taglines?.isNotEmpty == true) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '"${item.taglines!.first}"',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (hasOverview && hasDetails) const SizedBox(width: 64),

          // Additional info
          if (hasDetails) Expanded(child: _buildAdditionalInfo()),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildAdditionalInfo() {
    return GlassContainer(
      blur: AppTheme.blurHeavy,
      opacity: 0.09,
      borderRadius: AppTheme.radiusLg,
      borderColor: AppColors.white.withValues(alpha: 0.22),
      shadows: [
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.2),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.white.withValues(alpha: 0.16),
          AppColors.white.withValues(alpha: 0.05),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (item.studios?.isNotEmpty == true)
            DetailInfoRow(label: 'Studio', value: item.studios!.first),
          if (item.productionYear != null)
            DetailInfoRow(label: 'Year', value: item.productionYear.toString()),
          if (item.container != null)
            DetailInfoRow(
              label: 'Format',
              value: item.container!.toUpperCase(),
            ),
          if (item.mediaStreams?.isNotEmpty == true) ...[
            DetailInfoRow(
              label: 'Video',
              value:
                  item.mediaStreams!
                      .where((s) => s.type == 'Video')
                      .map(
                        (s) => '${s.codec?.toUpperCase()} ${s.videoResolution}',
                      )
                      .firstOrNull ??
                  'Unknown',
            ),
            DetailInfoRow(
              label: 'Audio',
              value:
                  item.mediaStreams!
                      .where((s) => s.type == 'Audio')
                      .map(
                        (s) =>
                            '${s.codec?.toUpperCase()} ${s.channelLayout ?? ''}',
                      )
                      .firstOrNull ??
                  'Unknown',
            ),
          ],
        ],
      ),
    );
  }
}
