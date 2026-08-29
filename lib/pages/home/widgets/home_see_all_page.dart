import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/api/models/media_item.dart';
import '../../../widgets/widgets.dart';
import '../../detail.dart';

class MobileSeeAllPage extends StatelessWidget {
  final String title;
  final List<MediaItem> items;
  final String serverUrl;

  const MobileSeeAllPage({
    required this.title,
    required this.items,
    required this.serverUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.62,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
        cacheExtent: 1000,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return AnimatedCard(
            imageUrl: item.getDisplayImageUrl(serverUrl, width: 240),
            title: item.name,
            subtitle: item.productionYear?.toString(),
            isWatched: item.isPlayed == true,
            enableEntranceAnimation: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailPage(itemId: item.id)),
              );
            },
          );
        },
      ),
    );
  }
}
