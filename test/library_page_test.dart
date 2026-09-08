import 'package:finar/core/api/jellyfin_api.dart';
import 'package:finar/core/api/media_service.dart';
import 'package:finar/core/api/models/library.dart';
import 'package:finar/pages/library/library_header.dart';
import 'package:finar/pages/library/library_page.dart';
import 'package:finar/providers/library_provider.dart';
import 'package:finar/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMediaService extends MediaService {
  _FakeMediaService() : super(JellyfinApi());

  @override
  Future<LibraryContent> getLibraryContent(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    List<String>? genres,
    List<int>? years,
    String? searchTerm,
  }) async {
    return const LibraryContent(items: [], totalCount: 0, hasMore: false);
  }

  @override
  Future<LibraryContent> getMusicLibraryContent(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    return const LibraryContent(items: [], totalCount: 0, hasMore: false);
  }

  @override
  Future<LibraryContent> getMusicArtists(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    return const LibraryContent(items: [], totalCount: 0, hasMore: false);
  }

  @override
  Future<LibraryContent> getMusicTracks(
    String libraryId, {
    int startIndex = 0,
    int limit = 50,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    String? searchTerm,
  }) async {
    return const LibraryContent(items: [], totalCount: 0, hasMore: false);
  }
}

Widget _wrap(Widget child, {List<Library> libraries = const []}) =>
    ProviderScope(
      overrides: [
        mediaServiceProvider.overrideWith((ref) => _FakeMediaService()),
        librariesProvider.overrideWith((ref) => Future.value(libraries)),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('LibraryHeader displays the library name', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LibraryHeader(title: 'Movies')),
      ),
    );
    await tester.pump();

    expect(find.text('Movies'), findsOneWidget);
  });

  testWidgets('LibraryPage uses the library name for a non-music library', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const LibraryPage(libraryId: 'lib1'),
        libraries: const [
          Library(id: 'lib1', name: 'Movies', collectionType: 'movies'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Movies'), findsOneWidget);
  });

  testWidgets('LibraryPage uses the library name for a music library', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const LibraryPage(libraryId: 'music1'),
        libraries: const [
          Library(id: 'music1', name: 'My Music', collectionType: 'music'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Music'), findsOneWidget);
    expect(find.text('Albums (0)'), findsOneWidget);
  });
}
