import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/models/library.dart';
import '../../providers/providers.dart';
import '../../widgets/adaptive_layout.dart';
import '../library.dart';
import '../music_library.dart';

/// The single library page used for every Jellyfin library.
/// Movies, TV shows, music, photos etc. all route through here.
/// The header is the same for every topic; only the library name changes.
/// The content body below the header is chosen by the library collectionType.
class LibraryPage extends ConsumerWidget {
  final String libraryId;

  /// Back handler used when the page is embedded in the shell rather than
  /// pushed as a route, so the header still offers a way out.
  final VoidCallback? onBack;

  const LibraryPage({super.key, required this.libraryId, this.onBack});

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
      desktopBuilder:
          () => Material(
            type: MaterialType.transparency,
            child:
                isMusic
                    ? MusicLibraryDesktop(
                      libraryId: libraryId,
                      libraryName: library.name,
                    )
                    : LibraryDesktop(
                      libraryId: libraryId,
                      libraryName: library.name,
                    ),
          ),
      mobileBuilder:
          () => Scaffold(
            body: SafeArea(
              child:
                  isMusic
                      ? MusicLibraryMobile(
                        libraryId: libraryId,
                        libraryName: library.name,
                        onBack: onBack,
                      )
                      : LibraryMobile(
                        libraryId: libraryId,
                        libraryName: library.name,
                        onBack: onBack,
                      ),
            ),
          ),
    );
  }
}
