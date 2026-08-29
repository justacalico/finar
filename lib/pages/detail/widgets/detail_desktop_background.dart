import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/colors.dart';

class DetailDesktopBackground extends StatelessWidget {
  final MediaItem item;
  final String serverUrl;

  const DetailDesktopBackground({
    super.key,
    required this.item,
    required this.serverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.type == MediaType.album
        ? item.getPrimaryImageUrl(serverUrl, width: 1920)
        : item.getBackdropImageUrl(serverUrl, width: 1920);

    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop image (album art for albums)
          CachedNetworkImage(
            imageUrl: imageUrl,
            memCacheWidth: 1000,
            fadeInDuration: const Duration(milliseconds: 150),
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.surface),
            errorWidget: (_, _, _) => Container(color: AppColors.background),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.3),
                  AppColors.background.withValues(alpha: 0.7),
                  AppColors.background,
                ],
                stops: const [0.0, 0.4, 0.7],
              ),
            ),
          ),

          // Left gradient for content readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.background.withValues(alpha: 0.9),
                  AppColors.background.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
