import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';

class DetailCastSection extends StatefulWidget {
  final MediaItem item;
  final String serverUrl;

  const DetailCastSection({
    super.key,
    required this.item,
    required this.serverUrl,
  });

  @override
  State<DetailCastSection> createState() => _DetailCastSectionState();
}

class _DetailCastSectionState extends State<DetailCastSection> {
  bool _showAllCast = false;

  @override
  Widget build(BuildContext context) {
    final people = widget.item.people ?? [];
    final displayPeople = _showAllCast ? people : people.take(10).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Cast & Crew', style: AppTextStyles.titleLarge),
              const Spacer(),
              if (people.length > 10)
                TextButton(
                  onPressed: () => setState(() => _showAllCast = !_showAllCast),
                  child: Text(_showAllCast ? 'Show Less' : 'See All'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: false,
              scrollCacheExtent: ScrollCacheExtent.pixels(500),
              itemCount: displayPeople.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return _PersonCard(
                  person: displayPeople[index],
                  serverUrl: widget.serverUrl,
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}

class _PersonCard extends StatelessWidget {
  final PersonInfo person;
  final String serverUrl;

  const _PersonCard({required this.person, required this.serverUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.surface,
            backgroundImage: person.primaryImageTag != null
                ? NetworkImage(
                    '$serverUrl/Items/${person.id}/Images/Primary?maxWidth=150&tag=${person.primaryImageTag}',
                  )
                : null,
            child: person.primaryImageTag == null
                ? Icon(Icons.person, size: 32)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            person.name,
            style: AppTextStyles.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (person.role != null)
            Text(
              person.role!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
