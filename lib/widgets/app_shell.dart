import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../core/models/models.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/library_providers.dart';
import '../core/storage/session_store.dart';
import '../providers/player_provider.dart';
import '../providers/session_provider.dart';
import 'media_image.dart';
import 'responsive.dart';

class NavTarget {
  const NavTarget(this.route, this.icon, this.iconSelected);

  final String route;
  final IconData icon;
  final IconData iconSelected;
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _mainRoutes = [
    '/home',
    '/libraries',
    '/search',
    '/favorites',
    '/downloads',
    '/settings',
  ];

  int _selectedIndex(String location) {
    for (var i = 0; i < _mainRoutes.length; i++) {
      if (location.startsWith(_mainRoutes[i])) return i;
    }
    if (location.startsWith('/library') || location.startsWith('/item')) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final location = GoRouterState.of(context).uri.toString();
    final selected = _selectedIndex(location);
    final targets = [
      NavTarget('/home', Icons.home_outlined, Icons.home),
      NavTarget('/libraries', Icons.video_library_outlined,
          Icons.video_library),
      NavTarget('/search', Icons.search_outlined, Icons.search),
      NavTarget('/favorites', Icons.favorite_outline, Icons.favorite),
      NavTarget('/downloads', Icons.download_outlined, Icons.download),
      NavTarget('/settings', Icons.settings_outlined, Icons.settings),
    ];
    final labels = [
      l10n.home,
      l10n.libraries,
      l10n.search,
      l10n.favorites,
      l10n.downloads,
      l10n.settings,
    ];

    final desktop = isDesktopLayout(context);

    final session = ref.watch(sessionProvider);
    final player = ref.watch(playerProvider);
    final libraries = ref.watch(librariesProvider).valueOrNull ?? [];

    final content = Row(
      children: [
        if (desktop)
          _Sidebar(
            targets: targets,
            labels: labels,
            selected: selected,
            libraries: libraries,
            session: session,
          ),
        if (desktop) const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              if (!desktop)
                _MobileBar(
                  title: _titleFor(location, labels),
                ),
              Expanded(child: child),
              if (player.item != null && player.item!.isAudio)
                const MiniPlayerBar(),
              if (!desktop)
                NavigationBar(
                  selectedIndex:
                      selected.clamp(0, targets.length - 1),
                  onDestinationSelected: (i) =>
                      context.go(targets[i].route),
                  destinations: [
                    for (var i = 0; i < targets.length; i++)
                      NavigationDestination(
                        icon: Icon(targets[i].icon),
                        selectedIcon: Icon(targets[i].iconSelected),
                        label: labels[i],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      body: content,
      drawer: desktop ? null : _NavDrawer(
          targets: targets,
          labels: labels,
          selected: selected,
          libraries: libraries,
          session: session),
    );
  }

  String _titleFor(String location, List<String> labels) {
    final index = _selectedIndex(location);
    if (index < labels.length && !location.startsWith('/item')) {
      return labels[index];
    }
    return '';
  }
}

class _MobileBar extends StatelessWidget implements PreferredSizeWidget {
  const _MobileBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: false,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({
    required this.targets,
    required this.labels,
    required this.selected,
    required this.libraries,
    required this.session,
    this.width = 244,
  });

  final List<NavTarget> targets;
  final List<String> labels;
  final int selected;
  final List<BaseItem> libraries;
  final Session? session;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final client = ref.watch(jellyfinClientProvider);
    return SizedBox(
      width: width,
      child: Material(
        color: scheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: SvgPicture.asset('icon.svg',
                          fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(l10n.appTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (var i = 0; i < targets.length; i++)
                    _NavRow(
                      icon: i == selected
                          ? targets[i].iconSelected
                          : targets[i].icon,
                      label: labels[i],
                      selected: i == selected,
                      onTap: () => context.go(targets[i].route),
                    ),
                  if (libraries.isNotEmpty) ...[
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(14, 18, 14, 4),
                      child: Text(l10n.libraries.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  letterSpacing: 1)),
                    ),
                    for (final lib in libraries)
                      _NavRow(
                        icon: _libraryIcon(lib.collectionType),
                        label: lib.name,
                        selected: GoRouterState.of(context)
                                .uri
                                .toString() ==
                            '/library/${lib.id}',
                        onTap: () =>
                            context.go('/library/${lib.id}'),
                      ),
                  ],
                ],
              ),
            ),
            if (session != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.go('/profiles'),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: MediaImage(
                              url: client?.userImageUrl(
                                  session!.user,
                                  maxWidth: 68),
                              icon: Icons.person_outline,
                              borderRadius: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(session!.user.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          fontWeight:
                                              FontWeight.w600)),
                              Text(session!.serverName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: scheme
                                              .onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _libraryIcon(String? collectionType) =>
      switch (collectionType) {
        'movies' => Icons.movie_outlined,
        'tvshows' => Icons.tv_outlined,
        'music' => Icons.music_note_outlined,
        'photos' => Icons.photo_outlined,
        'books' => Icons.book_outlined,
        'livetv' => Icons.live_tv_outlined,
        _ => Icons.folder_outlined,
      };
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected
            ? scheme.secondaryContainer
            : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          leading: Icon(icon,
              size: 20,
              color: selected
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant),
          title: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: selected
                      ? scheme.onSecondaryContainer
                      : scheme.onSurface,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400)),
          shape: const StadiumBorder(),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _NavDrawer extends StatelessWidget {
  const _NavDrawer({
    required this.targets,
    required this.labels,
    required this.selected,
    required this.libraries,
    required this.session,
  });

  final List<NavTarget> targets;
  final List<String> labels;
  final int selected;
  final List<BaseItem> libraries;
  final Session? session;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: _Sidebar(
          width: double.infinity,
          targets: targets,
          labels: labels,
          selected: selected,
          libraries: libraries,
          session: session,
        ),
      ),
    );
  }
}

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final item = player.item;
    if (item == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final client = ref.watch(jellyfinClientProvider);
    return Material(
      color: scheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => context.push('/play'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: MediaImage(
                  url: client?.primaryImageUrl(item, maxWidth: 80),
                  icon: Icons.music_note,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(item.albumArtist ?? item.seriesName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                    player.playing ? Icons.pause : Icons.play_arrow),
                onPressed: () =>
                    ref.read(playerProvider.notifier).toggle(),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: player.nextItem == null
                    ? null
                    : () => ref.read(playerProvider.notifier).next(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
