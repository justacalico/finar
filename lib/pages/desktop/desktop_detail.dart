import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../core/services/download_service.dart';
import '../../core/services/controller_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'desktop_player.dart';

class DesktopDetail extends ConsumerStatefulWidget {
  final String itemId;

  const DesktopDetail({super.key, required this.itemId});

  @override
  ConsumerState<DesktopDetail> createState() => _DesktopDetailState();
}

class _DesktopDetailState extends ConsumerState<DesktopDetail> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _mainFocusNode = FocusNode();
  int _selectedSeasonIndex = 0;
  bool _showAllCast = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _mainFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!ControllerService.isKeyDown(event)) {
      return KeyEventResult.ignored;
    }

    final action = ControllerService.getAction(event);

    // Handle back button
    if (action == ControllerAction.back) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(mediaItemDetailProvider(widget.itemId));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return itemAsync.when(
      data: (item) {
        // If this is a track, redirect to the album instead
        if (item.type == MediaType.audio && item.albumId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => DesktopDetail(itemId: item.albumId!),
              ),
            );
          });
          return const _DetailLoadingView();
        }
        return _buildContent(item, serverUrl);
      },
      loading: () => const _DetailLoadingView(),
      error: (error, stack) => _DetailErrorView(
        error: error.toString(),
        onRetry: () => ref.refresh(mediaItemDetailProvider(widget.itemId)),
      ),
    );
  }

  Widget _buildContent(MediaItem item, String serverUrl) {
    return Focus(
      focusNode: _mainFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Stack(
          children: [
            // Background
            _buildBackground(item, serverUrl),

            // Content
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Hero section with backdrop
                SliverToBoxAdapter(child: _buildHeroSection(item, serverUrl)),

                // Info section
                SliverToBoxAdapter(child: _buildInfoSection(item, serverUrl)),

                // Episodes (for TV Shows)
                if (item.type == MediaType.series)
                  SliverToBoxAdapter(
                    child: _buildEpisodesSection(item, serverUrl),
                  ),

                // Album Tracks (for Music Albums)
                if (item.type == MediaType.album)
                  SliverToBoxAdapter(
                    child: _buildAlbumTracksSection(item, serverUrl),
                  ),

                // Cast & Crew
                if (item.people?.isNotEmpty == true)
                  SliverToBoxAdapter(child: _buildCastSection(item, serverUrl)),

                // Similar Items
                SliverToBoxAdapter(
                  child: _buildSimilarSection(item.id, serverUrl),
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // Back button
            Positioned(
              top: 20,
              left: 20,
              child: SafeArea(
                child: GlassIconButton(
                  icon: Icons.arrow_back,
                  autofocus: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(MediaItem item, String serverUrl) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop image
          Image.network(
            item.getBackdropImageUrl(serverUrl, width: 1920),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppColors.background),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.3),
                  AppColors.background.withValues(alpha: 0.7),
                  AppColors.background,
                ],
                stops: const [0.0, 0.4, 0.7],
              ),
            ),
          ),

          // Left gradient for content readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.background.withValues(alpha: 0.9),
                  AppColors.background.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(MediaItem item, String serverUrl) {
    return SizedBox(
      height: 500,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(64, 120, 64, 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Poster
            Hero(
              tag: 'poster_${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Image.network(
                  item.getPrimaryImageUrl(serverUrl, width: 400),
                  width: 250,
                  height: 375,
                  fit: BoxFit.cover,
                ),
              ),
            ).animate().fadeIn().scale(
              begin: const Offset(0.9, 0.9),
              duration: AppTheme.durationNormal,
            ),

            const SizedBox(width: 40),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Logo or title
                  if (item.logoImageTag != null)
                    Image.network(
                      '$serverUrl/Items/${item.id}/Images/Logo?maxWidth=500&tag=${item.logoImageTag}',
                      height: 80,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, _, _) =>
                          Text(item.name, style: AppTextStyles.displayMedium),
                    )
                  else
                    Text(item.name, style: AppTextStyles.displayMedium),

                  const SizedBox(height: 16),

                  // Metadata row
                  _buildMetadataRow(item),

                  const SizedBox(height: 16),

                  // Genres
                  if (item.genres?.isNotEmpty == true)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.genres!.take(5).map((genre) {
                        return GlassChip(label: genre);
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActionButtons(item),
                ],
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(MediaItem item) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (item.productionYear != null)
          Text(item.productionYear.toString(), style: AppTextStyles.bodyLarge),
        if (item.officialRating != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(item.officialRating!, style: AppTextStyles.labelSmall),
          ),
        if (item.formattedRuntime.isNotEmpty)
          Text(item.formattedRuntime, style: AppTextStyles.bodyLarge),
        if (item.communityRating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 18, color: AppColors.accentYellow),
              const SizedBox(width: 4),
              Text(
                item.communityRating!.toStringAsFixed(1),
                style: AppTextStyles.rating,
              ),
            ],
          ),
        if (item.criticRating != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.reviews, size: 16, color: AppColors.accentRed),
              const SizedBox(width: 4),
              Text('${item.criticRating}%', style: AppTextStyles.bodyMedium),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButtons(MediaItem item) {
    return Row(
      children: [
        // Play button
        SizedBox(
          width: 180,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _playItem(item),
            icon: const Icon(Icons.play_arrow, size: 28),
            label: Text(
              item.hasProgress ? 'Resume' : 'Play',
              style: AppTextStyles.buttonLarge,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Trailer button
        if (item.hasTrailer)
          GlassButton(
            onPressed: () => _playTrailer(item),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: const Row(
              children: [
                Icon(Icons.movie_outlined, size: 20),
                SizedBox(width: 8),
                Text('Trailer'),
              ],
            ),
          ),

        const SizedBox(width: 12),

        // Favorite button
        Consumer(
          builder: (context, ref, _) {
            final isFavorite = item.isFavorite == true;
            return GlassIconButton(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              iconColor: isFavorite ? AppColors.accentRed : null,
              onPressed: () => _toggleFavorite(item),
            );
          },
        ),

        const SizedBox(width: 8),

        // Mark watched button
        GlassIconButton(
          icon: (item.isPlayed == true)
              ? Icons.check_circle
              : Icons.check_circle_outline,
          iconColor: (item.isPlayed == true) ? AppColors.primary : null,
          onPressed: () => _toggleWatched(item),
        ),

        const SizedBox(width: 8),

        // Download button
        _buildDownloadButton(item),

        const SizedBox(width: 8),

        // More options
        GlassIconButton(
          icon: Icons.more_horiz,
          onPressed: () => _showMoreOptions(item),
        ),
      ],
    );
  }

  Widget _buildInfoSection(MediaItem item, String serverUrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overview', style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                Text(
                  item.overview ?? 'No overview available.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    height: 1.6,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (item.taglines?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Text(
                    '"${item.taglines!.first}"',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 64),

          // Additional info
          Expanded(child: _buildAdditionalInfo(item)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildAdditionalInfo(MediaItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.studios?.isNotEmpty == true)
          _buildInfoRow('Studio', item.studios!.first),
        if (item.productionYear != null)
          _buildInfoRow('Year', item.productionYear.toString()),
        if (item.container != null)
          _buildInfoRow('Format', item.container!.toUpperCase()),
        if (item.mediaStreams?.isNotEmpty == true) ...[
          _buildInfoRow(
            'Video',
            item.mediaStreams!
                    .where((s) => s.type == 'Video')
                    .map(
                      (s) => '${s.codec?.toUpperCase()} ${s.videoResolution}',
                    )
                    .firstOrNull ??
                'Unknown',
          ),
          _buildInfoRow(
            'Audio',
            item.mediaStreams!
                    .where((s) => s.type == 'Audio')
                    .map(
                      (s) =>
                          '${s.codec?.toUpperCase()} ${s.channelLayout ?? ''}',
                    )
                    .firstOrNull ??
                'Unknown',
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyles.labelMedium),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildEpisodesSection(MediaItem item, String serverUrl) {
    final seasonsAsync = ref.watch(seasonsProvider(item.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seasons section
          seasonsAsync.when(
            data: (seasons) => seasons.length > 1
                ? _buildSeasonsRow(seasons, serverUrl)
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Section header with season selector dropdown
          Row(
            children: [
              Text('Episodes', style: AppTextStyles.titleLarge),
              const Spacer(),
              seasonsAsync.when(
                data: (seasons) => _buildSeasonSelector(seasons),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Episodes list
          seasonsAsync.when(
            data: (seasons) {
              if (seasons.isEmpty) return const SizedBox.shrink();
              final seasonId = seasons[_selectedSeasonIndex].id;
              return _buildEpisodesList(seasonId, serverUrl);
            },
            loading: () => const _LoadingShimmer(height: 150),
            error: (error, _) => Text('Error loading seasons: $error'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildSeasonsRow(List<MediaItem> seasons, String serverUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seasons', style: AppTextStyles.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: seasons.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final season = seasons[index];
              final isSelected = _selectedSeasonIndex == index;
              return _buildSeasonCard(season, serverUrl, isSelected, index);
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSeasonCard(
    MediaItem season,
    String serverUrl,
    bool isSelected,
    int index,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedSeasonIndex = index),
      child: AnimatedContainer(
        duration: AppTheme.durationFast,
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Season poster
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd - 2),
              child: Stack(
                children: [
                  Image.network(
                    season.getPrimaryImageUrl(serverUrl, width: 200),
                    width: 124,
                    height: 124,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 124,
                      height: 124,
                      color: AppColors.surface,
                      child: const Icon(Icons.tv, size: 32),
                    ),
                  ),
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Season name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                season.name,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonSelector(List<MediaItem> seasons) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.1,
      borderRadius: AppTheme.radiusMd,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(seasons.length, (index) {
          final isSelected = _selectedSeasonIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedSeasonIndex = index),
            child: AnimatedContainer(
              duration: AppTheme.durationFast,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                seasons[index].name,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.black : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEpisodesList(String seasonId, String serverUrl) {
    final episodesAsync = ref.watch(episodesProvider(seasonId));

    return episodesAsync.when(
      data: (episodes) => SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: episodes.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final episode = episodes[index];
            return _buildEpisodeCard(episode, serverUrl, seasonId);
          },
        ),
      ),
      loading: () => const _LoadingShimmer(height: 220),
      error: (error, _) => Text('Error loading episodes: $error'),
    );
  }

  Widget _buildEpisodeCard(
    MediaItem episode,
    String serverUrl,
    String seasonId,
  ) {
    final isWatched = episode.isPlayed == true;

    return GlassCard(
      width: 320,
      onTap: () => _playItem(episode),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbnail
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMd),
                ),
                child: ColorFiltered(
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
                    episode.getPrimaryImageUrl(serverUrl, width: 500),
                    width: 320,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Watched indicator
              if (isWatched)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
              // Progress bar
              if (episode.hasProgress && !isWatched)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: episode.progressPercent,
                    backgroundColor: AppColors.black.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 3,
                  ),
                ),
              // Play icon overlay
              Positioned.fill(
                child: Center(
                  child: Icon(
                    isWatched ? Icons.replay : Icons.play_circle_outline,
                    size: 48,
                    color: AppColors.white,
                  ),
                ),
              ),
              // Mark watched button
              Positioned(
                top: 8,
                left: 8,
                child: GlassIconButton(
                  icon: isWatched ? Icons.visibility_off : Icons.visibility,
                  size: 32,
                  onPressed: () => _toggleEpisodeWatched(episode, seasonId),
                ),
              ),
            ],
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'E${episode.indexNumber} - ${episode.name}',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: isWatched
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
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
                Text(
                  episode.overview ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleEpisodeWatched(MediaItem episode, String seasonId) {
    ref
        .read(mediaActionsProvider)
        .markEpisodeWatched(episode.id, seasonId, !(episode.isPlayed == true));
  }

  Widget _buildAlbumTracksSection(MediaItem album, String serverUrl) {
    final tracksAsync = ref.watch(albumTracksProvider(album.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
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
          tracksAsync.when(
            data: (tracks) => _buildTracksList(tracks, album, serverUrl),
            loading: () => const _LoadingShimmer(height: 300),
            error: (error, _) => Text('Error loading tracks: $error'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTracksList(
    List<MediaItem> tracks,
    MediaItem album,
    String serverUrl,
  ) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      borderRadius: AppTheme.radiusMd,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return _buildTrackTile(track, index + 1, album, serverUrl);
        },
      ),
    );
  }

  Widget _buildTrackTile(
    MediaItem track,
    int trackNumber,
    MediaItem album,
    String serverUrl,
  ) {
    final duration = track.formattedRuntime;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _playItem(track),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                duration,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(width: 16),

              // Play button
              GlassIconButton(
                icon: Icons.play_arrow,
                size: 36,
                onPressed: () => _playItem(track),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCastSection(MediaItem item, String serverUrl) {
    final people = item.people ?? [];
    final displayPeople = _showAllCast ? people : people.take(10).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Cast & Crew', style: AppTextStyles.titleLarge),
              const Spacer(),
              if (people.length > 10)
                TextButton(
                  onPressed: () => setState(() => _showAllCast = !_showAllCast),
                  child: Text(_showAllCast ? 'Show Less' : 'See All'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: displayPeople.map((person) {
              return _buildPersonCard(person, serverUrl);
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildPersonCard(PersonInfo person, String serverUrl) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.surface,
            backgroundImage: person.primaryImageTag != null
                ? NetworkImage(
                    '$serverUrl/Items/${person.id}/Images/Primary?maxWidth=150&tag=${person.primaryImageTag}',
                  )
                : null,
            child: person.primaryImageTag == null
                ? const Icon(Icons.person, size: 32)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            person.name,
            style: AppTextStyles.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (person.role != null)
            Text(
              person.role!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildSimilarSection(String itemId, String serverUrl) {
    final similarAsync = ref.watch(similarItemsProvider(itemId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 0, 64, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('More Like This', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: similarAsync.when(
              data: (items) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return AnimatedCard(
                    width: 160,
                    imageUrl: item.getPrimaryImageUrl(serverUrl, width: 300),
                    title: item.name,
                    subtitle: item.productionYear?.toString(),
                    animationIndex: index,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => DesktopDetail(itemId: item.id),
                        ),
                      );
                    },
                  );
                },
              ),
              loading: () => const _LoadingShimmer(height: 280),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildDownloadButton(MediaItem item) {
    final downloadState = ref.watch(downloadProvider);
    final existingDownload = downloadState.getTaskForItem(item.id);

    if (existingDownload != null) {
      switch (existingDownload.status) {
        case DownloadStatus.downloading:
          return Stack(
            alignment: Alignment.center,
            children: [
              GlassIconButton(
                icon: Icons.downloading,
                onPressed: () => _pauseDownload(existingDownload.id),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    value: existingDownload.progress,
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          );
        case DownloadStatus.paused:
          return GlassIconButton(
            icon: Icons.pause_circle_outline,
            iconColor: AppColors.warning,
            onPressed: () => _resumeDownload(existingDownload.id),
          );
        case DownloadStatus.completed:
          return GlassIconButton(
            icon: Icons.download_done,
            iconColor: AppColors.success,
            onPressed: () => _showDownloadOptions(existingDownload.id),
          );
        case DownloadStatus.failed:
          return GlassIconButton(
            icon: Icons.error_outline,
            iconColor: AppColors.error,
            onPressed: () => _downloadItem(item),
          );
        case DownloadStatus.pending:
          return GlassIconButton(
            icon: Icons.hourglass_empty,
            onPressed: () => _cancelDownload(existingDownload.id),
          );
        case DownloadStatus.cancelled:
          return GlassIconButton(
            icon: Icons.download_outlined,
            onPressed: () => _downloadItem(item),
          );
      }
    }

    return GlassIconButton(
      icon: Icons.download_outlined,
      onPressed: () => _downloadItem(item),
    );
  }

  Future<void> _downloadItem(MediaItem item) async {
    try {
      await ref.read(downloadProvider.notifier).downloadItem(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting download: ${item.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start download: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _pauseDownload(String taskId) {
    ref.read(downloadProvider.notifier).pauseDownload(taskId);
  }

  void _resumeDownload(String taskId) {
    ref.read(downloadProvider.notifier).resumeDownload(taskId);
  }

  void _cancelDownload(String taskId) {
    ref.read(downloadProvider.notifier).cancelDownload(taskId);
  }

  void _showDownloadOptions(String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Download Options'),
        content: const Text(
          'This item has been downloaded. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadProvider.notifier).deleteDownload(taskId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download removed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Remove Download',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _playItem(MediaItem item) {
    // Check if this is music content
    final isMusic =
        item.type == MediaType.audio ||
        item.type == MediaType.album ||
        item.type == MediaType.musicVideo;

    if (item.type == MediaType.album) {
      // For albums, fetch tracks and play as playlist
      _playAlbum(item);
    } else if (item.type == MediaType.series) {
      // For series, play the next up episode (continue watching)
      _playSeries(item);
    } else {
      ref.read(playerProvider.notifier).play(item);

      // Only navigate to video player for non-music content
      if (!isMusic) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const DesktopPlayer()));
      }
    }
  }

  Future<void> _playSeries(MediaItem series) async {
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final nextUp = await mediaService.getNextUpForSeries(series.id);

      if (nextUp != null) {
        // Play the next up episode
        ref.read(playerProvider.notifier).play(nextUp);
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DesktopPlayer()),
          );
        }
      } else {
        // No next up episode, get the first episode of the first season
        final seasons = await mediaService.getSeasons(series.id);
        if (seasons.isNotEmpty) {
          final episodes = await mediaService.getSeasonEpisodes(
            series.id,
            seasons.first.id,
          );
          if (episodes.isNotEmpty) {
            ref.read(playerProvider.notifier).play(episodes.first);
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DesktopPlayer()),
              );
            }
          } else {
            _showNoEpisodesError();
          }
        } else {
          _showNoEpisodesError();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play series: $e')));
      }
    }
  }

  void _showNoEpisodesError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No episodes available to play')),
      );
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play album: $e')));
      }
    }
  }

  void _playTrailer(MediaItem item) async {
    try {
      // First try to get local trailers
      if (item.localTrailerCount != null && item.localTrailerCount! > 0) {
        final mediaService = ref.read(mediaServiceProvider);
        final trailers = await mediaService.getLocalTrailers(item.id);
        if (trailers.isNotEmpty) {
          ref.read(playerProvider.notifier).play(trailers.first);
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const DesktopPlayer()),
            );
          }
          return;
        }
      }

      // Fall back to remote trailers (YouTube, etc.)
      if (item.remoteTrailers != null && item.remoteTrailers!.isNotEmpty) {
        final trailer = item.remoteTrailers!.first;
        if (trailer.url != null) {
          // For remote trailers (usually YouTube), open in browser or show message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening trailer: ${trailer.name ?? "Trailer"}'),
                action: SnackBarAction(
                  label: 'Open',
                  onPressed: () {
                    // Launch URL - you may want to use url_launcher package
                  },
                ),
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No trailer available')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to play trailer: $e')));
      }
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

  void _showMoreOptions(MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoreOptionsSheet(item: item),
    );
  }
}

class _DetailLoadingView extends StatelessWidget {
  const _DetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _DetailErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _DetailErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to load details', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(error, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  final double height;

  const _LoadingShimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(height: height, borderRadius: AppTheme.radiusMd);
  }
}

class _MoreOptionsSheet extends StatelessWidget {
  final MediaItem item;

  const _MoreOptionsSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: AppTheme.blurHeavy,
      opacity: 0.1,
      borderRadius: AppTheme.radiusXl,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          _buildOption(Icons.download_outlined, 'Download'),
          _buildOption(Icons.playlist_add, 'Add to Playlist'),
          _buildOption(Icons.share_outlined, 'Share'),
          _buildOption(Icons.info_outline, 'Media Info'),
          _buildOption(Icons.bug_report_outlined, 'Report Issue'),
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String label) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: () {});
  }
}
