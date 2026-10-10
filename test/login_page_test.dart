import 'package:dio/dio.dart';
import 'package:finar/core/api/auth_service.dart';
import 'package:finar/core/api/jellyfin_api.dart';
import 'package:finar/core/api/models/user.dart';
import 'package:finar/pages/login_page.dart';
import 'package:finar/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.connectResult = true, this.loginError})
    : super(JellyfinApi());

  final bool connectResult;
  final Object? loginError;
  String? lastConnectUrl;

  @override
  Future<void> init() async {}

  @override
  Future<bool> connectToServer(String url) async {
    lastConnectUrl = url;
    return connectResult;
  }

  @override
  Future<AuthenticationResult> login({
    required String username,
    required String password,
  }) {
    return Future.error(loginError ?? UnimplementedError());
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

Future<void> _goToCredentialsStage(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Server'),
    'jellyfin.local',
  );
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('starts on the server stage', (tester) async {
    await _pumpLogin(tester);

    expect(find.text('Finar'), findsOneWidget);
    expect(find.text('Connect to your Jellyfin server'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
    expect(find.text('Quick Connect'), findsNothing);
  });

  testWidgets('empty server shows a validation error', (tester) async {
    await _pumpLogin(tester);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Enter your server URL'), findsOneWidget);
  });

  testWidgets('scheme prefix toggles between https and http', (tester) async {
    await _pumpLogin(tester);

    expect(find.text('https://'), findsOneWidget);
    await tester.tap(find.text('https://'));
    await tester.pump();

    expect(find.text('http://'), findsOneWidget);
    expect(find.text('https://'), findsNothing);
  });

  testWidgets('unreachable server stays on stage one with an error banner', (
    tester,
  ) async {
    final service = _FakeAuthService(connectResult: false);
    await _pumpLogin(tester, authService: service);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Server'),
      'jellyfin.local',
    );
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump();

    expect(service.lastConnectUrl, 'https://jellyfin.local');
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
    expect(
      find.text('Could not connect to server. Please check the URL.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('continue connects then shows the credentials stage', (
    tester,
  ) async {
    final service = _FakeAuthService();
    await _pumpLogin(tester, authService: service);
    await _goToCredentialsStage(tester);

    expect(service.lastConnectUrl, 'https://jellyfin.local');
    expect(find.text('https://jellyfin.local'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Quick Connect'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('back button returns to the server stage', (tester) async {
    await _pumpLogin(tester, authService: _FakeAuthService());
    await _goToCredentialsStage(tester);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
    expect(find.text('jellyfin.local'), findsOneWidget);
  });

  testWidgets('empty username shows a validation error on stage two', (
    tester,
  ) async {
    await _pumpLogin(tester, authService: _FakeAuthService());
    await _goToCredentialsStage(tester);

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Enter your username'), findsNWidgets(2));
  });

  testWidgets('password visibility toggle swaps the eye icon', (tester) async {
    await _pumpLogin(tester, authService: _FakeAuthService());
    await _goToCredentialsStage(tester);

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
  });

  testWidgets('failed login surfaces the auth error in a banner', (
    tester,
  ) async {
    final service = _FakeAuthService(loginError: Exception('boom'));
    await _pumpLogin(tester, authService: service);
    await _goToCredentialsStage(tester);

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

    expect(
      find.text('An error occurred. Please try again.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('a 400 from the server shows invalid credentials', (
    tester,
  ) async {
    final service = _FakeAuthService(
      loginError: DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 400,
        ),
      ),
    );
    await _pumpLogin(tester, authService: service);
    await _goToCredentialsStage(tester);

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

    expect(find.text('Invalid username or password.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('the response body message is shown when the server sends one', (
    tester,
  ) async {
    final service = _FakeAuthService(
      loginError: DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 400,
          data: 'Invalid user',
        ),
      ),
    );
    await _pumpLogin(tester, authService: service);
    await _goToCredentialsStage(tester);

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

    expect(find.text('Invalid user'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('quick connect shows the code and cancel returns to the form', (
    tester,
  ) async {
    final service = _FakeAuthService();
    await _pumpLogin(tester, authService: service);
    await _goToCredentialsStage(tester);

    await tester.tap(find.text('Quick Connect'));
    await tester.pump();
    await tester.pump();

    expect(find.text('482913'), findsOneWidget);
    expect(find.text('Waiting for authorization...'), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('482913'), findsNothing);
  });
}
