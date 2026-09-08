import 'package:flutter/material.dart';
import 'detail.dart';
import 'downloads.dart';
import 'home.dart';
import 'library/library_page.dart';
import 'player.dart';
import 'settings.dart';

/// Responsive wrappers that preserve route intent.
/// Each forwards to the unified page (home, detail, player, etc.) which uses
/// [AdaptiveLayout] internally for desktop vs mobile.
class AdaptiveHomePage extends StatelessWidget {
  final int mobileInitialIndex;

  const AdaptiveHomePage({super.key, this.mobileInitialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return HomePage(initialIndex: mobileInitialIndex);
  }
}

class AdaptiveDetailPage extends StatelessWidget {
  final String itemId;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const AdaptiveDetailPage({
    super.key,
    required this.itemId,
    this.initialSeasonId,
    this.initialEpisodeId,
  });

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      itemId: itemId,
      initialSeasonId: initialSeasonId,
      initialEpisodeId: initialEpisodeId,
    );
  }
}

class AdaptivePlayerPage extends StatelessWidget {
  const AdaptivePlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlayerPage();
  }
}

class AdaptiveLibraryPage extends StatelessWidget {
  final String libraryId;

  const AdaptiveLibraryPage({super.key, required this.libraryId});

  @override
  Widget build(BuildContext context) {
    return LibraryPage(libraryId: libraryId);
  }
}

class AdaptiveMusicLibraryPage extends StatelessWidget {
  final String libraryId;

  const AdaptiveMusicLibraryPage({super.key, required this.libraryId});

  @override
  Widget build(BuildContext context) {
    return LibraryPage(libraryId: libraryId);
  }
}

class AdaptiveDownloadsPage extends StatelessWidget {
  const AdaptiveDownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DownloadsPage();
  }
}

class AdaptiveSettingsPage extends StatelessWidget {
  const AdaptiveSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPage();
  }
}
