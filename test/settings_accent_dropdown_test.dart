import 'package:finar/pages/settings/widgets/settings_appearance_mobile_section.dart';
import 'package:finar/pages/settings/widgets/settings_general_section.dart';
import 'package:finar/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpSection(
  WidgetTester tester,
  Widget child,
) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
  return container;
}

Finder _accentDropdown() => find.byWidgetPredicate(
  (w) => w is DropdownButton<int>,
);

Future<void> _pickAccentOption(WidgetTester tester, String label) async {
  await tester.ensureVisible(_accentDropdown());
  await tester.tap(_accentDropdown());
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mobile appearance accent dropdown', () {
    testWidgets('removes the Use system accent switch', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpSection(tester, const SettingsAppearanceMobileSection());

      expect(find.text('Use system accent'), findsNothing);
      expect(_accentDropdown(), findsOneWidget);
    });

    testWidgets('System option enables useSystemAccent', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await _pumpSection(
        tester,
        const SettingsAppearanceMobileSection(),
      );

      expect(container.read(settingsProvider).useSystemAccent, isFalse);
      expect(
        tester.widget<DropdownButton<int>>(_accentDropdown()).value,
        0,
      );

      await _pickAccentOption(tester, 'System');

      expect(container.read(settingsProvider).useSystemAccent, isTrue);
    });

    testWidgets('picking a colour clears useSystemAccent', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await _pumpSection(
        tester,
        const SettingsAppearanceMobileSection(),
      );

      await _pickAccentOption(tester, 'System');
      expect(container.read(settingsProvider).useSystemAccent, isTrue);

      await _pickAccentOption(tester, 'Pink');

      final settings = container.read(settingsProvider);
      expect(settings.useSystemAccent, isFalse);
      expect(settings.accentColorIndex, 3);
    });
  });

  group('desktop general accent dropdown', () {
    testWidgets('removes the Use system accent switch', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpSection(tester, SettingsGeneralSection(onReset: () {}));

      expect(find.text('Use system accent'), findsNothing);
      expect(_accentDropdown(), findsOneWidget);
    });

    testWidgets('System option enables useSystemAccent', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await _pumpSection(
        tester,
        SettingsGeneralSection(onReset: () {}),
      );

      await _pickAccentOption(tester, 'System');

      expect(container.read(settingsProvider).useSystemAccent, isTrue);
    });

    testWidgets('picking a colour clears useSystemAccent', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await _pumpSection(
        tester,
        SettingsGeneralSection(onReset: () {}),
      );

      await _pickAccentOption(tester, 'Blue');

      final settings = container.read(settingsProvider);
      expect(settings.useSystemAccent, isFalse);
      expect(settings.accentColorIndex, 2);
    });
  });
}
