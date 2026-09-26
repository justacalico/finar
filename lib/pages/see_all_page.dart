import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/async_view.dart';
import '../widgets/item_menu.dart';
import '../widgets/media_grid.dart';
import '../widgets/page_header.dart';
import 'player_page.dart';

/// Pushed full-grid view for a rail ("See all").
class SeeAllPage extends ConsumerWidget {
  final String title;
  final ItemQuery query;
  final ArtShape shape;

  const SeeAllPage({
    super.key,
    required this.title,
    required this.query,
    this.shape = ArtShape.poster,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(pagedItemsProvider(query));
    return Scaffold(
      body: Column(
        children: [
          PageHeader(title: title),
          Expanded(
            child: AsyncView(
              value: page,
              onRetry: () =>
                  ref.invalidate(pagedItemsProvider(query)),
              builder: (data) => MediaGrid(
                page: data,
                shape: shape,
                onLoadMore: () => ref
                    .read(pagedItemsProvider(query).notifier)
                    .loadMore(),
                onTap: (item) => ref
                    .read(shellNavProvider.notifier)
                    .openDetail(item),
                onLongPress: (item) => showItemMenu(
                  context,
                  ref,
                  item,
                  onPlay: (x) => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => PlayerPage(item: x))),
                  onOpen: (x) => ref
                      .read(shellNavProvider.notifier)
                      .openDetail(x),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
