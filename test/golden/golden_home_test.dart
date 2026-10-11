import 'package:finar/pages/home.dart';
import 'package:finar/providers/library_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_fixtures.dart';
import 'golden_helpers.dart';

void main() {
  testWidgets('home page desktop', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(tester, const HomePage());

    await expectGolden(tester, 'home_desktop');
  });

  testWidgets('home page mobile', (tester) async {
    mockGoldenPlatformChannels();
    final container = goldenContainer();
    addTearDown(container.dispose);
    container.read(libraryProvider.notifier).state = LibraryState(
      libraries: goldenLibraries,
      homeData: goldenHomeData,
    );

    await pumpGolden(
      tester,
      const HomePage(),
      size: goldenMobileSize,
      container: container,
    );

    await expectGolden(tester, 'home_mobile');
  });
}
