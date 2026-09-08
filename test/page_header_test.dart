import 'package:finar/widgets/page_header.dart';
import 'package:finar/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PageHeader shows the title in a glass bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PageHeader(title: 'Settings'))),
    );
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.byType(GlassContainer), findsOneWidget);
  });

  testWidgets('PageHeader hides the back button when nothing can pop', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PageHeader(title: 'Downloads'))),
    );
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  testWidgets('PageHeader back button pops a pushed route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const Scaffold(body: PageHeader(title: 'Search')),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Search'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('go'), findsOneWidget);
    expect(find.text('Search'), findsNothing);
  });

  testWidgets('PageHeader uses the explicit back handler when given', (
    tester,
  ) async {
    var popped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageHeader(title: 'Library', onBack: () => popped = true),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(popped, isTrue);
  });

  testWidgets('PageHeader renders trailing controls', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PageHeader(
            title: 'Downloads',
            trailing: Icon(Icons.sort),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.sort), findsOneWidget);
  });
}
