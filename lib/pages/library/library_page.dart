import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/models/library.dart';
import '../../providers/providers.dart';
import '../../widgets/adaptive_layout.dart';
import '../library.dart';
import '../music_library.dart';
import 'library_header.dart';

/// The single library page used for every Jellyfin library.
/// Movies, TV shows, music, photos etc. all route through here.
/// The header is the same for every topic; only the library name changes.
/// The content body below the header is chosen by the library collectionType.
class LibraryPage extends ConsumerWidget {
  final String libraryId;

  const LibraryPage({super.key, required this.libraryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final librariesAsync = ref.watch(librariesProvider);
    final library = librariesAsync.when(
      data: (libs) => libs.firstWhere(
        (l) => l.id == libraryId,
        orElse: () => Library(id: libraryId, name: 'Library'),
      ),
      loading: () => Library(id: libraryId, name: 'Library'),
      error: (_, _) => Library(id: libraryId, name: 'Library'),
    );

    final isMusic = library.collectionType?.toLowerCase() == 'music';

    return AdaptiveLayout(
      desktopBuilder: () => Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            LibraryHeader(title: library.name),
            Expanded(
              child: isMusic
                  ? MusicLibraryDesktop(libraryId: libraryId)
                  : LibraryDesktop(libraryId: libraryId),
            ),
          ],
        ),
      ),
      mobileBuilder: () => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              LibraryHeader(title: library.name),
              Expanded(
                child: isMusic
                    ? MusicLibraryMobile(libraryId: libraryId)
                    : LibraryMobile(libraryId: libraryId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
