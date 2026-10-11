import 'package:finar/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_helpers.dart';

void main() {
  testWidgets('login page server stage', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(tester, const LoginPage());

    await expectGolden(tester, 'login_server_stage');
  });

  testWidgets('login page server stage on mobile', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(tester, const LoginPage(), size: goldenMobileSize);

    await expectGolden(tester, 'login_server_stage_mobile');
  });

  testWidgets('login page credentials stage', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(tester, const LoginPage());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Server'),
      'jellyfin.test',
    );
    await tester.tap(find.text('Continue'));
    await goldenSettle(tester);

    await expectGolden(tester, 'login_credentials_stage');
  });
}
