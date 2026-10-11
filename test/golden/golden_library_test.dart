import 'package:finar/pages/home/widgets/home_library_browser.dart';
import 'package:finar/pages/library/library_page.dart';
import 'package:finar/pages/music_library.dart';
import 'package:finar/pages/music_library_mobile.dart';
import 'package:finar/providers/library_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_fixtures.dart';
import 'golden_helpers.dart';

void main() {
  testWidgets('library browser', (tester) async {
    mockGoldenPlatformChannels();
    final container = goldenContainer();
    addTearDown(container.dispose);
    container.read(libraryProvider.notifier).state = const LibraryState(
      libraries: goldenLibraries,
    );

    await pumpGolden(
      tester,
      const Scaffold(body: LibraryBrowser()),
      container: container,
    );

    await expectGolden(tester, 'library_browser');
  });

  testWidgets('library page desktop', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(tester, const LibraryPage(libraryId: 'lib-movies'));

    await expectGolden(tester, 'library_desktop');
  });

  testWidgets('library page mobile', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(
      tester,
      const LibraryPage(libraryId: 'lib-movies'),
      size: goldenMobileSize,
    );

    await expectGolden(tester, 'library_mobile');
  });

  testWidgets('music library desktop', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(
      tester,
      const Scaffold(
        body: MusicLibraryDesktop(libraryId: 'lib-music', libraryName: 'Music'),
      ),
    );

    await expectGolden(tester, 'music_library_desktop');
  });

  testWidgets('music library mobile', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(
      tester,
      const Scaffold(
        body: MusicLibraryMobile(libraryId: 'lib-music', libraryName: 'Music'),
      ),
      size: goldenMobileSize,
    );

    await expectGolden(tester, 'music_library_mobile');
  });
}
