import 'package:finar/pages/settings/widgets/settings_desktop.dart';
import 'package:finar/pages/settings/widgets/settings_mobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return ProviderScope(child: MaterialApp(home: child));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'embedded desktop settings hides back button and account actions',
    (tester) async {
      await tester.pumpWidget(_wrap(const SettingsDesktop(embedded: true)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.text('Switch profile'), findsNothing);
      expect(find.text('Sign out'), findsNothing);
      // Section rail and first section still render
      expect(find.text('General'), findsWidgets);
      expect(find.text('Playback'), findsWidgets);
    },
  );

  testWidgets(
    'standalone desktop settings keeps back button and account actions',
    (tester) async {
      await tester.pumpWidget(_wrap(const SettingsDesktop()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text('Switch profile'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    },
  );

  testWidgets('embedded mobile settings app bar has no back button', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SettingsMobile(embedded: true)));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  testWidgets('standalone mobile settings shows a back button', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsMobile()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('desktop settings content fills the pane and starts at top', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const SettingsDesktop(embedded: true)));
    await tester.pumpAndSettle();

    // The scroll view must fill the content pane instead of shrink wrapping
    // its section, which would leave the section centered in the Row.
    final scrollView = find.byType(SingleChildScrollView);
    expect(scrollView, findsOneWidget);
    expect(tester.getRect(scrollView).height, greaterThan(800));

    final subtitle = find.text('Customize your app experience');
    expect(subtitle, findsOneWidget);
    expect(tester.getTopLeft(subtitle).dy, lessThan(200));
  });
}
