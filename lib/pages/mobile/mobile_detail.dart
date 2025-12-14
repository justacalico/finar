import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../core/services/download_service.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'mobile_player.dart';

class MobileDetail extends ConsumerStatefulWidget {
  final String itemId;

  const MobileDetail({super.key, required this.itemId});

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
                  errorWidget: (_, _, _) => Container(color: AppColors.surface),
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
          SliverToBoxAdapter(child: _buildEpisodesSection(item, serverUrl)),
        ],

        // Cast section
        if (item.people?.isNotEmpty == true)
          SliverToBoxAdapter(child: _buildCastSection(item, serverUrl)),

        // Similar items
        SliverToBoxAdapter(child: _buildSimilarSection(item.id, serverUrl)),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
              Text(item.name, style: AppTextStyles.headlineSmall),
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
                      child: Text(genre, style: AppTextStyles.labelSmall),
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
      child: Text(text, style: AppTextStyles.labelSmall),
    );
  }

  Widget _buildActionButtons(MediaItem item) {
    return Row(
      children: [
        // Primary play button
        Expanded(
          child: SizedBox(
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
        ),

        // Trailer button
        if (item.hasTrailer) ...[
          const SizedBox(width: 12),
          GlassButton(
            onPressed: () => _playTrailer(item),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_outlined, size: 18),
                SizedBox(width: 8),
                Text('Trailer'),
              ],
            ),
          ),
        ],

        const SizedBox(width: 12),

        // More options menu
        _buildMoreOptionsMenu(item),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildMoreOptionsMenu(MediaItem item) {
    return GlassIconButton(
      icon: Icons.more_vert,
      onPressed: () => _showLiquidGlassMenu(item),
    );
  }

  void _showLiquidGlassMenu(MediaItem item) {
    final downloadTask = ref.read(downloadTaskProvider(item.id));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _LiquidGlassMenu(
        item: item,
        downloadTask: downloadTask,
        onFavorite: () => _toggleFavorite(item),
        onWatched: () => _toggleWatched(item),
        onDownload: () => _handleDownloadAction(item, downloadTask),
        onShare: () => _shareItem(item),
      ),
    );
  }

  IconData _getDownloadIcon(DownloadTask? task) {
    if (task == null) return Icons.download_outlined;
    switch (task.status) {
      case DownloadStatus.downloading:
        return Icons.downloading;
      case DownloadStatus.paused:
        return Icons.pause_circle_outline;
      case DownloadStatus.completed:
        return Icons.download_done;
      case DownloadStatus.failed:
        return Icons.refresh;
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getDownloadIconColor(DownloadTask? task) {
    if (task == null) return AppColors.textPrimary;
    switch (task.status) {
      case DownloadStatus.downloading:
        return AppColors.primary;
      case DownloadStatus.paused:
        return AppColors.accentYellow;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.error;
      default:
        return AppColors.textPrimary;
    }
  }

  String _getDownloadText(DownloadTask? task) {
    if (task == null) return 'Download';
    switch (task.status) {
      case DownloadStatus.downloading:
        return 'Downloading (${(task.progress * 100).toInt()}%)';
      case DownloadStatus.paused:
        return 'Resume Download';
      case DownloadStatus.completed:
        return 'Downloaded';
      case DownloadStatus.failed:
        return 'Retry Download';
      default:
        return 'Download Pending';
    }
  }

  void _handleDownloadAction(MediaItem item, DownloadTask? task) {
    if (task == null) {
      _downloadItem(item);
      return;
    }
    switch (task.status) {
      case DownloadStatus.downloading:
        ref.read(downloadProvider.notifier).pauseDownload(task.id);
        break;
      case DownloadStatus.paused:
      case DownloadStatus.failed:
        ref.read(downloadProvider.notifier).resumeDownload(task.id);
        break;
      case DownloadStatus.completed:
        // Already downloaded, could show options
        break;
      default:
        _downloadItem(item);
    }
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return _buildEpisodeCard(episode, serverUrl, seasonId);
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

  Widget _buildEpisodeCard(
    MediaItem episode,
    String serverUrl,
    String seasonId,
  ) {
    final isWatched = episode.isPlayed == true;

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
                  child: CachedNetworkImage(
                    imageUrl: episode.getPrimaryImageUrl(serverUrl, width: 250),
                    width: 130,
                    height: 75,
                    fit: BoxFit.cover,
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
                        size: 12,
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
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                      minHeight: 3,
                    ),
                  ),
                // Play icon
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

          const SizedBox(width: 12),

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
                        size: 14,
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

          // Mark watched button
          IconButton(
            icon: Icon(
              isWatched ? Icons.visibility_off : Icons.visibility,
              color: isWatched ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () => _toggleEpisodeWatched(episode, seasonId),
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
              separatorBuilder: (_, _) => const SizedBox(width: 12),
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
                separatorBuilder: (_, _) => const SizedBox(width: 12),
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MobilePlayer()));
  }

  void _playTrailer(MediaItem item) {
    // TODO: Implement trailer playback
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

  void _downloadItem(MediaItem item) {
    final downloadState = ref.read(downloadProvider);
    final existingTask = downloadState.getTaskForItem(item.id);

    if (existingTask != null) {
      // Show options for existing download
      _showDownloadOptions(existingTask);
    } else {
      // Start new download
      ref.read(downloadProvider.notifier).downloadItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading "${item.name}"'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _showDownloadsSheet(),
          ),
        ),
      );
    }
  }

  void _showDownloadOptions(DownloadTask task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.itemName, style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Status: ${_getStatusText(task.status)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (task.status == DownloadStatus.downloading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: task.progress,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${task.formattedDownloadedSize} / ${task.formattedSize}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (task.status == DownloadStatus.downloading)
              ListTile(
                leading: const Icon(Icons.pause),
                title: const Text('Pause Download'),
                onTap: () {
                  ref.read(downloadProvider.notifier).pauseDownload(task.id);
                  Navigator.pop(context);
                },
              ),
            if (task.canResume)
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Resume Download'),
                onTap: () {
                  ref.read(downloadProvider.notifier).resumeDownload(task.id);
                  Navigator.pop(context);
                },
              ),
            if (task.status == DownloadStatus.completed)
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Play Downloaded'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Play from local file
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Delete Download',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                ref.read(downloadProvider.notifier).deleteDownload(task.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return 'Waiting...';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Downloaded';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _showDownloadsSheet() {
    // Navigate to downloads page
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _DownloadsPage()));
  }

  void _shareItem(MediaItem item) {
    // TODO: Implement share
  }
}

/// Downloads page
class _DownloadsPage extends ConsumerWidget {
  const _DownloadsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          if (downloadState.downloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showDeleteAllDialog(context, ref),
            ),
        ],
      ),
      body: downloadState.downloads.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text('No Downloads', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Downloaded content will appear here',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: downloadState.downloads.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = downloadState.downloads[index];
                return _DownloadTile(task: task, serverUrl: serverUrl);
              },
            ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Downloads'),
        content: const Text(
          'Are you sure you want to delete all downloads? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(downloadProvider.notifier).deleteAllDownloads();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  final DownloadTask task;
  final String serverUrl;

  const _DownloadTile({required this.task, required this.serverUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              task.getImageUrl(serverUrl),
              width: 60,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 60,
                height: 90,
                color: AppColors.surface,
                child: const Icon(Icons.movie),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.itemName,
                  style: AppTextStyles.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusText(task.status),
                  style: AppTextStyles.caption.copyWith(
                    color: _getStatusColor(task.status),
                  ),
                ),
                if (task.status == DownloadStatus.downloading) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.formattedDownloadedSize} / ${task.formattedSize}',
                    style: AppTextStyles.caption,
                  ),
                ],
                if (task.status == DownloadStatus.completed)
                  Text(task.formattedSize, style: AppTextStyles.caption),
              ],
            ),
          ),
          // Action button
          _buildActionButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    switch (task.status) {
      case DownloadStatus.downloading:
        return IconButton(
          icon: const Icon(Icons.pause),
          onPressed: () =>
              ref.read(downloadProvider.notifier).pauseDownload(task.id),
        );
      case DownloadStatus.paused:
      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () =>
              ref.read(downloadProvider.notifier).resumeDownload(task.id),
        );
      case DownloadStatus.completed:
        return PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: ListTile(
                leading: Icon(Icons.play_circle_outline),
                title: Text('Play'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Delete', style: TextStyle(color: AppColors.error)),
                dense: true,
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              ref.read(downloadProvider.notifier).deleteDownload(task.id);
            }
            // TODO: Handle play
          },
        );
      default:
        return IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              ref.read(downloadProvider.notifier).deleteDownload(task.id),
        );
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return 'Waiting...';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Downloaded';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return AppColors.primary;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.error;
      case DownloadStatus.paused:
        return AppColors.accentYellow;
      default:
        return AppColors.textSecondary;
    }
  }
}
