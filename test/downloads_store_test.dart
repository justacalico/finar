import 'package:finar/core/storage/downloads_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('empty when nothing saved', () async {
    SharedPreferences.setMockInitialValues({});
    final store =
        DownloadsStore(await SharedPreferences.getInstance());
    expect(store.load(), isEmpty);
  });

  test('round trips records', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = DownloadsStore(prefs);
    final record = DownloadRecord(
      itemId: 'i1',
      name: 'Movie',
      type: 'Movie',
      subtitle: 'Series',
      serverUrl: 'http://srv',
      localPath: '/tmp/i1.bin',
      status: DownloadStatus.completed,
      progress: 1,
      totalBytes: 2048,
    );
    await store.save([record]);
    final loaded = DownloadsStore(prefs).load();
    expect(loaded.single.itemId, 'i1');
    expect(loaded.single.status, DownloadStatus.completed);
    expect(loaded.single.totalBytes, 2048);
    expect(loaded.single.subtitle, 'Series');
  });

  test('corrupt payloads read as empty', () async {
    SharedPreferences.setMockInitialValues(
        {'downloads.records': '{not json'});
    final prefs = await SharedPreferences.getInstance();
    expect(DownloadsStore(prefs).load(), isEmpty);
  });
}
