import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finar/core/storage/downloads_store.dart';
import 'package:finar/providers/core_providers.dart';
import 'package:finar/providers/downloads_provider.dart';
import 'package:finar/providers/session_provider.dart';

import 'helpers/fake_client.dart';
import 'helpers/path_provider_mock.dart';
import 'helpers/secure_storage_mock.dart';
import 'helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Directory? tmp;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
    tmp = Directory.systemTemp.createTempSync('finar_dl_test');
    mockPathProvider(documentsDir: tmp!.path);
  });

  tearDown(() {
    tmp?.deleteSync(recursive: true);
  });

  Future<ProviderContainer> makeContainer(FakeJellyfinClient client) async {
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(
          await SharedPreferences.getInstance()),
      jellyfinClientProvider.overrideWithValue(client),
      sessionProvider
          .overrideWith(() => FakeSessionNotifier(testSession())),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('download completes and persists', () async {
    final client = FakeJellyfinClient();
    final c = await makeContainer(client);
    await c.read(downloadsProvider.notifier).start(makeItem(id: 'm1', name: 'Film'));
    await pumpEventQueue();
    final records = c.read(downloadsProvider);
    expect(records.single.status, DownloadStatus.completed);
    expect(records.single.progress, 1);
    expect(File(records.single.localPath).existsSync(), isTrue);
    expect(
        c.read(downloadsProvider.notifier).isDownloaded('m1'), isTrue);
  });

  test('duplicate download is ignored', () async {
    final client = FakeJellyfinClient();
    final c = await makeContainer(client);
    await c.read(downloadsProvider.notifier).start(makeItem(id: 'm1'));
    await pumpEventQueue();
    await c.read(downloadsProvider.notifier).start(makeItem(id: 'm1'));
    await pumpEventQueue();
    expect(c.read(downloadsProvider).length, 1);
  });

  test('remove deletes file and record', () async {
    final client = FakeJellyfinClient();
    final c = await makeContainer(client);
    await c.read(downloadsProvider.notifier).start(makeItem(id: 'm1'));
    await pumpEventQueue();
    final path = c.read(downloadsProvider).single.localPath;
    await c.read(downloadsProvider.notifier).remove('m1');
    expect(c.read(downloadsProvider), isEmpty);
    expect(File(path).existsSync(), isFalse);
  });

  test('signed out start does nothing', () async {
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      jellyfinClientProvider.overrideWithValue(null),
      sessionProvider.overrideWith(() => FakeSessionNotifier(null)),
    ]);
    addTearDown(c.dispose);
    await c.read(downloadsProvider.notifier).start(makeItem());
    expect(c.read(downloadsProvider), isEmpty);
  });
}
