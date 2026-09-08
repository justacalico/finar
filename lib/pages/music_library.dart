import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/api/models/media_item.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';
import 'adaptive_pages.dart';

class MusicLibraryDesktop extends ConsumerStatefulWidget {
  final String libraryId;
  final String libraryName;

  const MusicLibraryDesktop({
    super.key,
    required this.libraryId,
    required this.libraryName,
  });

  @override
  ConsumerState<MusicLibraryDesktop> createState() =>
      MusicLibraryDesktopState();
}

class MusicLibraryDesktopState extends ConsumerState<MusicLibraryDesktop>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = MusicTab.values[_tabController.index];
    ref.read(musicLibraryProvider(widget.libraryId).notifier).setTab(tab);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      ref.read(musicLibraryProvider(widget.libraryId).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(musicLibraryProvider(widget.libraryId));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Column(
      children: [
        // Header
        PageHeader(
          title: widget.libraryName,
          trailing: _buildHeaderControls(musicState),
        ),

        // Tab Bar
        _buildTabBar(musicState),

        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAlbumsGrid(musicState, serverUrl),
              _buildTracksList(musicState, serverUrl),
              _buildArtistsGrid(musicState, serverUrl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderControls(MusicLibraryState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search field
        SizedBox(
          width: 240,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search music...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              ref
                  .read(musicLibraryProvider(widget.libraryId).notifier)
                  .setSearch(value);
            },
          ),
        ),

        const SizedBox(width: 16),

        // Sort dropdown
        _buildSortDropdown(state),

        const SizedBox(width: 16),

        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref
                .read(musicLibraryProvider(widget.libraryId).notifier)
                .refreshAll();
          },
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildTabBar(MusicLibraryState state) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.03,
      borderRadius: 0,
      showBorder: false,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.album, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Albums (${state.albumsTotal})',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_note, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tracks (${state.tracksTotal})',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Artists (${state.artistsTotal})',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(MusicLibraryState state) {
    return PopupMenuButton<String>(
      initialValue: state.sortBy,
      onSelected: (value) {
        ref
            .read(musicLibraryProvider(widget.libraryId).notifier)
            .setSorting(value, state.sortOrder);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'SortName', child: Text('Name')),
        const PopupMenuItem(value: 'DateCreated', child: Text('Date Added')),
        const PopupMenuItem(value: 'PremiereDate', child: Text('Release Date')),
        const PopupMenuItem(value: 'Random', child: Text('Random')),
      ],
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: AppTheme.radiusSm,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _getSortLabel(state.sortBy),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'SortName':
        return 'Name';
      case 'DateCreated':
        return 'Date Added';
      case 'PremiereDate':
        return 'Release Date';
      case 'Random':
        return 'Random';
      default:
        return 'Sort';
    }
  }

  Widget _buildAlbumsGrid(MusicLibraryState state, String serverUrl) {
    if (state.albums.isEmpty && state.albumsLoading) {
      return _buildLoadingGrid();
    }

    if (state.albums.isEmpty) {
      return _buildEmptyState('No albums found', Icons.album);
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.albums.length + (state.albumsHasMore ? 1 : 0),
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        if (index >= state.albums.length) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }
        return _buildAlbumCard(state.albums[index], serverUrl, index);
      },
    );
  }

  Widget _buildAlbumCard(MediaItem album, String serverUrl, int index) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigateToDetail(album.id),
        child: GlassContainer(
          borderRadius: AppTheme.radiusMd,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album art with hover effect
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: album.getPrimaryImageUrl(
                          serverUrl,
                          width: 400,
                        ),
                        memCacheWidth: 440,
                        memCacheHeight: 440,
                        fadeInDuration: const Duration(milliseconds: 150),
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: AppColors.surface),
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.surface,
                          child: Icon(
                            Icons.album,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(onTap: () => _playAlbum(album)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Album name
              Text(
                album.name,
                style: AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Artist name
              if (album.albumArtist != null ||
                  album.artists?.isNotEmpty == true)
                Text(
                  album.albumArtist ?? album.artists?.first ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              // Year
              if (album.productionYear != null)
                Text(
                  album.productionYear.toString(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTracksList(MusicLibraryState state, String serverUrl) {
    if (state.tracks.isEmpty && state.tracksLoading) {
      return _buildLoadingList();
    }

    if (state.tracks.isEmpty) {
      return _buildEmptyState('No tracks found', Icons.music_note);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: state.tracks.length + (state.tracksHasMore ? 1 : 0),
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        if (index >= state.tracks.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
        return _buildTrackItem(state.tracks[index], serverUrl, index);
      },
    );
  }

  Widget _buildTrackItem(MediaItem track, String serverUrl, int index) {
    final duration = track.runtimeTicks != null
        ? Duration(microseconds: track.runtimeTicks! ~/ 10)
        : null;
    final durationStr = duration != null
        ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        borderRadius: AppTheme.radiusMd,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _playTrack(track),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            hoverColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Track number
                  SizedBox(
                    width: 40,
                    child: Text(
                      track.indexNumber?.toString() ?? '#',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Album art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CachedNetworkImage(
                        imageUrl: track.getPrimaryImageUrl(
                          serverUrl,
                          width: 100,
                        ),
                        memCacheWidth: 96,
                        memCacheHeight: 96,
                        fadeInDuration: const Duration(milliseconds: 150),
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: AppColors.surface),
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.surface,
                          child: Icon(
                            Icons.music_note,
                            size: 24,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Track info
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (track.artists?.isNotEmpty == true)
                          Text(
                            track.artists!.join(', '),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Album
                  if (track.album != null)
                    Expanded(
                      flex: 2,
                      child: Text(
                        track.album!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Duration
                  SizedBox(
                    width: 60,
                    child: Text(
                      durationStr,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Actions
                  IconButton(
                    icon: Icon(
                      track.isFavorite == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                    ),
                    color: track.isFavorite == true
                        ? Colors.redAccent
                        : AppColors.textSecondary,
                    onPressed: () => _toggleTrackFavorite(track),
                    tooltip: track.isFavorite == true
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: () => _showTrackOptions(track),
                    tooltip: 'More options',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtistsGrid(MusicLibraryState state, String serverUrl) {
    if (state.artists.isEmpty && state.artistsLoading) {
      return _buildLoadingGrid(isCircle: true);
    }

    if (state.artists.isEmpty) {
      return _buildEmptyState('No artists found', Icons.person);
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.85,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: state.artists.length + (state.artistsHasMore ? 1 : 0),
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        if (index >= state.artists.length) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }
        return _buildArtistCard(state.artists[index], serverUrl, index);
      },
    );
  }

  Widget _buildArtistCard(MediaItem artist, String serverUrl, int index) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _navigateToDetail(artist.id),
        child: Column(
          children: [
            // Artist image (circular)
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipOval(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: artist.getPrimaryImageUrl(
                          serverUrl,
                          width: 300,
                        ),
                        memCacheWidth: 360,
                        memCacheHeight: 360,
                        fadeInDuration: const Duration(milliseconds: 150),
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: AppColors.surface),
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.surface,
                          child: Icon(
                            Icons.person,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      // Hover overlay
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _navigateToDetail(artist.id),
                          customBorder: const CircleBorder(),
                          hoverColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Artist name
            Text(
              artist.name,
              style: AppTextStyles.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid({bool isCircle = false}) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isCircle ? 180 : 220,
        childAspectRatio: isCircle ? 0.85 : 0.8,
        crossAxisSpacing: isCircle ? 24 : 16,
        mainAxisSpacing: isCircle ? 24 : 16,
      ),
      itemCount: 12,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        return ShimmerLoading(borderRadius: isCircle ? 100 : AppTheme.radiusMd);
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 15,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerLoading(height: 72, borderRadius: AppTheme.radiusMd),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.textSecondary),
          const SizedBox(height: 24),
          Text(
            message,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTrackFavorite(MediaItem track) async {
    try {
      await ref
          .read(mediaActionsProvider)
          .toggleFavorite(track.id, !(track.isFavorite == true));
      ref.invalidate(musicLibraryProvider(widget.libraryId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              track.isFavorite == true
                  ? 'Removed from favorites'
                  : 'Added to favorites',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showTrackOptions(MediaItem track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        blur: AppTheme.blurHeavy,
        opacity: 0.1,
        borderRadius: AppTheme.radiusXl,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              tileColor: Colors.transparent,
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                _playTrack(track);
              },
            ),
            ListTile(
              tileColor: Colors.transparent,
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to Queue'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              tileColor: Colors.transparent,
              leading: const Icon(Icons.album),
              title: const Text('Go to Album'),
              onTap: () {
                Navigator.pop(context);
                if (track.albumId != null) {
                  _navigateToDetail(track.albumId!);
                }
              },
            ),
            ListTile(
              tileColor: Colors.transparent,
              leading: Icon(
                track.isFavorite == true
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
              title: Text(
                track.isFavorite == true
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleTrackFavorite(track);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(String itemId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdaptiveDetailPage(itemId: itemId)),
    );
  }

  void _playTrack(MediaItem track) {
    ref.read(playerProvider.notifier).play(track);
  }

  Future<void> _playAlbum(MediaItem album) async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final tracks = await mediaService.getAlbumTracks(album.id);
      if (tracks.isNotEmpty) {
        ref.read(playerProvider.notifier).playPlaylist(tracks, 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play album: $e')));
      }
    }
  }
}

class MusicLibraryMobile extends ConsumerStatefulWidget {
  final String libraryId;
  final String libraryName;
  final VoidCallback? onBack;

  const MusicLibraryMobile({
    super.key,
    required this.libraryId,
    required this.libraryName,
    this.onBack,
  });

  @override
  ConsumerState<MusicLibraryMobile> createState() => MusicLibraryMobileState();
}

class MusicLibraryMobileState extends ConsumerState<MusicLibraryMobile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = MusicTab.values[_tabController.index];
    ref.read(musicLibraryProvider(widget.libraryId).notifier).setTab(tab);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(musicLibraryProvider(widget.libraryId).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(musicLibraryProvider(widget.libraryId));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Column(
      children: [
        PageHeader(
          title: widget.libraryName,
          onBack: widget.onBack,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearch(context),
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () => _showSortOptions(context),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(
              icon: const Icon(Icons.album),
              text: 'Albums (${musicState.albumsTotal})',
            ),
            Tab(
              icon: const Icon(Icons.music_note),
              text: 'Tracks (${musicState.tracksTotal})',
            ),
            Tab(
              icon: const Icon(Icons.person),
              text: 'Artists (${musicState.artistsTotal})',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Albums Tab
              _buildAlbumsGrid(musicState, serverUrl),
              // Tracks Tab
              _buildTracksList(musicState, serverUrl),
              // Artists Tab
              _buildArtistsGrid(musicState, serverUrl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumsGrid(MusicLibraryState state, String serverUrl) {
    if (state.albums.isEmpty && state.albumsLoading) {
      return _buildLoadingGrid();
    }

    if (state.albums.isEmpty) {
      return _buildEmptyState('No albums found', Icons.album);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref
            .read(musicLibraryProvider(widget.libraryId).notifier)
            .setTab(MusicTab.albums);
        await ref
            .read(musicLibraryProvider(widget.libraryId).notifier)
            .refresh();
      },
      color: Theme.of(context).colorScheme.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.albums.length + (state.albumsHasMore ? 1 : 0),
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
        cacheExtent: 500,
        itemBuilder: (context, index) {
          if (index >= state.albums.length) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }
          return _buildAlbumCard(state.albums[index], serverUrl, index);
        },
      ),
    );
  }

  Widget _buildAlbumCard(MediaItem album, String serverUrl, int index) {
    return GestureDetector(
      onTap: () => _playAlbum(album),
      onLongPress: () => _navigateToDetail(album.id),
      child: GlassContainer(
        borderRadius: AppTheme.radiusMd,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: album.getPrimaryImageUrl(serverUrl, width: 300),
                    memCacheWidth: 360,
                    memCacheHeight: 360,
                    fadeInDuration: const Duration(milliseconds: 150),
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.surface),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.surface,
                      child: Icon(
                        Icons.album,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Album name
            Text(
              album.name,
              style: AppTextStyles.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Artist name
            if (album.albumArtist != null || album.artists?.isNotEmpty == true)
              Text(
                album.albumArtist ?? album.artists?.first ?? '',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // Year
            if (album.productionYear != null)
              Text(
                album.productionYear.toString(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksList(MusicLibraryState state, String serverUrl) {
    if (state.tracks.isEmpty && state.tracksLoading) {
      return _buildLoadingList();
    }

    if (state.tracks.isEmpty) {
      return _buildEmptyState('No tracks found', Icons.music_note);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref
            .read(musicLibraryProvider(widget.libraryId).notifier)
            .setTab(MusicTab.tracks);
        await ref
            .read(musicLibraryProvider(widget.libraryId).notifier)
            .refresh();
      },
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.tracks.length + (state.tracksHasMore ? 1 : 0),
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
        cacheExtent: 500,
        itemBuilder: (context, index) {
          if (index >= state.tracks.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }
          return _buildTrackItem(state.tracks[index], serverUrl, index);
        },
      ),
    );
  }

  Widget _buildTrackItem(MediaItem track, String serverUrl, int index) {
    final duration = track.runtimeTicks != null
        ? Duration(microseconds: track.runtimeTicks! ~/ 10)
        : null;
    final durationStr = duration != null
        ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        borderRadius: AppTheme.radiusMd,
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: () => _playTrack(track),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Row(
            children: [
              // Track number or album art
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CachedNetworkImage(
                    imageUrl: track.getPrimaryImageUrl(serverUrl, width: 100),
                    memCacheWidth: 96,
                    memCacheHeight: 96,
                    fadeInDuration: const Duration(milliseconds: 150),
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.surface),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.surface,
                      child: Center(
                        child: Text(
                          track.indexNumber?.toString() ?? '#',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (track.artists?.isNotEmpty == true)
                          track.artists!.first,
                        if (track.album != null) track.album,
                      ].join(' • '),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Duration
              SizedBox(
                width: 50,
                child: Text(
                  durationStr,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Play button
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _playTrack(track),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistsGrid(MusicLibraryState state, String serverUrl) {
    if (state.artists.isEmpty && state.artistsLoading) {
      return _buildLoadingGrid(isCircle: true);
    }

    if (state.artists.isEmpty) {
      return _buildEmptyState('No artists found', Icons.person);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref
            .read(musicLibraryProvider(widget.libraryId).notifier)
            .setTab(MusicTab.artists);
        await ref
            .read(musicLibraryProvider(widget.libraryId).notifier)
            .refresh();
      },
      color: Theme.of(context).colorScheme.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.artists.length + (state.artistsHasMore ? 1 : 0),
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: false,
        cacheExtent: 500,
        itemBuilder: (context, index) {
          if (index >= state.artists.length) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }
          return _buildArtistCard(state.artists[index], serverUrl, index);
        },
      ),
    );
  }

  Widget _buildArtistCard(MediaItem artist, String serverUrl, int index) {
    return GestureDetector(
      onTap: () => _navigateToDetail(artist.id),
      child: Column(
        children: [
          // Artist image (circular)
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: artist.getPrimaryImageUrl(serverUrl, width: 200),
                  memCacheWidth: 240,
                  memCacheHeight: 240,
                  fadeInDuration: const Duration(milliseconds: 150),
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.surface),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.surface,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Artist name
          Text(
            artist.name,
            style: AppTextStyles.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid({bool isCircle = false}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isCircle ? 3 : 2,
        childAspectRatio: isCircle ? 0.8 : 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        return ShimmerLoading(borderRadius: isCircle ? 100 : AppTheme.radiusMd);
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerLoading(height: 72, borderRadius: AppTheme.radiusMd),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GlassContainer(
          blur: AppTheme.blurHeavy,
          opacity: 0.1,
          borderRadius: AppTheme.radiusXl,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search music...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  ref
                      .read(musicLibraryProvider(widget.libraryId).notifier)
                      .setSearch(value);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    final state = ref.read(musicLibraryProvider(widget.libraryId));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        blur: AppTheme.blurHeavy,
        opacity: 0.1,
        borderRadius: AppTheme.radiusXl,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Sort By', style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            _buildSortOption('Name', 'SortName', state.sortBy),
            _buildSortOption('Date Added', 'DateCreated', state.sortBy),
            _buildSortOption('Release Date', 'PremiereDate', state.sortBy),
            _buildSortOption('Random', 'Random', state.sortBy),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, String currentSort) {
    final isSelected = currentSort == value;
    return ListTile(
      tileColor: Colors.transparent,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        ref
            .read(musicLibraryProvider(widget.libraryId).notifier)
            .setSorting(value, 'Ascending');
        Navigator.pop(context);
      },
    );
  }

  void _navigateToDetail(String itemId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdaptiveDetailPage(itemId: itemId)),
    );
  }

  void _playTrack(MediaItem track) {
    ref.read(playerProvider.notifier).play(track);
  }

  Future<void> _playAlbum(MediaItem album) async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final tracks = await mediaService.getAlbumTracks(album.id);
      if (tracks.isNotEmpty) {
        ref.read(playerProvider.notifier).playPlaylist(tracks, 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play album: $e')));
      }
    }
  }
}
