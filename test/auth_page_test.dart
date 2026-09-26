import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/storage/app_storage.dart';
import 'package:finar/pages/auth_page.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAdapter implements HttpClientAdapter {
  final dynamic Function(RequestOptions options)? handler;
  FakeAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    if (requestStream != null) await requestStream.drain<void>();
    return ResponseBody.fromString(
        jsonEncode(handler?.call(options) ?? {}), 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }
}

Future<Widget> app({
  dynamic Function(RequestOptions)? api,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = AppStorage(await SharedPreferences.getInstance());
  final dio = Dio()..httpClientAdapter = FakeAdapter(api);
  final client = JellyfinClient(dio: dio, deviceId: 't');
  return ProviderScope(
    overrides: [
      appStorageProvider.overrideWithValue(storage),
      jellyfinClientProvider.overrideWithValue(client),
    ],
    child: const MaterialApp(home: AuthPage()),
  );
}

void main() {
  testWidgets('server step shows scheme dropdown and address field',
      (t) async {
    await t.pumpWidget(await app());
    await t.pumpAndSettle();
    expect(find.text('Connect to a server'), findsOneWidget);
    expect(find.text('https://'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });

  testWidgets('connect moves to username and password step',
      (t) async {
    await t.pumpWidget(await app(api: (o) {
      if (o.path == '/System/Info/Public') {
        return {
          'Id': 'srv',
          'ServerName': 'Test Server',
          'Version': '10.9'
        };
      }
      return {};
    }));
    await t.pumpAndSettle();

    await t.enterText(
        find.byType(TextField).first, 'jellyfin.local:8096');
    await t.tap(find.text('Connect'));
    await t.pumpAndSettle();

    expect(find.text('Test Server'), findsOneWidget);
    expect(
        find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(
        find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    // No who's-watching picker.
    expect(find.text("Who's watching?"), findsNothing);
  });

  testWidgets('failed connect shows error and stays on server step',
      (t) async {
    await t.pumpWidget(await app(api: (o) {
      throw DioException(requestOptions: o);
    }));
    await t.pumpAndSettle();

    await t.enterText(find.byType(TextField).first, 'dead:8096');
    await t.tap(find.text('Connect'));
    await t.pumpAndSettle();

    expect(find.textContaining('Could not reach'), findsOneWidget);
    expect(find.text('Connect to a server'), findsOneWidget);
  });

  testWidgets('sign in with typed credentials succeeds', (t) async {
    await t.pumpWidget(await app(api: (o) {
      if (o.path == '/System/Info/Public') {
        return {'Id': 'srv', 'ServerName': 'Srv', 'Version': '1'};
      }
      if (o.path == '/Users/AuthenticateByName') {
        return {
          'User': {'Id': 'u1', 'Name': 'cal'},
          'AccessToken': 'tok',
          'ServerId': 'srv'
        };
      }
      return {'Items': []};
    }));
    await t.pumpAndSettle();

    await t.enterText(
        find.byType(TextField).first, 'jellyfin.local:8096');
    await t.tap(find.text('Connect'));
    await t.pumpAndSettle();

    await t.enterText(
        find.widgetWithText(TextField, 'Username'), 'cal');
    await t.enterText(
        find.widgetWithText(TextField, 'Password'), 'pw');
    await t.tap(find.text('Sign in'));
    await t.pumpAndSettle();

    final element =
        t.element(find.byType(AuthPage)) as ConsumerStatefulElement;
    final container =
        ProviderScope.containerOf(element);
    expect(container.read(sessionProvider), isA<SignedIn>());
  });

  testWidgets('saved accounts render and switch on tap', (t) async {
    const saved = SavedAccount(
        serverUrl: 'http://srv',
        serverName: 'Home',
        userId: 'u1',
        userName: 'cal',
        accessToken: 'tok');
    await t.pumpWidget(await app(
      api: (o) => {'Items': []},
      prefs: {'accounts.v1': jsonEncode([saved.toJson()])},
    ));
    await t.pumpAndSettle();

    expect(find.text('Saved accounts'), findsOneWidget);
    expect(find.text('cal'), findsOneWidget);
    await t.tap(find.text('cal'));
    await t.pumpAndSettle();

    final element =
        t.element(find.byType(AuthPage)) as ConsumerStatefulElement;
    expect(
        ProviderScope.containerOf(element).read(sessionProvider),
        isA<SignedIn>());
  });
}
