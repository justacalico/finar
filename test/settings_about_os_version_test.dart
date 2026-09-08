import 'package:finar/core/utils/platform_detector.dart';
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

  testWidgets('OS version is rendered as a ListTile subtitle on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const SettingsAboutSection()));
    await tester.pumpAndSettle();

    final osVersionTile = tester.widget<ListTile>(
      find.ancestor(of: find.text('OS Version'), matching: find.byType(ListTile)),
    );

    expect(osVersionTile.trailing, isNull);
    expect(osVersionTile.subtitle, isA<Text>());

    final subtitleText = osVersionTile.subtitle! as Text;
    expect(subtitleText.data, PlatformDetector.osVersion);
    expect(subtitleText.softWrap, isTrue);
    expect(subtitleText.maxLines, isNull);
  });
}
