import 'package:finar/core/api/jellyfin_api.dart';
import 'package:finar/core/api/media_service.dart';
import 'package:finar/core/services/download_service.dart';
import 'package:finar/pages/player/widgets/player_desktop_bottom_controls.dart';
import 'package:finar/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeJellyfinApi extends JellyfinApi {}

class _FakeMediaService extends MediaService {
  _FakeMediaService() : super(JellyfinApi());
}

Future<void> _pumpControls(
  WidgetTester tester, {
  required VoidCallback onToggleSettings,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerProvider.overrideWith(
          (ref) => PlayerNotifier.uninitialized(
            _FakeMediaService(),
            DownloadService(_FakeJellyfinApi()),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              PlayerDesktopBottomControls(
                controlsVisible: true,
                onToggleSettings: onToggleSettings,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows a single settings button and no duplicate track buttons', (
    tester,
  ) async {
    await _pumpControls(tester, onToggleSettings: () {});

    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.subtitles), findsNothing);
    expect(find.byIcon(Icons.audiotrack), findsNothing);
  });

  testWidgets('settings button calls onToggleSettings', (tester) async {
    var toggled = 0;
    await _pumpControls(tester, onToggleSettings: () => toggled++);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();

    expect(toggled, 1);
  });
}
