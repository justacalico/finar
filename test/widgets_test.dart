import 'package:dio/dio.dart';
import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/api/models.dart';
import 'package:finar/core/storage/app_storage.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/app_image.dart';
import 'package:finar/widgets/async_view.dart';
import 'package:finar/widgets/detail_actions.dart';
import 'package:finar/widgets/media_card.dart';
import 'package:finar/widgets/page_header.dart';
import 'package:finar/widgets/seek_bar.dart';
import 'package:finar/widgets/settings_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> app(Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final storage = AppStorage(await SharedPreferences.getInstance());
  final client = JellyfinClient(dio: Dio(), deviceId: 't')
    ..setServerUrl('http://srv')
    ..setCredentials(accessToken: 't', userId: 'u');
  return ProviderScope(
    overrides: [
      appStorageProvider.overrideWithValue(storage),
      jellyfinClientProvider.overrideWithValue(client),
    ],
    child: MaterialApp(
      theme: AppTheme.build(
          Brightness.dark, kAccentOptions['System']!),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('MediaCard', () {
    const item = MediaItem(
      id: 'i1',
      name: 'The Movie',
      productionYear: 2021,
      userData: UserData(
          played: false,
          playbackPositionTicks: 300,
          isFavorite: false),
      runtimeTicks: 1000,
    );

    testWidgets('renders title, subtitle and progress', (t) async {
      await t.pumpWidget(await app(const MediaCard(item: item)));
      await t.pump();
      expect(find.text('The Movie'), findsOneWidget);
      expect(find.text('2021'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('watched badge shows for played items', (t) async {
      const played = MediaItem(
          id: 'i2', name: 'Seen', userData: UserData(played: true));
      await t.pumpWidget(
          await app(const MediaCard(item: played)));
      await t.pump();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('tap callback fires', (t) async {
      var tapped = false;
      await t.pumpWidget(await app(
          MediaCard(item: item, onTap: () => tapped = true)));
      await t.pump();
      await t.tap(find.byType(MediaCard));
      expect(tapped, isTrue);
    });
  });

  group('AppImage', () {
    testWidgets('empty url shows placeholder icon', (t) async {
      await t.pumpWidget(await app(const AppImage('')));
      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    });
  });

  group('SeekBar', () {
    testWidgets('shows position and remaining labels', (t) async {
      await t.pumpWidget(await app(SeekBar(
        position: const Duration(seconds: 90),
        duration: const Duration(minutes: 10),
        onSeek: (_) {},
      )));
      expect(find.text('1:30'), findsOneWidget);
      expect(find.text('-8:30'), findsOneWidget);
    });

    testWidgets('slider disabled without duration', (t) async {
      await t.pumpWidget(await app(SeekBar(
        position: Duration.zero,
        duration: Duration.zero,
        onSeek: (_) {},
      )));
      final slider = t.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNull);
    });
  });

  group('PageHeader', () {
    testWidgets('renders the title', (t) async {
      await t.pumpWidget(
          await app(const PageHeader(title: 'Downloads')));
      expect(find.text('Downloads'), findsOneWidget);
    });
  });

  group('Settings widgets', () {
    testWidgets('group renders title and children', (t) async {
      await t.pumpWidget(await app(const SettingsGroup(
        title: 'Playback',
        children: [SettingSwitch(title: 'Autoplay', value: true)],
      )));
      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Autoplay'), findsOneWidget);
    });

    testWidgets('switch toggles', (t) async {
      var value = false;
      await t.pumpWidget(await app(StatefulBuilder(
        builder: (context, setState) => SettingSwitch(
            title: 'Toggle',
            value: value,
            onChanged: (v) => setState(() => value = v)),
      )));
      await t.tap(find.byType(Switch));
      expect(value, isTrue);
    });

    testWidgets('dropdown shows current value', (t) async {
      await t.pumpWidget(await app(const SettingDropdown<String>(
        title: 'Theme',
        value: 'Dark',
        options: {'Dark': 'Dark', 'Light': 'Light'},
      )));
      expect(find.text('Dark'), findsOneWidget);
    });
  });

  group('DetailActions', () {
    const movie = MediaItem(
      id: 'm1',
      name: 'Film',
      kind: MediaKind.movie,
      runtimeTicks: 9000000000,
      userData: UserData(
          played: false,
          playbackPositionTicks: 4500000000,
          isFavorite: true),
    );

    testWidgets(
        'every action is inline, no overflow menu entry', (t) async {
      await t.pumpWidget(
          await app(const DetailActions(item: movie)));
      await t.pump();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline),
          findsOneWidget);
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('resume and play-from-start both offered', (t) async {
      var plays = 0;
      var restarts = 0;
      await t.pumpWidget(await app(DetailActions(
        item: movie,
        onPlay: () => plays++,
        onPlayFromStart: () => restarts++,
      )));
      await t.pump();
      await t.tap(find.textContaining('Resume'));
      await t.tap(find.text('Play from start'));
      expect(plays, 1);
      expect(restarts, 1);
    });
  });

  group('EmptyView / ErrorView', () {
    testWidgets('empty view shows icon and title', (t) async {
      await t.pumpWidget(await app(const EmptyView(
          icon: Icons.inbox, title: 'Nothing here')));
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('error view retries', (t) async {
      var retried = false;
      await t.pumpWidget(await app(ErrorView(
          message: 'Failed',
          onRetry: () => retried = true)));
      await t.tap(find.text('Try again'));
      expect(retried, isTrue);
    });
  });
}
