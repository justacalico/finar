import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';

class PlayerMobileTopControls extends ConsumerWidget {
  final bool controlsVisible;
  final VoidCallback onBack;
  final VoidCallback onLock;
  final VoidCallback onQueueNextEpisode;
  final VoidCallback onToggleSettings;

  const PlayerMobileTopControls({
    super.key,
    required this.controlsVisible,
    required this.onBack,
    required this.onLock,
    required this.onQueueNextEpisode,
    required this.onToggleSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !controlsVisible,
        child: AnimatedOpacity(
          opacity: controlsVisible ? 1.0 : 0.0,
          duration: AppTheme.durationFast,
          child: AnimatedSlide(
            offset: controlsVisible ? Offset.zero : const Offset(0, -1),
            duration: AppTheme.durationNormal,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.currentItem?.name ?? 'Now Playing',
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (state.currentItem?.seriesName != null)
                          Text(
                            '${state.currentItem!.seriesName} • S${state.currentItem!.parentIndexNumber}E${state.currentItem!.indexNumber}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.lock_outline),
                    onPressed: onLock,
                  ),
                  if (state.currentItem?.type == MediaType.episode)
                    IconButton(
                      icon: const Icon(Icons.playlist_add),
                      tooltip: 'Queue next episode',
                      onPressed: onQueueNextEpisode,
                    ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: onToggleSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
