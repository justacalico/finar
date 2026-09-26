import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_provider.dart';
import '../widgets/async_view.dart';
import '../widgets/item_menu.dart';
import '../widgets/media_grid.dart';
import '../widgets/page_header.dart';
import 'detail_page.dart';
import 'player_page.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  static const _query = ItemQuery(isFavorite: true);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(pagedItemsProvider(_query));
    return Column(
      children: [
        const PageHeader(title: 'Favorites'),
        Expanded(
          child: AsyncView(
            value: page,
            onRetry: () => ref.invalidate(pagedItemsProvider(_query)),
            builder: (data) => data.items.isEmpty
                ? const EmptyView(
                    icon: Icons.favorite_outline,
                    title: 'No favorites yet',
                    subtitle:
                        'Long-press any item to add it to favorites.')
                : MediaGrid(
                    page: data,
                    onLoadMore: () => ref
                        .read(pagedItemsProvider(_query).notifier)
                        .loadMore(),
                    onTap: (item) => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => DetailPage(
                                itemId: item.id, item: item))),
                    onLongPress: (item) => showItemMenu(
                      context,
                      ref,
                      item,
                      onPlay: (x) => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => PlayerPage(item: x))),
                      onOpen: (x) => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => DetailPage(
                                  itemId: x.id, item: x))),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
