import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'mobile_player.dart';

class MobileDetail extends ConsumerStatefulWidget {
  final String itemId;

  const MobileDetail({
    super.key,
    required this.itemId,
  });

  @override
  ConsumerState<MobileDetail> createState() => _MobileDetailState();
}

class _MobileDetailState extends ConsumerState<MobileDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedSeasonIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = ref.watch(mediaItemDetailProvider(widget.itemId));
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Scaffold(
      body: itemAsync.when(
        data: (item) => _buildContent(item, serverUrl),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load', style: AppTextStyles.titleMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(mediaItemDetailProvider(widget.itemId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MediaItem item, String serverUrl) {
    return CustomScrollView(
      slivers: [
        // Collapsing header with backdrop
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.background,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Backdrop image
                CachedNetworkImage(
                  imageUrl: item.getBackdropImageUrl(serverUrl, width: 800),
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.surface),
                  errorWidget: (_, _, _) =>
                      Container(color: AppColors.surface),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.7),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with poster and info
                _buildHeaderRow(item, serverUrl),

                const SizedBox(height: 24),

                // Action buttons
                _buildActionButtons(item),

                const SizedBox(height: 24),

                // Overview
                if (item.overview != null) ...[
                  Text('Overview', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    item.overview!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),

        // Episodes section for TV shows
        if (item.type == MediaType.series) ...[
          SliverToBoxAdapter(
            child: _buildEpisodesSection(item, serverUrl),
          ),
        ],

        // Cast section
        if (item.people?.isNotEmpty == true)
          SliverToBoxAdapter(
            child: _buildCastSection(item, serverUrl),
          ),

        // Similar items
        SliverToBoxAdapter(
          child: _buildSimilarSection(item.id, serverUrl),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(MediaItem item, String serverUrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poster
        Hero(
          tag: 'poster_${item.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: CachedNetworkImage(
              imageUrl: item.getPrimaryImageUrl(serverUrl, width: 300),
              width: 120,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 8),
              // Metadata
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (item.productionYear != null)
                    _buildMetadataChip(item.productionYear.toString()),
                  if (item.officialRating != null)
                    _buildMetadataChip(item.officialRating!),
                  if (item.formattedRuntime.isNotEmpty)
                    _buildMetadataChip(item.formattedRuntime),
                ],
              ),
              const SizedBox(height: 8),
              // Rating
              if (item.communityRating != null)
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 18,
                      color: AppColors.accentYellow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.communityRating!.toStringAsFixed(1),
                      style: AppTextStyles.rating,
                    ),
                    if (item.criticRating != null) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.reviews,
                        size: 16,
                        color: AppColors.accentRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.criticRating}%',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 8),
              // Genres
              if (item.genres?.isNotEmpty == true)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.genres!.take(3).map((genre) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        genre,
                        style: AppTextStyles.labelSmall,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildMetadataChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall,
      ),
    );
  }

  Widget _buildActionButtons(MediaItem item) {
    return Column(
      children: [
        // Primary play button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _playItem(item),
            icon: const Icon(Icons.play_arrow, size: 24),
            label: Text(
              item.hasProgress ? 'Resume' : 'Play',
              style: AppTextStyles.buttonLarge,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary actions
        Row(
          children: [
            // Trailer
            if (item.hasTrailer)
              Expanded(
                child: GlassButton(
                  onPressed: () => _playTrailer(item),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Trailer'),
                    ],
                  ),
                ),
              ),
            if (item.hasTrailer) const SizedBox(width: 12),

            // Favorite
            GlassIconButton(
              icon: (item.isFavorite == true) ? Icons.favorite : Icons.favorite_border,
              iconColor: (item.isFavorite == true) ? AppColors.accentRed : null,
              onPressed: () => _toggleFavorite(item),
            ),

            const SizedBox(width: 8),

            // Watched
            GlassIconButton(
              icon: (item.isPlayed == true)
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              iconColor: (item.isPlayed == true) ? AppColors.primary : null,
              onPressed: () => _toggleWatched(item),
            ),

            const SizedBox(width: 8),

            // Download
            GlassIconButton(
              icon: Icons.download_outlined,
              onPressed: () => _downloadItem(item),
            ),

            const SizedBox(width: 8),

            // Share
            GlassIconButton(
              icon: Icons.share_outlined,
              onPressed: () => _shareItem(item),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildEpisodesSection(MediaItem item, String serverUrl) {
    final seasonsAsync = ref.watch(seasonsProvider(item.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Episodes', style: AppTextStyles.titleMedium),
        ),
        const SizedBox(height: 12),

        // Season selector
        seasonsAsync.when(
          data: (seasons) => _buildSeasonTabs(seasons),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 12),

        // Episodes list
        seasonsAsync.when(
          data: (seasons) {
            if (seasons.isEmpty) return const SizedBox.shrink();
            final seasonId = seasons[_selectedSeasonIndex].id;
            return _buildEpisodesList(seasonId, serverUrl);
          },
          loading: () => const ShimmerLoading(height: 120),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading seasons: $error'),
          ),
        ),

        const SizedBox(height: 24),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSeasonTabs(List<MediaItem> seasons) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedSeasonIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedSeasonIndex = index),
            child: AnimatedContainer(
              duration: AppTheme.durationFast,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              alignment: Alignment.center,
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
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: episodes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return _buildEpisodeCard(episode, serverUrl);
        },
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerLoading(height: 100),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildEpisodeCard(MediaItem episode, String serverUrl) {
    return GlassCard(
      onTap: () => _playItem(episode),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: episode.getPrimaryImageUrl(serverUrl, width: 250),
                  width: 130,
                  height: 75,
                  fit: BoxFit.cover,
                ),
                // Progress bar
                if (episode.hasProgress)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: episode.progressPercent,
                      backgroundColor: AppColors.black.withValues(alpha: 0.5),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 3,
                    ),
                  ),
                // Play icon
                const Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 32,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'E${episode.indexNumber} - ${episode.name}',
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildCastSection(MediaItem item, String serverUrl) {
    final people = item.people ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cast & Crew', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: people.length.clamp(0, 10),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final person = people[index];
                return _buildPersonCard(person, serverUrl);
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildPersonCard(PersonInfo person, String serverUrl) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.surface,
            backgroundImage: person.primaryImageTag != null
                ? CachedNetworkImageProvider(
                    '$serverUrl/Items/${person.id}/Images/Primary?maxWidth=150&tag=${person.primaryImageTag}',
                  )
                : null,
            child: person.primaryImageTag == null
                ? const Icon(Icons.person, size: 24)
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('More Like This', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: similarAsync.when(
              data: (items) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return AnimatedCard(
                    width: 120,
                    imageUrl: item.getPrimaryImageUrl(serverUrl, width: 200),
                    title: item.name,
                    subtitle: item.productionYear?.toString(),
                    animationIndex: index,
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => MobileDetail(itemId: item.id),
                        ),
                      );
                    },
                  );
                },
              ),
              loading: () => const ShimmerLoading(height: 200),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  void _playItem(MediaItem item) {
    ref.read(playerProvider.notifier).play(item);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MobilePlayer(),
      ),
    );
  }

  void _playTrailer(MediaItem item) {
    // TODO: Implement trailer playback
  }

  void _toggleFavorite(MediaItem item) {
    ref.read(mediaActionsProvider).toggleFavorite(item.id, !(item.isFavorite == true));
  }

  void _toggleWatched(MediaItem item) {
    ref.read(mediaActionsProvider).toggleWatched(item.id, !(item.isPlayed == true));
  }

  void _downloadItem(MediaItem item) {
    // TODO: Implement download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download coming soon')),
    );
  }

  void _shareItem(MediaItem item) {
    // TODO: Implement share
  }
}
