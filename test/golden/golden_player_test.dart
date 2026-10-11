import 'package:finar/pages/player.dart';
import 'package:finar/providers/player_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_services.dart';
import 'golden_fixtures.dart';
import 'golden_helpers.dart';

void main() {
  List<Override> goldenPlayerOverrides(PlayerState seed) => [
    playerProvider.overrideWith(
      (ref) => GoldenPlayerNotifier(
        FakeMediaService(),
        FakeDownloadService(),
        seed,
      ),
    ),
  ];

  PlayerState playingSeed() => PlayerState(
    currentItem: goldenMovies[0],
    isPlaying: true,
    position: const Duration(minutes: 24),
    duration: const Duration(minutes: 112),
    bufferedPosition: const Duration(minutes: 30),
    volume: 0.8,
  );

  testWidgets('player page desktop', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(
      tester,
      const PlayerPage(),
      overrides: goldenPlayerOverrides(playingSeed()),
      settle: false,
    );

    await expectGolden(tester, 'player_desktop');
  });

  testWidgets('player page mobile', (tester) async {
    mockGoldenPlatformChannels();
    await pumpGolden(
      tester,
      const PlayerPage(),
      size: goldenMobileSize,
      overrides: goldenPlayerOverrides(playingSeed()),
      settle: false,
    );

    await expectGolden(tester, 'player_mobile');
  });
}
