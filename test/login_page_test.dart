import 'package:finar/core/api/auth_service.dart';
import 'package:finar/core/api/jellyfin_api.dart';
import 'package:finar/core/api/models/user.dart';
import 'package:finar/pages/login_page.dart';
import 'package:finar/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.connectResult = true}) : super(JellyfinApi());

  final bool connectResult;
  String? lastConnectUrl;

  @override
  Future<void> init() async {}

  @override
  Future<bool> connectToServer(String url) async {
    lastConnectUrl = url;
    return connectResult;
  }

  @override
  Future<String> initiateQuickConnect() async => '482913';

  @override
  Future<AuthenticationResult?> checkQuickConnect(String secret) async => null;
}

Future<void> _pumpLogin(WidgetTester tester, {AuthService? authService}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (authService != null)
          authServiceProvider.overrideWithValue(authService),
      ],
      child: const MaterialApp(home: LoginPage()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renders sign in form inside a card', (tester) async {
    await _pumpLogin(tester);

    expect(find.text('Finar'), findsOneWidget);
    expect(find.text('Sign in to your Jellyfin server'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Quick Connect'), findsOneWidget);
  });

  testWidgets('shows validation errors when submitting an empty form', (
    tester,
  ) async {
    await _pumpLogin(tester);

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Enter your server URL'), findsOneWidget);
    expect(find.text('Enter your username'), findsNWidgets(2));
  });

  testWidgets('scheme prefix toggles between https and http', (tester) async {
    await _pumpLogin(tester);

    expect(find.text('https://'), findsOneWidget);
    await tester.tap(find.text('https://'));
    await tester.pump();

    expect(find.text('http://'), findsOneWidget);
    expect(find.text('https://'), findsNothing);
  });

  testWidgets('password visibility toggle swaps the eye icon', (tester) async {
    await _pumpLogin(tester);

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
  });

  testWidgets('quick connect without a server url shows an error banner', (
    tester,
  ) async {
    await _pumpLogin(tester);

    await tester.tap(find.text('Quick Connect'));
    await tester.pump();

    expect(find.text('Enter your server URL first'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('failed login surfaces the auth error in a banner', (
    tester,
  ) async {
    final service = _FakeAuthService(connectResult: false);
    await _pumpLogin(tester, authService: service);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Server'),
      'jellyfin.local',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'calico',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'hunter2',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pump();

    expect(service.lastConnectUrl, 'https://jellyfin.local');
    expect(
      find.text(
        'Could not connect to server. Please check the URL and ensure the server is running.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('quick connect shows the code and cancel returns to the form', (
    tester,
  ) async {
    final service = _FakeAuthService();
    await _pumpLogin(tester, authService: service);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Server'),
      'jellyfin.local',
    );
    await tester.tap(find.text('Quick Connect'));
    await tester.pump();
    await tester.pump();

    expect(service.lastConnectUrl, 'https://jellyfin.local');
    expect(find.text('482913'), findsOneWidget);
    expect(find.text('Waiting for authorization...'), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('482913'), findsNothing);
  });
}
