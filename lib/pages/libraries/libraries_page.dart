import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/library_providers.dart';
import '../../providers/session_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/media_image.dart';
import '../../widgets/responsive.dart';

class LibrariesPage extends ConsumerWidget {
  const LibrariesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final libraries = ref.watch(librariesProvider);
    return libraries.when(
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          EmptyState(icon: Icons.error_outline, message: l10n.error),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
              icon: Icons.video_library_outlined,
              message: l10n.emptyLibrary);
        }
        final width = MediaQuery.sizeOf(context).width -
            (isDesktopLayout(context) ? 244 : 0);
        final columns = gridColumnsForWidth(width);
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 16 / 10,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) =>
              _LibraryCard(item: items[i]),
        );
      },
    );
  }
}

class _LibraryCard extends ConsumerWidget {
  const _LibraryCard({required this.item});

  final BaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(jellyfinClientProvider);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/library/${item.id}'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaImage(
              url: client?.primaryImageUrl(item, maxWidth: 480),
              icon: _iconFor(item.collectionType),
              borderRadius: 0,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String? collectionType) =>
      switch (collectionType) {
        'movies' => Icons.movie_outlined,
        'tvshows' => Icons.tv_outlined,
        'music' => Icons.music_note_outlined,
        'photos' => Icons.photo_outlined,
        'books' => Icons.book_outlined,
        _ => Icons.folder_outlined,
      };
}
