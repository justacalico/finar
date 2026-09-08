import 'package:finar/core/api/models/library.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/pages/home/widgets/home_library_list_card.dart';
import 'package:finar/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('LibraryListCard renders as a GlassContainer with library text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: LibraryListCard(
            library: const Library(
              id: '1',
              name: 'Movies',
              collectionType: 'movies',
              childCount: 8,
            ),
            icon: Icons.movie_outlined,
            typeLabel: 'Movies',
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GlassContainer), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('Movies · 8 items'), findsOneWidget);
  });

  testWidgets('LibraryListCard uses the theme primary color for the icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: LibraryListCard(
            library: const Library(
              id: '2',
              name: 'Music',
              collectionType: 'music',
              childCount: 120,
            ),
            icon: Icons.music_note_outlined,
            typeLabel: 'Music',
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.music_note_outlined));
    expect(icon.color, primary);
  });

  testWidgets('LibraryListCard uses the same primary color for every type', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Column(
            children: [
              LibraryListCard(
                library: const Library(
                  id: '1',
                  name: 'Movies',
                  collectionType: 'movies',
                  childCount: 8,
                ),
                icon: Icons.movie_outlined,
                typeLabel: 'Movies',
                onTap: () {},
              ),
              LibraryListCard(
                library: const Library(
                  id: '2',
                  name: 'Music',
                  collectionType: 'music',
                  childCount: 50,
                ),
                icon: Icons.music_note_outlined,
                typeLabel: 'Music',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final movieIcon = tester.widget<Icon>(find.byIcon(Icons.movie_outlined));
    final musicIcon = tester.widget<Icon>(
      find.byIcon(Icons.music_note_outlined),
    );
    expect(movieIcon.color, musicIcon.color);
    expect(movieIcon.color, primary);
  });

  testWidgets('LibraryListCard calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: LibraryListCard(
            library: const Library(
              id: '3',
              name: 'TV Shows',
              collectionType: 'tvshows',
              childCount: 12,
            ),
            icon: Icons.tv_outlined,
            typeLabel: 'TV Shows',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(LibraryListCard));
    expect(tapped, true);
  });
}
