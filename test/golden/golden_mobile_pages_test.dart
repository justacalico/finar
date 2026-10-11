import 'package:finar/pages/home/widgets/home_favorites_view.dart';
import 'package:finar/pages/home/widgets/home_search_page.dart';
import 'package:finar/pages/home/widgets/home_see_all_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_fixtures.dart';
import 'golden_helpers.dart';

void main() {
  testWidgets('search page empty state', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(
      tester,
      const Scaffold(body: MobileSearchPage()),
      size: goldenMobileSize,
    );

    await expectGolden(tester, 'search_empty');
  });

  testWidgets('search page with results', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(
      tester,
      const Scaffold(body: MobileSearchPage()),
      size: goldenMobileSize,
    );

    await tester.enterText(find.byType(TextField), 'dune');
    await goldenSettle(tester);

    await expectGolden(tester, 'search_results');
  });

  testWidgets('see all page', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(
      tester,
      MobileSeeAllPage(
        title: 'Recently Added',
        items: goldenMovies,
        serverUrl: goldenServerUrl,
      ),
      size: goldenMobileSize,
    );

    await expectGolden(tester, 'see_all');
  });

  testWidgets('favorites view', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(
      tester,
      const Scaffold(body: MobileFavoritesView()),
      size: goldenMobileSize,
    );

    await expectGolden(tester, 'favorites_mobile');
  });
}
