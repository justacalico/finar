import 'package:finar/pages/settings/widgets/settings_about_mobile_section.dart';
import 'package:finar/pages/settings/widgets/settings_about_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _seed = Colors.teal;

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed)),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Finar',
      packageName: 'ink.openlyst.finar',
      version: '4.1.1',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('desktop Source Code icon uses the theme primary colour', (
    tester,
  ) async {
    // The OS Version tile shows the raw kernel string, which needs a wide
    // surface or the tile's title runs out of room.
    tester.view.physicalSize = const Size(4000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const SettingsAboutSection()));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.code));
    expect(icon.color, ColorScheme.fromSeed(seedColor: _seed).primary);
  });

  testWidgets('mobile Source Code icon uses the theme primary colour', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SettingsAboutMobileSection()));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.code_rounded));
    expect(icon.color, ColorScheme.fromSeed(seedColor: _seed).primary);
  });
}
