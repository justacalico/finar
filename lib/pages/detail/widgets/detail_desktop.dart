import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/services/controller_service.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/pages/adaptive_pages.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import 'detail_album_tracks.dart';
import 'detail_artist_albums_section.dart';
import 'detail_desktop_background.dart';
import 'detail_desktop_cast.dart';
import 'detail_desktop_download.dart';
import 'detail_desktop_hero.dart';
import 'detail_desktop_info.dart';
import 'detail_episodes_section.dart';
import 'detail_error_view.dart';
import 'detail_loading_view.dart';
import 'detail_more_options_sheet.dart';
import 'detail_similar_section.dart';
import 'package:finar/core/utils/media_actions.dart';

class DetailDesktop extends ConsumerStatefulWidget {
  final String itemId;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const DetailDesktop({
    super.key,
    required this.itemId,
    this.initialSeasonId,
    this.initialEpisodeId,
  });

  @override
  ConsumerState<DetailDesktop> createState() => _DetailDesktopState();
}

class _DetailDesktopState extends ConsumerState<DetailDesktop> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _mainFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus when the page is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainFocusNode.requestFocus();
    });
  }

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

    // Handle scrolling with up/down when no focusable element has focus
    // This allows scrolling the page content with the controller
    if (action == ControllerAction.up) {
      _scrollController.animateTo(
        (_scrollController.offset - 100).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
      // Don't return handled - let focus system also try to move focus
    }

    if (action == ControllerAction.down) {
      _scrollController.animateTo(
        (_scrollController.offset + 100).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
      // Don't return handled - let focus system also try to move focus
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
                builder: (_) => AdaptiveDetailPage(itemId: item.albumId!),
              ),
            );
          });
          return const DetailLoadingView();
        }

        // If this is an episode, redirect to the parent series detail.
        if (item.type == MediaType.episode && item.seriesId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => AdaptiveDetailPage(
                  itemId: item.seriesId!,
                  initialSeasonId: item.seasonId,
                  initialEpisodeId: item.id,
                ),
              ),
            );
          });
          return const DetailLoadingView();
        }

        return _buildContent(item, serverUrl);
      },
      loading: () => const DetailLoadingView(),
      error: (error, stack) => DetailErrorView(
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
            DetailDesktopBackground(item: item, serverUrl: serverUrl),

            // Content
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Hero section with backdrop
                SliverToBoxAdapter(
                  child: DetailHeroSection(
                    item: item,
                    serverUrl: serverUrl,
                    onMoreOptions: _showMoreOptions,
                  ),
                ),

                // Info section
                if (item.overview != null ||
                    item.studios?.isNotEmpty == true ||
                    item.productionYear != null ||
                    item.container != null ||
                    item.mediaStreams?.isNotEmpty == true)
                  SliverToBoxAdapter(child: DetailInfoSection(item: item)),

                // Episodes (for TV Shows)
                if (item.type == MediaType.series)
                  SliverToBoxAdapter(
                    child: DetailEpisodesSection(
                      item: item,
                      serverUrl: serverUrl,
                      initialSeasonId: widget.initialSeasonId,
                      initialEpisodeId: widget.initialEpisodeId,
                    ),
                  ),

                // Album Tracks (for Music Albums) — virtualized
                if (item.type == MediaType.album)
                  ...albumTracksSlivers(ref, item, serverUrl),

                // Artist Albums (for Music Artists)
                if (item.type == MediaType.artist)
                  SliverToBoxAdapter(
                    child: DetailArtistAlbumsSection(
                      artistId: item.id,
                      serverUrl: serverUrl,
                      isDesktop: true,
                    ),
                  ),

                // Cast & Crew
                if (item.people?.isNotEmpty == true)
                  SliverToBoxAdapter(
                    child: DetailCastSection(item: item, serverUrl: serverUrl),
                  ),

                // Similar Items — section widget so only this rebuilds when similar loads
                SliverToBoxAdapter(
                  child: DetailSimilarSection(
                    itemId: item.id,
                    serverUrl: serverUrl,
                    isDesktop: true,
                  ),
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

  void _showMoreOptions(MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DetailMoreOptionsSheet(
        item: item,
        onDownload: () => downloadDetailItem(ref, context, item),
        onShare: () => shareMediaItem(item),
        onMediaInfo: () => _showMediaInfoDialog(item),
        onAddToPlaylist: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add to playlist coming soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onReportIssue: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report issue coming soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showMediaInfoDialog(MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(item.name, style: AppTextStyles.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.productionYear != null)
                Text(
                  'Year: ${item.productionYear}',
                  style: AppTextStyles.bodyMedium,
                ),
              ...[
                const SizedBox(height: 8),
                Text(
                  'Runtime: ${item.formattedRuntime}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
              if (item.overview?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(item.overview!, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
