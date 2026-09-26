import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/storage/app_storage.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/pages/shell_page.dart';
import 'package:finar/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
          RequestOptions options,
          Stream<Uint8List>? requestStream,
          Future<void>? cancelFuture) async =>
      ResponseBody.fromString(jsonEncode({'Items': <dynamic>[]}), 200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
}

void main() {
  testWidgets('sidebar shows the app icon next to the wordmark',
      (t) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final storage =
        AppStorage(await SharedPreferences.getInstance());
    final client = JellyfinClient(
        dio: Dio()..httpClientAdapter = _FakeAdapter(),
        deviceId: 't')
      ..setServerUrl('http://srv')
      ..setCredentials(accessToken: 't', userId: 'u');
    await t.pumpWidget(ProviderScope(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
        jellyfinClientProvider.overrideWithValue(client),
      ],
      child: MaterialApp(
        theme: AppTheme.build(
            Brightness.dark, kAccentOptions['System']!),
        home: const ShellPage(),
      ),
    ));
    await t.pump();
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Finar'), findsOneWidget);
    // Settings is pinned to the bottom of the sidebar, not
    // inline with the other destinations.
    final settings =
        find.widgetWithText(ListTile, 'Settings');
    expect(settings, findsOneWidget);
    final bottom = t.getBottomLeft(settings).dy;
    expect(bottom, greaterThan(700));
    final libraries =
        find.widgetWithText(ListTile, 'Libraries');
    expect(
        bottom, greaterThan(t.getBottomLeft(libraries).dy));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });
}
