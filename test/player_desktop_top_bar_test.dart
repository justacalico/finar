import 'package:finar/core/api/jellyfin_api.dart';
import 'package:finar/core/api/media_service.dart';
import 'package:finar/core/services/download_service.dart';
import 'package:finar/pages/player/widgets/player_desktop_top_bar.dart';
import 'package:finar/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeJellyfinApi extends JellyfinApi {}

class _FakeMediaService extends MediaService {
  _FakeMediaService() : super(JellyfinApi());
}

Future<void> _pumpTopBar(
  WidgetTester tester, {
  required VoidCallback onBack,
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
              PlayerDesktopTopBar(controlsVisible: true, onBack: onBack),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows back button and no fullscreen button', (tester) async {
    await _pumpTopBar(tester, onBack: () {});

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.fullscreen), findsNothing);
    expect(find.byIcon(Icons.fullscreen_exit), findsNothing);
  });

  testWidgets('back button calls onBack', (tester) async {
    var backs = 0;
    await _pumpTopBar(tester, onBack: () => backs++);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    expect(backs, 1);
  });
}
