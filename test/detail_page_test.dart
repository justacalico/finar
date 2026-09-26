import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/api/models.dart';
import 'package:finar/core/storage/app_storage.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/pages/detail_page.dart';
import 'package:finar/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAdapter implements HttpClientAdapter {
  final dynamic Function(RequestOptions options) handler;
  _FakeAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
          RequestOptions options,
          Stream<Uint8List>? requestStream,
          Future<void>? cancelFuture) async =>
      ResponseBody.fromString(jsonEncode(handler(options)), 200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
}

const _movie = MediaItem(
  id: 'm1',
  name: 'A Film',
  kind: MediaKind.movie,
);

void main() {
  testWidgets('back button sits inset from the hero corner',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    final storage =
        AppStorage(await SharedPreferences.getInstance());
    final client = JellyfinClient(
        dio: Dio()
          ..httpClientAdapter = _FakeAdapter((o) {
            if (o.path.contains('/Similar')) {
              return {'Items': <dynamic>[]};
            }
            return {'Id': 'm1', 'Name': 'A Film', 'Type': 'Movie'};
          }),
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
        home: const DetailPage(itemId: 'm1', item: _movie),
      ),
    ));
    await t.pump();
    final topLeft =
        t.getTopLeft(find.byIcon(Icons.arrow_back));
    expect(topLeft.dx, greaterThan(0));
    expect(topLeft.dy, greaterThan(0));
    // Let autoDispose providers fire their teardown timers.
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });
}
