import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'package:finar/core/utils/media_actions.dart';
import 'detail_loading_shimmer.dart';

List<Widget> albumTracksSlivers(
  WidgetRef ref,
  MediaItem album,
  String serverUrl,
) {
  final tracksAsync = ref.watch(albumTracksProvider(album.id));
  return tracksAsync.when(
    data: (tracks) => [
      SliverToBoxAdapter(
        child: RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(64, 0, 64, 16),
            child: Row(
              children: [
                Text('Tracks', style: AppTextStyles.titleLarge),
                const Spacer(),
                Text(
                  '${tracks.length} songs',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
        sliver: SliverList.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final track = tracks[index];
            return _TrackTile(track: track, trackNumber: index + 1);
          },
        ),
      ),
    ],
    loading: () => [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
          child: const DetailLoadingShimmer(height: 300),
        ),
      ),
    ],
    error: (error, _) => [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
          child: Text('Error loading tracks: $error'),
        ),
      ),
    ],
  );
}

class _TrackTile extends ConsumerWidget {
  final MediaItem track;
  final int trackNumber;

  const _TrackTile({required this.track, required this.trackNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = track.formattedRuntime;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => playDetailItem(ref, context, track),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Track number
              SizedBox(
                width: 40,
                child: Text(
                  track.indexNumber?.toString() ?? trackNumber.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: 16),

              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: AppTextStyles.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (track.albumArtist != null ||
                        track.artists?.isNotEmpty == true)
                      Text(
                        track.albumArtist ?? track.artists?.join(', ') ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Duration
              Text(
                duration,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(width: 16),

              // Play button
              GlassIconButton(
                icon: Icons.play_arrow,
                size: 36,
                onPressed: () => playDetailItem(ref, context, track),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
