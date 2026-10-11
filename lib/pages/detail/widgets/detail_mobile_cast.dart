import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';

class DetailMobileCastSection extends StatelessWidget {
  final MediaItem item;
  final String serverUrl;

  const DetailMobileCastSection({
    super.key,
    required this.item,
    required this.serverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final people = item.people ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cast & Crew', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: false,
              scrollCacheExtent: ScrollCacheExtent.pixels(500),
              itemCount: people.length.clamp(0, 10),
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final person = people[index];
                return _PersonCard(person: person, serverUrl: serverUrl);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _PersonCard extends StatelessWidget {
  final PersonInfo person;
  final String serverUrl;

  const _PersonCard({required this.person, required this.serverUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.surface,
            backgroundImage: person.primaryImageTag != null
                ? CachedNetworkImageProvider(
                    '$serverUrl/Items/${person.id}/Images/Primary?maxWidth=150&tag=${person.primaryImageTag}',
                  )
                : null,
            child: person.primaryImageTag == null
                ? Icon(Icons.person, size: 22)
                : null,
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              person.name,
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (person.role != null)
            Flexible(
              child: Text(
                person.role!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
