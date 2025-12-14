import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../core/services/download_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'tv_player.dart';

class TvDetail extends ConsumerStatefulWidget {
  final String itemId;

  const TvDetail({super.key, required this.itemId});

  @override
  ConsumerState<TvDetail> createState() => _TvDetailState();
}

class _TvDetailState extends ConsumerState<TvDetail> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _episodesScrollController = ScrollController();
  int _selectedButtonIndex = 0;
  int _selectedSeasonIndex = 0;
  int _selectedEpisodeIndex = 0;
  bool _inEpisodeSelection = false;

  static const double _episodeCardHeight = 110.0; // Card height + spacing

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _episodesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(mediaItemDetailProvider(widget.itemId));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: itemAsync.when(
          data: (item) {
            // If this is a track, redirect to the album instead
            if (item.type == MediaType.audio && item.albumId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => TvDetail(itemId: item.albumId!),
                  ),
                );
              });
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            return _buildContent(item, serverUrl);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildContent(MediaItem item, String serverUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        _buildBackground(item, serverUrl),

        // Content
        Row(
          children: [
            // Left side - Info
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    GlassIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),

                    const SizedBox(height: 32),

                    // Logo or title
                    if (item.logoImageTag != null)
                      Image.network(
                        '$serverUrl/Items/${item.id}/Images/Logo?maxWidth=500&tag=${item.logoImageTag}',
                        height: 100,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        errorBuilder: (_, _, _) =>
                            Text(item.name, style: AppTextStyles.displayMedium),
                      )
                    else
                      Text(item.name, style: AppTextStyles.displayMedium),

                    const SizedBox(height: 16),

                    // Metadata
                    _buildMetadata(item),

                    const SizedBox(height: 24),

                    // Overview
                    if (item.overview != null)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            item.overview!,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Action buttons
                    _buildActionButtons(item),
                  ],
                ),
              ),
            ),

            // Right side - Episodes (for TV shows)
            if (item.type == MediaType.series)
              Expanded(flex: 4, child: _buildEpisodesPanel(item, serverUrl)),

            // Right side - Tracks (for music albums)
            if (item.type == MediaType.album)
              Expanded(flex: 4, child: _buildAlbumTracksPanel(item, serverUrl)),
          ],
        ),
      ],
    );
  }

  Widget _buildBackground(MediaItem item, String serverUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Backdrop
        Image.network(
          item.getBackdropImageUrl(serverUrl, width: 1920),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: AppColors.background),
        ),

        // Gradient overlays
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.background,
                AppColors.background.withValues(alpha: 0.8),
                AppColors.background.withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.background, Colors.transparent],
              stops: const [0.0, 0.5],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata(MediaItem item) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (item.productionYear != null)
          Text(
            item.productionYear.toString(),
            style: AppTextStyles.titleMedium,
          ),
        if (item.officialRating != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(item.officialRating!, style: AppTextStyles.labelMedium),
          ),
        if (item.formattedRuntime.isNotEmpty)
          Text(item.formattedRuntime, style: AppTextStyles.titleMedium),
        if (item.communityRating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 20, color: AppColors.accentYellow),
              const SizedBox(width: 4),
              Text(
                item.communityRating!.toStringAsFixed(1),
                style: AppTextStyles.rating,
              ),
            ],
          ),
        if (item.genres?.isNotEmpty == true)
          Text(
            item.genres!.take(3).join(' • '),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(MediaItem item) {
    final downloadState = ref.watch(downloadProvider);
    final existingDownload = downloadState.getTaskForItem(item.id);

    final downloadIcon = _getDownloadIcon(existingDownload);
    final downloadLabel = _getDownloadLabel(existingDownload);

    final buttons = [
      _ActionButton(
        icon: Icons.play_arrow,
        label: item.hasProgress ? 'Resume' : 'Play',
        isPrimary: true,
        onPressed: () => _playItem(item),
      ),
      if (item.hasTrailer)
        _ActionButton(
          icon: Icons.movie_outlined,
          label: 'Trailer',
          onPressed: () {},
        ),
      _ActionButton(
        icon: item.isFavorite == true ? Icons.favorite : Icons.favorite_border,
        label: 'Favorite',
        onPressed: () => _toggleFavorite(item),
      ),
      _ActionButton(
        icon: item.isPlayed == true
            ? Icons.check_circle
            : Icons.check_circle_outline,
        label: 'Watched',
        onPressed: () => _toggleWatched(item),
      ),
      _ActionButton(
        icon: downloadIcon,
        label: downloadLabel,
        onPressed: () => _handleDownloadAction(item, existingDownload),
      ),
    ];

    return Row(
      children: buttons.asMap().entries.map((entry) {
        final index = entry.key;
        final button = entry.value;
        final isSelected =
            !_inEpisodeSelection && _selectedButtonIndex == index;

        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
            child: button.isPrimary
                ? ElevatedButton.icon(
                    onPressed: button.onPressed,
                    icon: Icon(button.icon),
                    label: Text(button.label),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  )
                : GlassButton(
                    onPressed: button.onPressed,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(button.icon, size: 20),
                        const SizedBox(width: 8),
                        Text(button.label),
                      ],
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEpisodesPanel(MediaItem item, String serverUrl) {
    final seasonsAsync = ref.watch(seasonsProvider(item.id));

    return Container(
      margin: const EdgeInsets.all(32),
      child: GlassContainer(
        blur: AppTheme.blurMedium,
        opacity: 0.1,
        borderRadius: AppTheme.radiusLg,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Season selector
            seasonsAsync.when(
              data: (seasons) => _buildSeasonTabs(seasons),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Episodes list
            Expanded(
              child: seasonsAsync.when(
                data: (seasons) {
                  if (seasons.isEmpty) return const SizedBox.shrink();
                  final seasonId = seasons[_selectedSeasonIndex].id;
                  return _buildEpisodesList(seasonId, serverUrl);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildSeasonTabs(List<MediaItem> seasons) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedSeasonIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedSeasonIndex = index),
            child: AnimatedContainer(
              duration: AppTheme.durationFast,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border:
                    _inEpisodeSelection &&
                        _selectedEpisodeIndex == -1 &&
                        _selectedSeasonIndex == index
                    ? Border.all(color: AppColors.accentBlue, width: 2)
                    : null,
              ),
              child: Text(
                seasons[index].name,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.black : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEpisodesList(String seasonId, String serverUrl) {
    final episodesAsync = ref.watch(episodesProvider(seasonId));

    return episodesAsync.when(
      data: (episodes) => ListView.separated(
        controller: _episodesScrollController,
        itemCount: episodes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final episode = episodes[index];
          final isSelected =
              _inEpisodeSelection && _selectedEpisodeIndex == index;
          return _buildEpisodeCard(episode, serverUrl, isSelected, seasonId);
        },
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildEpisodeCard(
    MediaItem episode,
    String serverUrl,
    bool isSelected,
    String seasonId,
  ) {
    final isWatched = episode.isPlayed == true;

    return GestureDetector(
      onTap: () => _playItem(episode),
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd + 4),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Stack(
                children: [
                  ColorFiltered(
                    colorFilter: isWatched
                        ? ColorFilter.mode(
                            AppColors.black.withValues(alpha: 0.3),
                            BlendMode.darken,
                          )
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          ),
                    child: Image.network(
                      episode.getPrimaryImageUrl(serverUrl, width: 300),
                      width: 160,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 160,
                        height: 90,
                        color: AppColors.surface,
                        child: const Icon(Icons.movie),
                      ),
                    ),
                  ),
                  // Watched indicator
                  if (isWatched)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  if (episode.hasProgress && !isWatched)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: episode.progressPercent,
                        backgroundColor: AppColors.black.withValues(alpha: 0.5),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                        minHeight: 3,
                      ),
                    ),
                  Positioned.fill(
                    child: Center(
                      child: Icon(
                        isWatched ? Icons.replay : Icons.play_circle_outline,
                        size: 32,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'E${episode.indexNumber} - ${episode.name}',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isWatched
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isWatched)
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (episode.overview != null)
                    Text(
                      episode.overview!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  if (episode.formattedRuntime.isNotEmpty)
                    Text(
                      episode.formattedRuntime,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumTracksPanel(MediaItem album, String serverUrl) {
    final tracksAsync = ref.watch(albumTracksProvider(album.id));

    return Container(
      margin: const EdgeInsets.all(32),
      child: GlassContainer(
        blur: AppTheme.blurMedium,
        opacity: 0.1,
        borderRadius: AppTheme.radiusLg,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text('Tracks', style: AppTextStyles.titleLarge),
                const Spacer(),
                tracksAsync
                        .whenData(
                          (tracks) => Text(
                            '${tracks.length} songs',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                        .value ??
                    const SizedBox.shrink(),
              ],
            ),

            const SizedBox(height: 16),

            // Tracks list
            Expanded(
              child: tracksAsync.when(
                data: (tracks) => ListView.separated(
                  itemCount: tracks.length,
                  separatorBuilder: (_, _) => Divider(
                    color: AppColors.divider.withValues(alpha: 0.3),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return _buildTrackTile(track, index + 1, album, serverUrl);
                  },
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1);
  }

  Widget _buildTrackTile(
    MediaItem track,
    int trackNumber,
    MediaItem album,
    String serverUrl,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _playItem(track),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Row(
            children: [
              // Track number
              SizedBox(
                width: 40,
                child: Text(
                  track.indexNumber?.toString() ?? trackNumber.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: 16),

              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      style: AppTextStyles.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (track.albumArtist != null ||
                        track.artists?.isNotEmpty == true)
                      Text(
                        track.albumArtist ?? track.artists?.join(', ') ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Duration
              Text(
                track.formattedRuntime,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(width: 16),

              // Play icon
              Icon(
                Icons.play_circle_outline,
                color: AppColors.textSecondary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final itemAsync = ref.read(mediaItemDetailProvider(widget.itemId));
    final item = itemAsync.valueOrNull;
    if (item == null) return;

    final isSeries = item.type == MediaType.series;
    final buttonCount = _getButtonCount(item);

    // Get episodes count for bounds checking
    int episodesCount = 0;
    if (isSeries) {
      final seasonsAsync = ref.read(seasonsProvider(item.id));
      final seasons = seasonsAsync.valueOrNull ?? [];
      if (seasons.isNotEmpty && _selectedSeasonIndex < seasons.length) {
        final seasonId = seasons[_selectedSeasonIndex].id;
        final episodesAsync = ref.read(episodesProvider(seasonId));
        episodesCount = episodesAsync.valueOrNull?.length ?? 0;
      }
    }

    setState(() {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          if (_inEpisodeSelection && _selectedEpisodeIndex > 0) {
            _selectedEpisodeIndex--;
            _scrollToSelectedEpisode();
          } else if (_inEpisodeSelection && _selectedEpisodeIndex == 0) {
            _selectedEpisodeIndex = -1; // Season tabs
            _scrollToTopOfEpisodes();
          }
          break;

        case LogicalKeyboardKey.arrowDown:
          if (_inEpisodeSelection) {
            if (_selectedEpisodeIndex == -1) {
              _selectedEpisodeIndex = 0;
              _scrollToSelectedEpisode();
            } else if (_selectedEpisodeIndex < episodesCount - 1) {
              _selectedEpisodeIndex++;
              _scrollToSelectedEpisode();
            }
          }
          break;

        case LogicalKeyboardKey.arrowLeft:
          if (_inEpisodeSelection) {
            if (_selectedEpisodeIndex == -1 && _selectedSeasonIndex > 0) {
              _selectedSeasonIndex--;
              _selectedEpisodeIndex = 0;
              _scrollToTopOfEpisodes();
            } else {
              _inEpisodeSelection = false;
            }
          } else if (_selectedButtonIndex > 0) {
            _selectedButtonIndex--;
          }
          break;

        case LogicalKeyboardKey.arrowRight:
          if (_inEpisodeSelection && _selectedEpisodeIndex == -1) {
            final seasonsAsync = ref.read(seasonsProvider(item.id));
            final seasons = seasonsAsync.valueOrNull ?? [];
            if (_selectedSeasonIndex < seasons.length - 1) {
              _selectedSeasonIndex++;
              _selectedEpisodeIndex = 0;
              _scrollToTopOfEpisodes();
            }
          } else if (!_inEpisodeSelection) {
            if (_selectedButtonIndex < buttonCount - 1) {
              _selectedButtonIndex++;
            } else if (isSeries) {
              _inEpisodeSelection = true;
              _selectedEpisodeIndex = 0;
              _scrollToTopOfEpisodes();
            }
          }
          break;

        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
          _handleSelect(item);
          break;

        case LogicalKeyboardKey.goBack:
        case LogicalKeyboardKey.escape:
          if (_inEpisodeSelection) {
            _inEpisodeSelection = false;
          } else {
            Navigator.pop(context);
          }
          break;
      }
    });
  }

  void _scrollToSelectedEpisode() {
    if (_selectedEpisodeIndex < 0) return;

    final targetOffset = _selectedEpisodeIndex * _episodeCardHeight;
    final maxScroll = _episodesScrollController.hasClients
        ? _episodesScrollController.position.maxScrollExtent
        : 0.0;

    if (_episodesScrollController.hasClients) {
      _episodesScrollController.animateTo(
        targetOffset.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToTopOfEpisodes() {
    if (_episodesScrollController.hasClients) {
      _episodesScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  int _getButtonCount(MediaItem item) {
    int count = 1; // Play
    if (item.hasTrailer) count++;
    count += 2; // Favorite + Watched
    return count;
  }

  void _handleSelect(MediaItem item) {
    if (_inEpisodeSelection) {
      if (_selectedEpisodeIndex >= 0) {
        final seasonsAsync = ref.read(seasonsProvider(item.id));
        final seasons = seasonsAsync.valueOrNull ?? [];
        if (seasons.isNotEmpty) {
          final seasonId = seasons[_selectedSeasonIndex].id;
          final episodesAsync = ref.read(episodesProvider(seasonId));
          final episodes = episodesAsync.valueOrNull ?? [];
          if (_selectedEpisodeIndex < episodes.length) {
            _playItem(episodes[_selectedEpisodeIndex]);
          }
        }
      }
    } else {
      // Handle button press
      int index = _selectedButtonIndex;
      if (index == 0) {
        _playItem(item);
      } else if (item.hasTrailer && index == 1) {
        // Play trailer
      } else {
        final adjustedIndex = item.hasTrailer ? index - 1 : index;
        if (adjustedIndex == 1) {
          _toggleFavorite(item);
        } else if (adjustedIndex == 2) {
          _toggleWatched(item);
        }
      }
    }
  }

  void _playItem(MediaItem item) {
    // Check if this is music content
    final isMusic = item.type == MediaType.audio || 
                    item.type == MediaType.album ||
                    item.type == MediaType.musicVideo;
    
    if (item.type == MediaType.album) {
      // For albums, fetch tracks and play as playlist
      _playAlbum(item);
    } else {
      ref.read(playerProvider.notifier).play(item);
      
      // Only navigate to video player for non-music content
      if (!isMusic) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TvPlayer()),
        );
      }
    }
  }

  Future<void> _playAlbum(MediaItem album) async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final tracks = await mediaService.getAlbumTracks(album.id);
      if (tracks.isNotEmpty) {
        ref.read(playerProvider.notifier).playPlaylist(tracks, 0);
      }
    } catch (e) {
      // Silently fail on TV
    }
  }

  void _toggleFavorite(MediaItem item) {
    ref
        .read(mediaActionsProvider)
        .toggleFavorite(item.id, !(item.isFavorite == true));
  }

  void _toggleWatched(MediaItem item) {
    ref
        .read(mediaActionsProvider)
        .toggleWatched(item.id, !(item.isPlayed == true));
  }

  IconData _getDownloadIcon(DownloadTask? download) {
    if (download == null) return Icons.download_outlined;
    switch (download.status) {
      case DownloadStatus.downloading:
        return Icons.downloading;
      case DownloadStatus.paused:
        return Icons.pause_circle_outline;
      case DownloadStatus.completed:
        return Icons.download_done;
      case DownloadStatus.failed:
        return Icons.error_outline;
      case DownloadStatus.pending:
        return Icons.hourglass_empty;
      case DownloadStatus.cancelled:
        return Icons.download_outlined;
    }
  }

  String _getDownloadLabel(DownloadTask? download) {
    if (download == null) return 'Download';
    switch (download.status) {
      case DownloadStatus.downloading:
        return '${(download.progress * 100).toInt()}%';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Downloaded';
      case DownloadStatus.failed:
        return 'Retry';
      case DownloadStatus.pending:
        return 'Pending';
      case DownloadStatus.cancelled:
        return 'Download';
    }
  }

  void _handleDownloadAction(MediaItem item, DownloadTask? download) {
    if (download == null ||
        download.status == DownloadStatus.cancelled ||
        download.status == DownloadStatus.failed) {
      _startDownload(item);
    } else if (download.status == DownloadStatus.downloading) {
      ref.read(downloadProvider.notifier).pauseDownload(download.id);
    } else if (download.status == DownloadStatus.paused) {
      ref.read(downloadProvider.notifier).resumeDownload(download.id);
    } else if (download.status == DownloadStatus.pending) {
      ref.read(downloadProvider.notifier).cancelDownload(download.id);
    } else if (download.status == DownloadStatus.completed) {
      _showDownloadCompleteDialog(download.id);
    }
  }

  Future<void> _startDownload(MediaItem item) async {
    try {
      await ref.read(downloadProvider.notifier).downloadItem(item);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start download: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDownloadCompleteDialog(String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Download Complete'),
        content: const Text('This item has been downloaded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadProvider.notifier).deleteDownload(taskId);
              Navigator.pop(context);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  _ActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onPressed,
  });
}
