import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/navigation_provider.dart';
import '../providers/providers.dart';
import '../providers/session_provider.dart';
import '../widgets/app_image.dart';
import '../widgets/focusable.dart';
import '../widgets/page_header.dart';

/// Grid of the user's Jellyfin libraries.
class LibrariesPage extends ConsumerWidget {
  const LibrariesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final libraries = session is SignedIn ? session.libraries : const [];
    final client = ref.read(jellyfinClientProvider);

    return Column(
      children: [
        const PageHeader(title: 'Libraries'),
        Expanded(
          child: libraries.isEmpty
              ? const Center(child: Text('No libraries found on this server.'))
              : GridView.builder(
                  padding: EdgeInsets.all(Insets.md),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: dim(280),
                    mainAxisSpacing: Insets.md,
                    crossAxisSpacing: Insets.md,
                    childAspectRatio: 16 / 10,
                  ),
                  itemCount: libraries.length,
                  itemBuilder: (context, i) {
                    final lib = libraries[i];
                    return Focusable(
                      onTap: () => ref
                          .read(shellNavProvider.notifier)
                          .openLibrary(
                            lib.id,
                            lib.name,
                            collectionType: lib.collectionType,
                          ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (lib.imageTags.primary != null)
                            AppImage(
                              client.imageUrl(
                                lib.id,
                                'Primary',
                                maxWidth: 560,
                                tag: lib.imageTags.primary,
                              ),
                              fill: true,
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(Radii.card),
                              ),
                              child: Icon(
                                lib.isMusic
                                    ? Icons.music_note_outlined
                                    : Icons.video_library_outlined,
                                size: dim(40),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.all(Insets.sm),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(Radii.card),
                                ),
                              ),
                              child: Text(
                                lib.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
