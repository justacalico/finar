import 'package:finar/core/api/jellyfin_api.dart';
import 'package:finar/core/api/media_service.dart';
import 'package:finar/core/api/models/library.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/pages/home/widgets/home_library_browser.dart';
import 'package:finar/pages/home/widgets/home_library_list_card.dart';
import 'package:finar/providers/library_provider.dart';
import 'package:finar/widgets/glass_container.dart';
import 'package:finar/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMediaService extends MediaService {
  _FakeMediaService() : super(JellyfinApi());
}

Widget _pump(ProviderContainer container, Widget child) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  const primary = Color(0xFFFF6B9D);

  setUp(() {
    AppColors.set(
      brightness: Brightness.light,
      oled: false,
      themeColor: primary,
      accentColor: primary,
      useSystemAccent: false,
    );
  });

  testWidgets('LibraryBrowser shows themed header and glass cards', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        libraryProvider.overrideWith(
          (ref) => LibraryNotifier(_FakeMediaService(), JellyfinApi()),
        ),
      ],
    );
    container.read(libraryProvider.notifier).state = const LibraryState(
      libraries: [
        Library(
          id: '1',
          name: 'Movies',
          collectionType: 'movies',
          childCount: 8,
        ),
      ],
    );

    await tester.pumpWidget(
      _pump(container, const Scaffold(body: LibraryBrowser())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Movies · 8 items'), findsOneWidget);
    expect(find.byType(LibraryListCard), findsOneWidget);
    expect(find.byType(PageHeader), findsOneWidget);
    expect(find.byType(GlassContainer), findsWidgets);

    final cardIcon = tester.widget<Icon>(find.byIcon(Icons.movie_outlined));
    expect(cardIcon.color, primary);
  });
}
