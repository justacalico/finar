import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'tv_detail.dart';

class TvMusicLibrary extends ConsumerStatefulWidget {
  final String libraryId;

  const TvMusicLibrary({super.key, required this.libraryId});

  @override
  ConsumerState<TvMusicLibrary> createState() => _TvMusicLibraryState();
}

class _TvMusicLibraryState extends ConsumerState<TvMusicLibrary>
    with SingleTickerProviderStateMixin {
  final FocusNode _mainFocusNode = FocusNode();
  late TabController _tabController;

  int _selectedIndex = 0;
  int _selectedTabIndex = 0;

  // Color extraction for dynamic background
  Color _dominantColor = AppColors.background;
  Color _accentColor = AppColors.primary;
  String? _lastColorExtractedItemId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainFocusNode.requestFocus();
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedTabIndex = _tabController.index;
      _selectedIndex = 0;
    });
    final tab = MusicTab.values[_tabController.index];
    ref.read(musicLibraryProvider(widget.libraryId).notifier).setTab(tab);
  }

  @override
  void dispose() {
    _mainFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event, MusicLibraryState state) {
    if (event is! KeyDownEvent) return;

    final items = state.currentItems;
    final columns = _getColumnsForTab();

    setState(() {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          if (_selectedIndex > 0) {
            _selectedIndex--;
          } else {
            // Switch to previous tab
            if (_selectedTabIndex > 0) {
              _tabController.animateTo(_selectedTabIndex - 1);
            }
          }
          break;
        case LogicalKeyboardKey.arrowRight:
          if (_selectedIndex < items.length - 1) {
            _selectedIndex++;
          } else {
            // Switch to next tab
            if (_selectedTabIndex < 2) {
              _tabController.animateTo(_selectedTabIndex + 1);
            }
          }
          break;
        case LogicalKeyboardKey.arrowUp:
          if (_selectedIndex >= columns) {
            _selectedIndex -= columns;
          }
          break;
        case LogicalKeyboardKey.arrowDown:
          if (_selectedIndex + columns < items.length) {
            _selectedIndex += columns;
          } else {
            // Load more if at the end
            ref
                .read(musicLibraryProvider(widget.libraryId).notifier)
                .loadMore();
          }
          break;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
          if (items.isNotEmpty && _selectedIndex < items.length) {
            _onItemSelected(items[_selectedIndex]);
          }
          break;
        case LogicalKeyboardKey.tab:
          // Cycle through tabs
          _tabController.animateTo((_selectedTabIndex + 1) % 3);
          break;
      }
    });
  }

  int _getColumnsForTab() {
    switch (_selectedTabIndex) {
      case 0: // Albums
        return 5;
      case 1: // Tracks (list view, 1 column)
        return 1;
      case 2: // Artists
        return 6;
      default:
        return 5;
    }
  }

  void _onItemSelected(MediaItem item) {
    if (_selectedTabIndex == 1) {
      // Track - play it
      ref.read(playerProvider.notifier).play(item);
    } else {
      // Album or Artist - navigate to detail
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TvDetail(itemId: item.id)),
      );
    }
  }

  Future<void> _extractColors(MediaItem? item, String serverUrl) async {
    if (item == null || item.id == _lastColorExtractedItemId) return;
    _lastColorExtractedItemId = item.id;

    try {
      final imageUrl = item.getPrimaryImageUrl(serverUrl, width: 100);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100),
        maximumColorCount: 16,
      );

      if (mounted) {
        setState(() {
          _dominantColor =
              paletteGenerator.dominantColor?.color ?? AppColors.background;
          _accentColor =
              paletteGenerator.vibrantColor?.color ??
              paletteGenerator.mutedColor?.color ??
              AppColors.primary;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dominantColor = AppColors.background;
          _accentColor = AppColors.primary;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicState = ref.watch(musicLibraryProvider(widget.libraryId));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    final items = musicState.currentItems;
    MediaItem? selectedItem;
    if (_selectedIndex >= 0 && _selectedIndex < items.length) {
      selectedItem = items[_selectedIndex];
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _mainFocusNode,
        onKeyEvent: (event) => _handleKeyEvent(event, musicState),
        child: Stack(
          children: [
            // Dynamic background
            if (selectedItem != null) _buildBackground(selectedItem, serverUrl),

            // Content
            Column(
              children: [
                // Header with tabs
                _buildHeader(musicState),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildAlbumsGrid(musicState, serverUrl),
                      _buildTracksList(musicState, serverUrl),
                      _buildArtistsGrid(musicState, serverUrl),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(MediaItem item, String serverUrl) {
    _extractColors(item, serverUrl);

    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _dominantColor.withValues(alpha: 0.6),
              _accentColor.withValues(alpha: 0.4),
              _dominantColor.withValues(alpha: 0.5),
              AppColors.background.withValues(alpha: 0.9),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MusicLibraryState state) {
    return GlassContainer(
      blur: AppTheme.blurMedium,
      opacity: 0.1,
      borderRadius: 0,
      showBorder: false,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      child: Column(
        children: [
          // Title row
          Row(
            children: [
              Icon(Icons.library_music, color: AppColors.primary, size: 36),
              const SizedBox(width: 16),
              Text('Music Library', style: AppTextStyles.headlineLarge),
              const Spacer(),
              // Stats
              _buildStatChip(Icons.album, '${state.albumsTotal}', 'Albums'),
              const SizedBox(width: 24),
              _buildStatChip(
                Icons.music_note,
                '${state.tracksTotal}',
                'Tracks',
              ),
              const SizedBox(width: 24),
              _buildStatChip(Icons.person, '${state.artistsTotal}', 'Artists'),
            ],
          ),
          const SizedBox(height: 16),
          // Tab bar
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 4,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.titleMedium,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.album, size: 24),
                    const SizedBox(width: 8),
                    const Text('Albums'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.music_note, size: 24),
                    const SizedBox(width: 8),
                    const Text('Tracks'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 24),
                    const SizedBox(width: 8),
                    const Text('Artists'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
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

    return GridView.builder(
      padding: const EdgeInsets.all(48),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.8,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: state.albums.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedTabIndex == 0 && _selectedIndex == index;
        return _buildAlbumCard(
          state.albums[index],
          serverUrl,
          index,
          isSelected,
        );
      },
    );
  }

  Widget _buildAlbumCard(
    MediaItem album,
    String serverUrl,
    int index,
    bool isSelected,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(isSelected ? 1.08 : 1.0),
      child: GlassContainer(
        borderRadius: AppTheme.radiusMd,
        padding: const EdgeInsets.all(16),
        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album art
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      album.getPrimaryImageUrl(serverUrl, width: 400),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.album,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.shadowGlow(AppColors.primary),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 150.ms),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Album name
            Text(
              album.name,
              style: AppTextStyles.titleMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Artist name
            if (album.albumArtist != null || album.artists?.isNotEmpty == true)
              Text(
                album.albumArtist ?? album.artists?.first ?? '',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      itemCount: state.tracks.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedTabIndex == 1 && _selectedIndex == index;
        return _buildTrackItem(
          state.tracks[index],
          serverUrl,
          index,
          isSelected,
        );
      },
    );
  }

  Widget _buildTrackItem(
    MediaItem track,
    String serverUrl,
    int index,
    bool isSelected,
  ) {
    final duration = track.runtimeTicks != null
        ? Duration(microseconds: track.runtimeTicks! ~/ 10)
        : null;
    final durationStr = duration != null
        ? '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'
        : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
      child: GlassContainer(
        borderRadius: AppTheme.radiusMd,
        padding: const EdgeInsets.all(16),
        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : null,
        child: Row(
          children: [
            // Track number
            SizedBox(
              width: 50,
              child: Text(
                track.indexNumber?.toString() ?? '#',
                style: AppTextStyles.titleMedium.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 16),
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Image.network(
                  track.getPrimaryImageUrl(serverUrl, width: 100),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surface,
                    child: const Icon(
                      Icons.music_note,
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Track info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (track.artists?.isNotEmpty == true)
                    Text(
                      track.artists!.join(', '),
                      style: AppTextStyles.bodyMedium.copyWith(
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
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            // Duration
            SizedBox(
              width: 80,
              child: Text(
                durationStr,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 16),
            // Play indicator for selected
            if (isSelected)
              Icon(
                Icons.play_circle_fill,
                color: AppColors.primary,
                size: 32,
              ).animate().scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
              ),
          ],
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
      padding: const EdgeInsets.all(48),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 0.85,
        crossAxisSpacing: 32,
        mainAxisSpacing: 32,
      ),
      itemCount: state.artists.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedTabIndex == 2 && _selectedIndex == index;
        return _buildArtistCard(
          state.artists[index],
          serverUrl,
          index,
          isSelected,
        );
      },
    );
  }

  Widget _buildArtistCard(
    MediaItem artist,
    String serverUrl,
    int index,
    bool isSelected,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(isSelected ? 1.1 : 1.0),
      child: Column(
        children: [
          // Artist image (circular)
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppColors.primary, width: 4)
                      : null,
                  boxShadow: isSelected
                      ? AppTheme.shadowGlow(AppColors.primary)
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: ClipOval(
                  child: Image.network(
                    artist.getPrimaryImageUrl(serverUrl, width: 300),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.person,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Artist name
          Text(
            artist.name,
            style: AppTextStyles.titleMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
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
      padding: const EdgeInsets.all(48),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isCircle ? 6 : 5,
        childAspectRatio: isCircle ? 0.85 : 0.8,
        crossAxisSpacing: isCircle ? 32 : 24,
        mainAxisSpacing: isCircle ? 32 : 24,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return ShimmerLoading(borderRadius: isCircle ? 100 : AppTheme.radiusMd);
      },
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerLoading(height: 88, borderRadius: AppTheme.radiusMd),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: AppColors.textSecondary),
          const SizedBox(height: 24),
          Text(
            message,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
