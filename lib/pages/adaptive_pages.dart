import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'desktop/desktop_detail.dart';
import 'desktop/desktop_downloads.dart';
import 'desktop/desktop_home.dart';
import 'desktop/desktop_library.dart';
import 'desktop/desktop_music_library.dart';
import 'desktop/desktop_player.dart';
import 'desktop/desktop_settings.dart';
import 'mobile/mobile_detail.dart';
import 'mobile/mobile_home.dart';
import 'mobile/mobile_library.dart';
import 'mobile/mobile_music_library.dart';
import 'mobile/mobile_player.dart';
import 'mobile/mobile_settings.dart';

/// Responsive wrappers that preserve route intent while swapping UI by size.
///
/// This allows a route like "detail(itemId)" to stay on the same logical page
/// when crossing desktop/mobile breakpoints.
class AdaptiveHomePage extends StatelessWidget {
  final int mobileInitialIndex;

  const AdaptiveHomePage({super.key, this.mobileInitialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return _AdaptivePage(
      desktopBuilder: () => const DesktopHome(),
      mobileBuilder: () => MobileHome(initialIndex: mobileInitialIndex),
    );
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
    return _AdaptivePage(
      desktopBuilder: () => DesktopDetail(
        itemId: itemId,
        initialSeasonId: initialSeasonId,
        initialEpisodeId: initialEpisodeId,
      ),
      mobileBuilder: () => MobileDetail(
        itemId: itemId,
        initialSeasonId: initialSeasonId,
        initialEpisodeId: initialEpisodeId,
      ),
    );
  }
}

class AdaptivePlayerPage extends StatelessWidget {
  const AdaptivePlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdaptivePage(
      desktopBuilder: () => const DesktopPlayer(),
      mobileBuilder: () => const MobilePlayer(),
    );
  }
}

class AdaptiveLibraryPage extends StatelessWidget {
  final String libraryId;

  const AdaptiveLibraryPage({super.key, required this.libraryId});

  @override
  Widget build(BuildContext context) {
    return _AdaptivePage(
      desktopBuilder: () => DesktopLibrary(libraryId: libraryId),
      mobileBuilder: () => MobileLibrary(libraryId: libraryId),
    );
  }
}

class AdaptiveMusicLibraryPage extends StatelessWidget {
  final String libraryId;

  const AdaptiveMusicLibraryPage({super.key, required this.libraryId});

  @override
  Widget build(BuildContext context) {
    return _AdaptivePage(
      desktopBuilder: () => DesktopMusicLibrary(libraryId: libraryId),
      mobileBuilder: () => MobileMusicLibrary(libraryId: libraryId),
    );
  }
}

class AdaptiveDownloadsPage extends StatelessWidget {
  const AdaptiveDownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdaptivePage(
      desktopBuilder: () => const DesktopDownloads(),
      mobileBuilder: () => const MobileHome(initialIndex: 3),
    );
  }
}

class AdaptiveSettingsPage extends StatelessWidget {
  const AdaptiveSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdaptivePage(
      desktopBuilder: () => const DesktopSettings(),
      mobileBuilder: () => const MobileSettings(),
    );
  }
}

class _AdaptivePage extends ConsumerWidget {
  static const double mobileMaxWidth = 600;

  final Widget Function() desktopBuilder;
  final Widget Function() mobileBuilder;

  const _AdaptivePage({
    required this.desktopBuilder,
    required this.mobileBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forcedUiMode = ref.watch(forcedUiModeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useMobile = switch (forcedUiMode) {
          UiMode.mobile => true,
          UiMode.desktop => false,
          UiMode.auto => constraints.maxWidth <= mobileMaxWidth,
        };

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<String>(useMobile ? 'mobile' : 'desktop'),
            child: useMobile ? mobileBuilder() : desktopBuilder(),
          ),
        );
      },
    );
  }
}
