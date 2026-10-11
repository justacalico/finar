import 'package:finar/pages/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  testWidgets('settings page desktop', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(tester, const SettingsPage());

    await expectGolden(tester, 'settings_desktop');
  });

  testWidgets('settings page mobile', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(
      tester,
      const SettingsPage(),
      size: goldenMobileSize,
    );

    await expectGolden(tester, 'settings_mobile');
  });
}
