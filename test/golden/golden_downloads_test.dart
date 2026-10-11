import 'package:finar/core/services/download_service.dart';
import 'package:finar/pages/downloads.dart';
import 'package:finar/providers/download_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_services.dart';
import 'golden_fixtures.dart';
import 'golden_helpers.dart';

void main() {
  testWidgets('downloads page empty', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(tester, const DownloadsPage());

    await expectGolden(tester, 'downloads_empty');
  });

  testWidgets('downloads page with tasks', (tester) async {
    mockGoldenPlatformChannels();
    final tasks = [
      DownloadTask(
        id: 'dl-1',
        itemId: 'movie-1',
        itemName: 'Dune: Part Two',
        itemType: 'Movie',
        status: DownloadStatus.completed,
        progress: 1.0,
        totalBytes: 4 * 1024 * 1024 * 1024,
        downloadedBytes: 4 * 1024 * 1024 * 1024,
        serverUrl: goldenServerUrl,
        createdAt: DateTime(2026, 9, 20),
        completedAt: DateTime(2026, 9, 20),
      ),
      DownloadTask(
        id: 'dl-2',
        itemId: 'movie-4',
        itemName: 'Interstellar',
        itemType: 'Movie',
        status: DownloadStatus.downloading,
        progress: 0.42,
        totalBytes: 6 * 1024 * 1024 * 1024,
        downloadedBytes: 2576980377,
        serverUrl: goldenServerUrl,
        createdAt: DateTime(2026, 10, 4),
      ),
      DownloadTask(
        id: 'dl-3',
        itemId: 'ep-1',
        itemName: 'Pilot',
        itemType: 'Episode',
        status: DownloadStatus.paused,
        progress: 0.7,
        totalBytes: 1024 * 1024 * 1024,
        downloadedBytes: 734003200,
        serverUrl: goldenServerUrl,
        createdAt: DateTime(2026, 10, 8),
      ),
    ];

    await pumpGolden(
      tester,
      const DownloadsPage(),
      overrides: [
        downloadProvider.overrideWith(
          (ref) => FakeDownloadNotifier(downloads: tasks),
        ),
      ],
    );

    await expectGolden(tester, 'downloads_with_tasks');
  });
}
