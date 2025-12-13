import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/models/media_item.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';
import 'tv_player.dart';

class TvDetail extends ConsumerStatefulWidget {
  final String itemId;

  const TvDetail({
    super.key,
    required this.itemId,
  });

  @override
  ConsumerState<TvDetail> createState() => _TvDetailState();
}

class _TvDetailState extends ConsumerState<TvDetail> {
  final FocusNode _focusNode = FocusNode();
  int _selectedButtonIndex = 0;
  int _selectedSeasonIndex = 0;
  int _selectedEpisodeIndex = 0;
  bool _inEpisodeSelection = false;

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
          data: (item) => _buildContent(item, serverUrl),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => Center(
            child: Text('Error: $error'),
          ),
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
                        errorBuilder: (_, __, ___) => Text(
                          item.name,
                          style: AppTextStyles.displayMedium,
                        ),
                      )
                    else
                      Text(
                        item.name,
                        style: AppTextStyles.displayMedium,
                      ),

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
              Expanded(
                flex: 4,
                child: _buildEpisodesPanel(item, serverUrl),
              ),
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
          errorBuilder: (_, __, ___) => Container(color: AppColors.background),
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
              colors: [
                AppColors.background,
                Colors.transparent,
              ],
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
            child: Text(
              item.officialRating!,
              style: AppTextStyles.labelMedium,
            ),
          ),
        if (item.formattedRuntime.isNotEmpty)
          Text(
            item.formattedRuntime,
            style: AppTextStyles.titleMedium,
          ),
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
        icon: item.isPlayed == true ? Icons.check_circle : Icons.check_circle_outline,
        label: 'Watched',
        onPressed: () => _toggleWatched(item),
      ),
    ];

    return Row(
      children: buttons.asMap().entries.map((entry) {
        final index = entry.key;
        final button = entry.value;
        final isSelected = !_inEpisodeSelection && _selectedButtonIndex == index;

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
              error: (_, __) => const SizedBox.shrink(),
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
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                border: _inEpisodeSelection &&
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
        itemCount: episodes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final episode = episodes[index];
          final isSelected =
              _inEpisodeSelection && _selectedEpisodeIndex == index;
          return _buildEpisodeCard(episode, serverUrl, isSelected);
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
  ) {
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
                  Image.network(
                    episode.getPrimaryImageUrl(serverUrl, width: 300),
                    width: 160,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 160,
                      height: 90,
                      color: AppColors.surface,
                      child: const Icon(Icons.movie),
                    ),
                  ),
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

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'E${episode.indexNumber} - ${episode.name}',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
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

    setState(() {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          if (_inEpisodeSelection && _selectedEpisodeIndex > 0) {
            _selectedEpisodeIndex--;
          } else if (_inEpisodeSelection && _selectedEpisodeIndex == 0) {
            _selectedEpisodeIndex = -1; // Season tabs
          }
          break;

        case LogicalKeyboardKey.arrowDown:
          if (_inEpisodeSelection) {
            if (_selectedEpisodeIndex == -1) {
              _selectedEpisodeIndex = 0;
            } else {
              _selectedEpisodeIndex++;
            }
          }
          break;

        case LogicalKeyboardKey.arrowLeft:
          if (_inEpisodeSelection) {
            if (_selectedEpisodeIndex == -1 && _selectedSeasonIndex > 0) {
              _selectedSeasonIndex--;
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
            }
          } else if (!_inEpisodeSelection) {
            if (_selectedButtonIndex < buttonCount - 1) {
              _selectedButtonIndex++;
            } else if (isSeries) {
              _inEpisodeSelection = true;
              _selectedEpisodeIndex = 0;
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
    ref.read(playerProvider.notifier).play(item);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TvPlayer(),
      ),
    );
  }

  void _toggleFavorite(MediaItem item) {
    ref.read(mediaActionsProvider).toggleFavorite(item.id, !(item.isFavorite == true));
  }

  void _toggleWatched(MediaItem item) {
    ref.read(mediaActionsProvider).toggleWatched(item.id, !(item.isPlayed == true));
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
