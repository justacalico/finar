import 'package:finar/pages/detail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  testWidgets('movie detail desktop', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(tester, const DetailPage(itemId: 'movie-1'));

    await expectGolden(tester, 'detail_desktop');
  });

  testWidgets('movie detail mobile', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(
      tester,
      const DetailPage(itemId: 'movie-1'),
      size: goldenMobileSize,
    );

    await expectGolden(tester, 'detail_mobile');
  });
}
