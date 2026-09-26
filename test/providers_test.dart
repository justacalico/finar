import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/api/models.dart';
import 'package:finar/core/storage/app_storage.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/downloads_provider.dart';
import 'package:finar/providers/library_provider.dart';
import 'package:finar/providers/navigation_provider.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAdapter implements HttpClientAdapter {
  final dynamic Function(RequestOptions options)? handler;
  final List<RequestOptions> requests = [];

  FakeAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture) async {
    requests.add(options);
    final data = handler?.call(options);
    return ResponseBody.fromString(jsonEncode(data ?? {}), 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }
}

JellyfinClient fakeClient(
    dynamic Function(RequestOptions) handler) {
  final dio = Dio()..httpClientAdapter = FakeAdapter(handler);
  return JellyfinClient(dio: dio, deviceId: 'test')
    ..setServerUrl('http://srv')
    ..setCredentials(accessToken: 't', userId: 'u1');
}

Future<ProviderContainer> container({
  dynamic Function(RequestOptions)? api,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = AppStorage(await SharedPreferences.getInstance());
  final c = ProviderContainer(overrides: [
    appStorageProvider.overrideWithValue(storage),
    jellyfinClientProvider
        .overrideWithValue(fakeClient(api ?? (_) => {})),
  ]);
  addTearDown(c.dispose);
  return c;
}

Map<String, dynamic> itemJson(String id) =>
    {'Id': id, 'Name': 'Item $id', 'Type': 'Movie'};

void main() {
  group('SettingsNotifier', () {
    test('defaults', () async {
      final c = await container();
      final s = c.read(settingsProvider);
      expect(s.themeMode, AppThemeMode.system);
      expect(s.accentName, 'System');
      expect(s.autoplayNext, isTrue);
    });

    test('updates persist to storage', () async {
      final c = await container();
      await c
          .read(settingsProvider.notifier)
          .setThemeMode(AppThemeMode.dark);
      await c.read(settingsProvider.notifier).setAccent('Pink');
      final stored =
          c.read(appStorageProvider).settings();
      expect(stored['themeMode'], 'dark');
      expect(stored['accentName'], 'Pink');
    });

    test('restores saved settings', () async {
      final c = await container(prefs: {
        'settings.v1':
            jsonEncode({'themeMode': 'oled', 'accentName': 'Teal'})
      });
      final s = c.read(settingsProvider);
      expect(s.themeMode, AppThemeMode.oled);
      expect(s.oled, isTrue);
      expect(s.accentName, 'Teal');
      expect(s.accent, kAccentOptions['Teal']);
    });

    test('subtitle and playback setters', () async {
      final c = await container();
      final n = c.read(settingsProvider.notifier);
      await n.setSubtitlesEnabled(false);
      await n.setSubtitleSize(1.5);
      await n.setMaxBitrate(4000000);
      await n.setAutoplayNext(false);
      final s = c.read(settingsProvider);
      expect(s.subtitlesEnabled, isFalse);
      expect(s.subtitleSize, 1.5);
      expect(s.maxStreamingBitrate, 4000000);
      expect(s.autoplayNext, isFalse);
    });

    test('zoom steps, clamps and resets', () async {
      final c = await container();
      final n = c.read(settingsProvider.notifier);
      expect(c.read(settingsProvider).uiScale, 1.0);
      await n.zoomIn();
      expect(c.read(settingsProvider).uiScale, 1.1);
      await n.zoomOut();
      expect(c.read(settingsProvider).uiScale, 1.0);
      for (var i = 0; i < 10; i++) {
        await n.zoomOut();
      }
      expect(c.read(settingsProvider).uiScale, 0.5);
      for (var i = 0; i < 20; i++) {
        await n.zoomIn();
      }
      expect(c.read(settingsProvider).uiScale, 2.0);
      await n.resetZoom();
      expect(c.read(settingsProvider).uiScale, 1.0);
      // Persisted with the rest of the settings.
      expect(c.read(appStorageProvider).settings()['uiScale'], 1.0);
    });
  });

  group('AppTheme', () {
    test('tonal surfaces stay quiet, not vivid', () {
      final dark = AppTheme.scheme(
          Brightness.dark, kAccentOptions['System']!);
      expect(dark.secondaryContainer,
          isNot(equals(dark.primary)));
      expect(dark.onSecondaryContainer, dark.onSurface);
      final light = AppTheme.scheme(
          Brightness.light, kAccentOptions['System']!);
      expect(light.secondaryContainer,
          isNot(equals(light.primary)));
      final oled = AppTheme.scheme(
          Brightness.dark, kAccentOptions['System']!,
          oled: true);
      expect(oled.surface.value, 0xFF000000);
    });
  });

  group('ShellNavNotifier', () {
    test('select, open and close library', () async {
      final c = await container();
      final n = c.read(shellNavProvider.notifier);
      n.select(ShellSection.downloads);
      expect(
          c.read(shellNavProvider).section, ShellSection.downloads);
      n.openLibrary('l1', 'Movies', collectionType: 'movies');
      expect(c.read(shellNavProvider).libraryId, 'l1');
      expect(c.read(shellNavProvider).libraryCollectionType,
          'movies');
      n.closeLibrary();
      expect(c.read(shellNavProvider).libraryId, isNull);
      expect(
          c.read(shellNavProvider).section, ShellSection.libraries);
    });

    test('section labels are non-empty', () {
      for (final s in ShellSection.values) {
        expect(s.label, isNotEmpty);
      }
    });

    test('detail stack pushes, pops and clears', () async {
      final c = await container();
      final n = c.read(shellNavProvider.notifier);
      const a = MediaItem(id: 'a', name: 'A');
      const b = MediaItem(id: 'b', name: 'B');

      n.openDetail(a);
      expect(c.read(shellNavProvider).detailItem?.id, 'a');
      n.openDetail(b);
      expect(c.read(shellNavProvider).detailItem?.id, 'b');
      expect(c.read(shellNavProvider).detailStack.length, 2);

      n.closeDetail();
      expect(c.read(shellNavProvider).detailItem?.id, 'a');
      n.closeDetail();
      expect(c.read(shellNavProvider).detailItem, isNull);
      // Closing an empty stack is a no-op.
      n.closeDetail();
      expect(c.read(shellNavProvider).detailStack, isEmpty);
    });

    test('selecting a section clears the detail stack', () async {
      final c = await container();
      final n = c.read(shellNavProvider.notifier);
      n.openDetail(const MediaItem(id: 'a', name: 'A'));
      n.select(ShellSection.settings);
      expect(c.read(shellNavProvider).detailStack, isEmpty);
      expect(
          c.read(shellNavProvider).section, ShellSection.settings);
    });
  });

  group('ItemQuery', () {
    test('equality and hashing', () {
      const a = ItemQuery(
          parentId: 'l', types: ['Movie'], sortBy: 'SortName');
      const b = ItemQuery(
          parentId: 'l', types: ['Movie'], sortBy: 'SortName');
      const different = ItemQuery(
          parentId: 'l', types: ['Series'], sortBy: 'SortName');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(different)));
    });
  });

  group('PagedItemsNotifier', () {
    test('fetches first page and reports hasMore', () async {
      final c = await container(api: (o) {
        expect(o.queryParameters['ParentId'], 'l1');
        return {
          'Items': [itemJson('a'), itemJson('b')],
          'TotalRecordCount': 5,
        };
      });
      const query = ItemQuery(parentId: 'l1');
      final page =
          await c.read(pagedItemsProvider(query).future);
      expect(page.items.length, 2);
      expect(page.total, 5);
      expect(page.hasMore, isTrue);
    });

    test('loadMore appends items', () async {
      final c = await container(api: (o) {
        final start =
            o.queryParameters['StartIndex'] as int? ?? 0;
        if (start == 0) {
          return {
            'Items': [itemJson('a'), itemJson('b')],
            'TotalRecordCount': 4,
          };
        }
        return {
          'Items': [itemJson('c'), itemJson('d')],
          'TotalRecordCount': 4,
        };
      });
      const query = ItemQuery(parentId: 'l1');
      await c.read(pagedItemsProvider(query).future);
      await c
          .read(pagedItemsProvider(query).notifier)
          .loadMore();
      final page = c.read(pagedItemsProvider(query)).value!;
      expect(page.items.map((i) => i.id).toList(),
          ['a', 'b', 'c', 'd']);
      expect(page.hasMore, isFalse);
    });

    test('updateItem patches matching entries in place', () async {
      final c = await container(api: (o) => {
            'Items': [itemJson('a'), itemJson('b')],
            'TotalRecordCount': 2,
          });
      const query = ItemQuery(parentId: 'l1');
      await c.read(pagedItemsProvider(query).future);
      final original = c
          .read(pagedItemsProvider(query))
          .value!
          .items
          .first;
      c
          .read(pagedItemsProvider(query).notifier)
          .updateItem(original.copyWith(
              userData: const UserData(played: true)));
      final patched = c
          .read(pagedItemsProvider(query))
          .value!
          .items
          .first;
      expect(patched.isPlayed, isTrue);
    });

    test('loadMore does nothing when complete', () async {
      var calls = 0;
      final c = await container(api: (o) {
        calls++;
        return {
          'Items': [itemJson('a')],
          'TotalRecordCount': 1,
        };
      });
      const query = ItemQuery(parentId: 'l1');
      await c.read(pagedItemsProvider(query).future);
      calls = 0;
      await c
          .read(pagedItemsProvider(query).notifier)
          .loadMore();
      expect(calls, 0);
    });
  });

  group('DownloadEntry', () {
    test('json round trip', () {
      const item = MediaItem(id: 'x', name: 'X');
      const e = DownloadEntry(
          item: item,
          localPath: '/tmp/x.mkv',
          status: DownloadStatus.done,
          progress: 1);
      final back = DownloadEntry.fromJson(e.toJson());
      expect(back.status, DownloadStatus.done);
      expect(back.localPath, '/tmp/x.mkv');
      expect(back.item.id, 'x');
    });

    test('manifest load marks in-flight entries failed', () async {
      const item = MediaItem(id: 'x', name: 'X');
      const e = DownloadEntry(
          item: item,
          localPath: '/tmp/x.mkv',
          status: DownloadStatus.downloading,
          progress: 0.4);
      final c = await container(prefs: {
        'downloads.v1': jsonEncode([e.toJson()]),
      });
      final entries = c.read(downloadsProvider);
      expect(entries.single.status, DownloadStatus.failed);
    });

    test('empty manifest yields empty state', () async {
      final c = await container();
      expect(c.read(downloadsProvider), isEmpty);
    });
  });
}
