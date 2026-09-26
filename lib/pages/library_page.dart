import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/async_view.dart';
import '../widgets/item_menu.dart';
import '../widgets/media_grid.dart';
import '../widgets/page_header.dart';
import 'detail_page.dart';
import 'player_page.dart';

/// Browsable grid for one library with sort controls and paging.
/// Used for the Libraries section, See-all pages and pushed folders.
class LibraryPage extends ConsumerStatefulWidget {
  final String libraryId;
  final String title;
  final List<String>? types;
  final bool inShell;

  const LibraryPage({
    super.key,
    required this.libraryId,
    required this.title,
    this.types,
    this.inShell = false,
  });

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  static const _sortOptions = {
    'SortName': 'Name',
    'DateCreated': 'Date added',
    'PremiereDate': 'Release date',
    'CommunityRating': 'Rating',
    'Random': 'Shuffle',
  };

  late ItemQuery _query;
  String _sortBy = 'SortName';
  bool _descending = false;

  @override
  void initState() {
    super.initState();
    _query = ItemQuery(parentId: widget.libraryId, types: widget.types);
  }

  void _setSort(String by) {
    setState(() {
      if (_sortBy == by) {
        _descending = !_descending;
      } else {
        _sortBy = by;
        _descending = by != 'SortName';
      }
      _query = _query.copyWith(
        sortBy: _sortBy,
        sortOrder: _descending ? 'Descending' : 'Ascending',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(pagedItemsProvider(_query));
    return Column(
      children: [
        PageHeader(
          title: widget.title,
          showBack: widget.inShell,
          onBack: widget.inShell
              ? () =>
                  ref.read(shellNavProvider.notifier).closeLibrary()
              : null,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort',
              onSelected: _setSort,
              itemBuilder: (_) => [
                for (final e in _sortOptions.entries)
                  CheckedPopupMenuItem(
                    value: e.key,
                    checked: _sortBy == e.key,
                    child: Text(_sortBy == e.key
                        ? '${e.value} ${_descending ? '↓' : '↑'}'
                        : e.value),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () =>
                  ref.invalidate(pagedItemsProvider(_query)),
            ),
          ],
        ),
        Expanded(
          child: AsyncView(
            value: page,
            onRetry: () => ref.invalidate(pagedItemsProvider(_query)),
            builder: (data) => data.items.isEmpty
                ? const EmptyView(
                    icon: Icons.inbox_outlined,
                    title: 'This library is empty')
                : MediaGrid(
                    page: data,
                    onLoadMore: () => ref
                        .read(pagedItemsProvider(_query).notifier)
                        .loadMore(),
                    onTap: (item) => _open(context, item),
                    onLongPress: (item) => showItemMenu(
                      context,
                      ref,
                      item,
                      onPlay: (x) => _play(context, x),
                      onOpen: (x) => _open(context, x),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, MediaItem item) {
    if (widget.inShell) {
      Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
              builder: (_) => DetailPage(itemId: item.id, item: item)));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DetailPage(itemId: item.id, item: item)));
    }
  }

  void _play(BuildContext context, MediaItem item) {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (_) => PlayerPage(item: item)));
  }

}
