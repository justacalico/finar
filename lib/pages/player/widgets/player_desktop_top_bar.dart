import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';

class PlayerDesktopTopBar extends ConsumerWidget {
  final bool controlsVisible;
  final bool isFullscreen;
  final VoidCallback onBack;
  final VoidCallback onToggleFullscreen;

  const PlayerDesktopTopBar({
    super.key,
    required this.controlsVisible,
    required this.isFullscreen,
    required this.onBack,
    required this.onToggleFullscreen,
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
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GlassIconButton(icon: Icons.arrow_back, onPressed: onBack),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.currentItem?.name ?? 'Now Playing',
                            style: AppTextStyles.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (state.currentItem?.seriesName != null)
                            Text(
                              '${state.currentItem!.seriesName} • S${state.currentItem!.parentIndexNumber}E${state.currentItem!.indexNumber}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    GlassIconButton(
                      icon: isFullscreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                      onPressed: onToggleFullscreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
