import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';
import '../core/theme/app_theme.dart';
import '../providers/library_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/providers.dart';
import '../widgets/app_image.dart';
import '../widgets/async_view.dart';
import '../widgets/focusable.dart';
import '../widgets/page_header.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchProvider(_query));
    return Column(
      children: [
        PageHeader(
          title: 'Search',
          below: Padding(
            padding: EdgeInsets.fromLTRB(Insets.sm, Insets.sm, Insets.sm, 0),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Movies, shows, music...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? const EmptyView(
                  icon: Icons.search,
                  title: 'Search your library',
                )
              : AsyncView(
                  value: results,
                  builder: (hints) => hints.isEmpty
                      ? const EmptyView(
                          icon: Icons.search_off,
                          title: 'No results',
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(Insets.md),
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: dim(160),
                                mainAxisSpacing: Insets.md,
                                crossAxisSpacing: Insets.sm,
                                childAspectRatio: 0.62,
                              ),
                          itemCount: hints.length,
                          itemBuilder: (context, i) =>
                              _SearchCard(hint: hints[i]),
                        ),
                ),
        ),
      ],
    );
  }
}

class _SearchCard extends ConsumerWidget {
  final SearchHint hint;
  const _SearchCard({required this.hint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(jellyfinClientProvider);
    final url = hint.primaryImageTag != null
        ? client.imageUrl(
            hint.itemId,
            'Primary',
            maxWidth: 320,
            tag: hint.primaryImageTag,
          )
        : '';
    final shape = hint.kind == MediaKind.artist
        ? ArtShape.square
        : ArtShape.poster;
    return Focusable(
      onTap: () => ref
          .read(shellNavProvider.notifier)
          .openDetail(MediaItem(id: hint.itemId, name: hint.name)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppImage(url, shape: shape),
          SizedBox(height: dim(8)),
          Text(
            hint.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            [
              hint.type,
              if (hint.productionYear != null) '${hint.productionYear}',
            ].join('  •  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
