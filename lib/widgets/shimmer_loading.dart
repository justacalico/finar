import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/colors.dart';
import '../core/theme/app_theme.dart';

/// A shimmer loading placeholder - optimized with RepaintBoundary
class ShimmerLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppTheme.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: SizedBox(width: width, height: height),
      )
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .shimmer(
            duration: const Duration(milliseconds: 1500),
            color: AppColors.white.withValues(alpha: 0.1),
          ),
    );
  }
}

/// A loading skeleton for list items
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const ShimmerLoading(
            width: 80,
            height: 120,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  height: 20,
                  width: MediaQuery.of(context).size.width * 0.5,
                ),
                const SizedBox(height: 8),
                const ShimmerLoading(
                  height: 14,
                  width: 100,
                ),
                const SizedBox(height: 8),
                const ShimmerLoading(
                  height: 14,
                  width: 150,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A loading skeleton for cards
class SkeletonCard extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonCard({
    super.key,
    this.width = 150,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(
            width: width,
            height: height,
          ),
          const SizedBox(height: 8),
          ShimmerLoading(
            width: width * 0.8,
            height: 14,
          ),
          const SizedBox(height: 4),
          ShimmerLoading(
            width: width * 0.5,
            height: 12,
          ),
        ],
      ),
    );
  }
}
