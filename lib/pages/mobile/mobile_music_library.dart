import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'mobile_detail.dart';

class MobileMusicLibrary extends ConsumerStatefulWidget {
  final String libraryId;

  const MobileMusicLibrary({super.key, required this.libraryId});

  @override
  ConsumerState<MobileMusicLibrary> createState() => _MobileMusicLibraryState();
}

class _MobileMusicLibraryState extends ConsumerState<MobileMusicLibrary>
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

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Colors.transparent,
            flexibleSpace: BlurBackdrop(
              blur: AppTheme.blurLight,
              child: const SizedBox.expand(),
            ),
            title: Text('Music', style: AppTextStyles.headlineMedium),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearch(context),
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () => _showSortOptions(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
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
          ),
        ],
        body: TabBarView(
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
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.albums.length + (state.albumsHasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.albums.length) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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
                      child: Image.network(
                        album.getPrimaryImageUrl(serverUrl, width: 300),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.surface,
                          child: const Icon(
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
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: (index % 10) * 50))
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
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
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.tracks.length + (state.tracksHasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.tracks.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
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
                      child: Image.network(
                        track.getPrimaryImageUrl(serverUrl, width: 100),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
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
                  Text(
                    durationStr,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Play button
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline),
                    color: AppColors.primary,
                    onPressed: () => _playTrack(track),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: (index % 15) * 30))
        .slideX(begin: 0.05, end: 0);
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
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.artists.length + (state.artistsHasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.artists.length) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        artist.getPrimaryImageUrl(serverUrl, width: 200),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.person,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
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
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: (index % 10) * 50))
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
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
      itemBuilder: (context, index) {
        return ShimmerLoading(borderRadius: isCircle ? 100 : AppTheme.radiusMd);
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
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
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
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
      MaterialPageRoute(builder: (_) => MobileDetail(itemId: itemId)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play album: $e')),
        );
      }
    }
  }
}
