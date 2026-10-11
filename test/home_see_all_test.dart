import 'package:finar/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden/golden_helpers.dart';

void main() {
  testWidgets('see all on home expands into a grid and back returns', (
    tester,
  ) async {
    mockGoldenPlatformChannels();
    await pumpGolden(tester, const HomePage());

    await tester.tap(find.text('See All').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining(' items'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('See All'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('See All'), findsWidgets);
    expect(find.textContaining(' items'), findsNothing);
  });
}
