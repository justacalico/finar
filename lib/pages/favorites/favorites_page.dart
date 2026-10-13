import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/library_providers.dart';
import '../../providers/session_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/media_card.dart';
import '../../widgets/responsive.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);
    final client = ref.watch(jellyfinClientProvider);
    return favorites.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          EmptyState(icon: Icons.error_outline, message: l10n.error),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
              icon: Icons.favorite_outline,
              message: l10n.emptyFavourites);
        }
        final width = MediaQuery.sizeOf(context).width -
            (isDesktopLayout(context) ? 244 : 0);
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumnsForWidth(width),
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
              imageUrl:
                  client?.primaryImageUrl(item, maxWidth: 400),
              subtitle: item.seriesName ??
                  item.productionYear?.toString(),
              onTap: () => context.push('/item/${item.id}'),
            );
          },
        );
      },
    );
  }
}
