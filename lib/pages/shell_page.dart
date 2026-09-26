import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/platform.dart';
import '../providers/navigation_provider.dart';
import 'detail_page.dart';
import 'downloads_page.dart';
import 'favorites_page.dart';
import 'home_page.dart';
import 'libraries_page.dart';
import 'library_page.dart';
import 'music_page.dart';
import 'search_page.dart';
import 'settings_page.dart';
import '../widgets/mini_player.dart';

class ShellPage extends ConsumerWidget {
  const ShellPage({super.key});

  static const _destinations =
      <ShellSection, ({IconData icon, IconData selected})>{
        ShellSection.home: (icon: Icons.home_outlined, selected: Icons.home),
        ShellSection.search: (icon: Icons.search, selected: Icons.search),
        ShellSection.favorites: (
          icon: Icons.favorite_outline,
          selected: Icons.favorite,
        ),
        ShellSection.downloads: (
          icon: Icons.download_outlined,
          selected: Icons.download,
        ),
        ShellSection.libraries: (
          icon: Icons.video_library_outlined,
          selected: Icons.video_library,
        ),
        ShellSection.settings: (
          icon: Icons.settings_outlined,
          selected: Icons.settings,
        ),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(shellNavProvider);
    final wide = isWideLayout(MediaQuery.of(context).size.width);

    final body = nav.detailItem != null
        ? DetailPage(
            key: ValueKey(nav.detailItem!.id),
            itemId: nav.detailItem!.id,
            item: nav.detailItem,
          )
        : _body(nav, wide);

    if (wide) {
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _Sidebar(nav: nav, destinations: _destinations),
                  VerticalDivider(
                    width: dim(1),
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      );
    }

    final order = _destinations.keys.toList();
    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: order.indexOf(nav.section),
            onDestinationSelected: (i) =>
                ref.read(shellNavProvider.notifier).select(order[i]),
            destinations: [
              for (final s in order)
                NavigationDestination(
                  icon: Icon(_destinations[s]!.icon),
                  selectedIcon: Icon(_destinations[s]!.selected),
                  label: s.label,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _body(ShellNav nav, bool wide) {
    switch (nav.section) {
      case ShellSection.home:
        return const HomePage();
      case ShellSection.search:
        return const SearchPage();
      case ShellSection.favorites:
        return const FavoritesPage();
      case ShellSection.downloads:
        return const DownloadsPage();
      case ShellSection.libraries:
        if (nav.libraryId != null) {
          if (nav.libraryCollectionType == 'music') {
            return MusicPage(
              libraryId: nav.libraryId!,
              title: nav.libraryName ?? 'Music',
              inShell: true,
            );
          }
          return LibraryPage(
            libraryId: nav.libraryId!,
            title: nav.libraryName ?? 'Library',
            inShell: true,
          );
        }
        return const LibrariesPage();
      case ShellSection.settings:
        return const SettingsPage();
    }
  }
}

class _Sidebar extends ConsumerWidget {
  final ShellNav nav;
  final Map<ShellSection, ({IconData icon, IconData selected})> destinations;

  const _Sidebar({required this.nav, required this.destinations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: dim(220),
      child: ListView(
        padding: EdgeInsets.all(Insets.sm),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              Insets.sm,
              Insets.md,
              Insets.sm,
              Insets.lg,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(dim(8)),
                  child: SvgPicture.asset(
                    'icon.svg',
                    width: dim(34),
                    height: dim(34),
                  ),
                ),
                SizedBox(width: Insets.sm),
                Text(
                  'Finar',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: scheme.primary),
                ),
              ],
            ),
          ),
          for (final s in destinations.keys) _item(context, ref, s),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, WidgetRef ref, ShellSection s) {
    final scheme = Theme.of(context).colorScheme;
    final selected = nav.section == s;
    final d = destinations[s]!;
    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dim(10)),
        ),
        selected: selected,
        selectedTileColor: scheme.primary.withValues(alpha: 0.15),
        leading: Icon(
          selected ? d.selected : d.icon,
          size: dim(22),
          color: selected
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.7),
        ),
        title: Text(
          s.label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? scheme.primary : null,
          ),
        ),
        onTap: () => ref.read(shellNavProvider.notifier).select(s),
      ),
    );
  }
}
