import 'package:finar/widgets/window_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  const channel = MethodChannel('window_manager');
  final calls = <MethodCall>[];
  var maximized = false;

  setUp(() {
    calls.clear();
    maximized = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'isMaximized') return maximized;
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> pumpBar(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WindowTitleBar())),
    );
    await tester.pump();
  }

  testWidgets('WindowTitleBar shows the app title and a drag area', (
    tester,
  ) async {
    await pumpBar(tester);

    expect(find.text('Finar'), findsOneWidget);
    expect(find.byType(DragToMoveArea), findsOneWidget);
  });

  testWidgets('WindowTitleBar minimize button minimizes the window', (
    tester,
  ) async {
    await pumpBar(tester);

    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pump();

    expect(calls.map((c) => c.method), contains('minimize'));
  });

  testWidgets('WindowTitleBar close button closes the window', (tester) async {
    await pumpBar(tester);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(calls.map((c) => c.method), contains('close'));
  });

  testWidgets('WindowTitleBar maximize button maximizes a restored window', (
    tester,
  ) async {
    await pumpBar(tester);

    await tester.tap(find.byIcon(Icons.crop_square_rounded));
    await tester.pump();

    final methods = calls.map((c) => c.method).toList();
    expect(methods, contains('isMaximized'));
    expect(methods, contains('maximize'));
    expect(methods, isNot(contains('unmaximize')));

    expect(find.byIcon(Icons.filter_none_rounded), findsOneWidget);
  });

  testWidgets('WindowTitleBar maximize button restores a maximized window', (
    tester,
  ) async {
    maximized = true;
    await pumpBar(tester);

    await tester.tap(find.byIcon(Icons.crop_square_rounded));
    await tester.pump();

    final methods = calls.map((c) => c.method).toList();
    expect(methods, contains('unmaximize'));
    expect(methods, isNot(contains('maximize')));
  });
}
