import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/library_providers.dart';
import '../../providers/session_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/media_card.dart';
import '../../widgets/responsive.dart';

final _queryProvider = StateProvider<String>((ref) => '');

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(_queryProvider);
    final results = ref.watch(searchResultsProvider(query));
    final client = ref.watch(jellyfinClientProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        ref.read(_queryProvider.notifier).state = '';
                      },
                    ),
            ),
            onChanged: (v) =>
                ref.read(_queryProvider.notifier).state = v,
          ),
        ),
        Expanded(
          child: query.trim().isEmpty
              ? EmptyState(
                  icon: Icons.search, message: l10n.startSearch)
              : results.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (_, _) => EmptyState(
                      icon: Icons.error_outline,
                      message: l10n.error),
                  data: (items) {
                    if (items.isEmpty) {
                      return EmptyState(
                          icon: Icons.search_off,
                          message: l10n.noResults);
                    }
                    final width = MediaQuery.sizeOf(context).width -
                        (isDesktopLayout(context) ? 244 : 0);
                    final columns = gridColumnsForWidth(width);
                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return MediaCard(
                          item: item,
                          width: double.infinity,
                          imageUrl: client?.primaryImageUrl(item,
                              maxWidth: 400),
                          subtitle: item.type,
                          onTap: () =>
                              context.push('/item/${item.id}'),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
