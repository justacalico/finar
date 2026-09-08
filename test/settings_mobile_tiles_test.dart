import 'package:finar/pages/settings/widgets/settings_mobile_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'mobileDropdownTile keeps the selected value next to the arrow',
    (tester) async {
      // The button sizes itself to the longest item, so a short value like
      // 'Off' must be right-aligned inside it rather than floating left.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => mobileDropdownTile<int>(
                context,
                'Sleep Timer',
                0,
                const [
                  DropdownMenuItem(value: 0, child: Text('Off')),
                  DropdownMenuItem(value: -1, child: Text('End of current')),
                ],
                (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>),
      );
      expect(dropdown.alignment, AlignmentDirectional.centerEnd);

      final valueRight = tester.getTopRight(find.text('Off')).dx;
      final arrowLeft = tester
          .getTopLeft(find.byIcon(Icons.keyboard_arrow_down_rounded))
          .dx;
      expect(arrowLeft - valueRight, lessThan(24));
    },
  );
}
