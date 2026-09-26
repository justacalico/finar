import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';
import 'providers.dart';
import 'session_provider.dart';

class HomeSection {
  final String title;
  final List<MediaItem> items;
  final String? libraryId;

  const HomeSection(this.title, this.items, {this.libraryId});
}

class HomeData {
  final List<MediaItem> resume;
  final List<MediaItem> nextUp;
  final List<HomeSection> latestByLibrary;
  final List<MediaItem> favorites;

  const HomeData({
    this.resume = const [],
    this.nextUp = const [],
    this.latestByLibrary = const [],
    this.favorites = const [],
  });

  /// Hero item for the top of the page: first resumable, else first
  /// recent item.
  MediaItem? get featured {
    if (resume.isNotEmpty) return resume.first;
    for (final s in latestByLibrary) {
      if (s.items.isNotEmpty) return s.items.first;
    }
    return null;
  }
}

class HomeNotifier extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() async {
    final session = ref.watch(sessionProvider);
    if (session is! SignedIn) return const HomeData();
    final client = ref.read(jellyfinClientProvider);

    Future<List<MediaItem>> orEmpty(Future<List<MediaItem>> f) =>
        f.catchError((_) => <MediaItem>[]);

    final results = await Future.wait([
      orEmpty(client.getResume()),
      orEmpty(client.getNextUp()),
      orEmpty(client
          .getItems(
              isFavorite: true,
              recursive: true,
              limit: 16,
              sortBy: 'SortName',
              fields: const ['Overview'])
          .then((r) => r.items)),
      for (final lib in session.libraries)
        orEmpty(client.getLatest(parentId: lib.id, limit: 16)),
    ]);

    final resume = results[0];
    final nextUp = results[1];
    final favorites = results[2];
    final latest = <HomeSection>[
      for (var i = 0; i < session.libraries.length; i++)
        if (results[3 + i].isNotEmpty)
          HomeSection('Latest ${session.libraries[i].name}',
              results[3 + i],
              libraryId: session.libraries[i].id),
    ];

    return HomeData(
      resume: resume,
      nextUp: nextUp,
      favorites: favorites,
      latestByLibrary: latest,
    );
  }
}

final homeProvider =
    AsyncNotifierProvider<HomeNotifier, HomeData>(HomeNotifier.new);
