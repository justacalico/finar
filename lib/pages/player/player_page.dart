import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/player_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/media_image.dart';

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  bool _controlsVisible = true;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _poke() {
    setState(() => _controlsVisible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final notifier = ref.read(playerProvider.notifier);
    if (event.logicalKey == LogicalKeyboardKey.space) {
      notifier.toggle();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      notifier.seekBy(const Duration(seconds: -10));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      notifier.seekBy(const Duration(seconds: 10));
    }
    _poke();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final player = ref.watch(playerProvider);
    final item = player.item;
    final backend = ref.watch(playerBackendProvider);
    final isAudio = item?.isAudio ?? false;

    if (item == null) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => context.pop(),
            child: Text(l10n.back),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          _handleKey(event);
          return KeyEventResult.handled;
        },
        child: GestureDetector(
          onTap: _poke,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isAudio)
                _AudioBackdrop(item: item)
              else
                backend.buildVideo(context),
              AnimatedOpacity(
                opacity: _controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: _ControlsOverlay(
                  isAudio: isAudio,
                  onBack: () {
                    ref.read(playerProvider.notifier).stop();
                    context.pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioBackdrop extends ConsumerWidget {
  const _AudioBackdrop({required this.item});

  final BaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(jellyfinClientProvider);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.35),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: MediaImage(
                url: client?.primaryImageUrl(item, maxWidth: 440),
                icon: Icons.music_note,
                borderRadius: 18,
              ),
            ),
            const SizedBox(height: 20),
            Text(item.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(item.albumArtist ?? item.seriesName ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _ControlsOverlay extends ConsumerWidget {
  const _ControlsOverlay({required this.isAudio, required this.onBack});

  final bool isAudio;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final player = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final item = player.item!;
    final position = player.position;
    final duration = player.duration;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.75),
          ],
          stops: const [0, 0.2, 0.7, 1],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white),
                    tooltip: l10n.back,
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        if (item.seriesName != null ||
                            item.albumArtist != null)
                          Text(
                            item.seriesName ??
                                item.albumArtist ??
                                '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  _TrackMenu(
                    icon: Icons.subtitles_outlined,
                    tooltip: l10n.subtitles,
                    tracks: player.subtitleTracks,
                    active: player.subtitleTrack,
                    allowOff: true,
                    offLabel: l10n.noSubtitles,
                    onSelected: notifier.selectSubtitle,
                  ),
                  _TrackMenu(
                    icon: Icons.audiotrack_outlined,
                    tooltip: l10n.audio,
                    tracks: player.audioTracks,
                    active: player.audioTrack,
                    allowOff: false,
                    onSelected: notifier.selectAudio,
                  ),
                  _SpeedMenu(
                    rate: player.rate,
                    label: l10n.playbackSpeed,
                    onSelected: notifier.setRate,
                  ),
                  if (player.queue.length > 1)
                    IconButton(
                      icon: const Icon(Icons.queue_music,
                          color: Colors.white),
                      tooltip: l10n.queue,
                      onPressed: () => _showQueue(context, ref, l10n),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (player.queueIndex > 0)
                  IconButton(
                    icon: const Icon(Icons.skip_previous,
                        color: Colors.white, size: 34),
                    onPressed: notifier.previous,
                  ),
                IconButton(
                  icon: const Icon(Icons.replay_10,
                      color: Colors.white, size: 30),
                  tooltip: l10n.seekBack,
                  onPressed: () => notifier
                      .seekBy(const Duration(seconds: -10)),
                ),
                const SizedBox(width: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: notifier.toggle,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: player.buffering
                        ? const Padding(
                            padding: EdgeInsets.all(22),
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2),
                          )
                        : Icon(
                            player.playing
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 40),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.forward_10,
                      color: Colors.white, size: 30),
                  tooltip: l10n.seekForward,
                  onPressed: () => notifier
                      .seekBy(const Duration(seconds: 10)),
                ),
                if (player.nextItem != null)
                  IconButton(
                    icon: const Icon(Icons.skip_next,
                        color: Colors.white, size: 34),
                    onPressed: notifier.next,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(formatDuration(position),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(
                                enabledThumbRadius: 7),
                        overlayShape:
                            const RoundSliderOverlayShape(
                                overlayRadius: 14),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: duration.inMilliseconds == 0
                            ? null
                            : (v) => notifier.seek(Duration(
                                milliseconds: (v *
                                        duration
                                            .inMilliseconds)
                                    .round())),
                      ),
                    ),
                  ),
                  Text(
                    '-${formatDuration(duration - position)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showQueue(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final player = ref.read(playerProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l10n.queue,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: player.queue.length,
                itemBuilder: (context, i) {
                  final queued = player.queue[i];
                  return ListTile(
                    dense: true,
                    selected: i == player.queueIndex,
                    leading: i == player.queueIndex
                        ? const Icon(Icons.play_arrow)
                        : Text('${i + 1}'),
                    title: Text(queued.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: queued.albumArtist == null
                        ? null
                        : Text(queued.albumArtist!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    onTap: () {
                      ref
                          .read(playerProvider.notifier)
                          .playQueue(player.queue, i);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackMenu extends StatelessWidget {
  const _TrackMenu({
    required this.icon,
    required this.tooltip,
    required this.tracks,
    required this.active,
    required this.onSelected,
    this.allowOff = false,
    this.offLabel,
  });

  final IconData icon;
  final String tooltip;
  final List<TrackOption> tracks;
  final int? active;
  final ValueChanged<int?> onSelected;
  final bool allowOff;
  final String? offLabel;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty && !allowOff) return const SizedBox.shrink();
    return PopupMenuButton<int?>(
      icon: Icon(icon, color: Colors.white),
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: (context) => [
        if (allowOff)
          CheckedPopupMenuItem(
            value: null,
            checked: active == null,
            child: Text(offLabel ?? 'Off'),
          ),
        for (final track in tracks)
          CheckedPopupMenuItem(
            value: track.index,
            checked: active == track.index,
            child: Text(track.label),
          ),
      ],
    );
  }
}

class _SpeedMenu extends StatelessWidget {
  const _SpeedMenu(
      {required this.rate,
      required this.label,
      required this.onSelected});

  final double rate;
  final String label;
  final ValueChanged<double> onSelected;

  static const _rates = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      icon: const Icon(Icons.speed, color: Colors.white),
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final r in _rates)
          CheckedPopupMenuItem(
            value: r,
            checked: rate == r,
            child: Text('${r}x'),
          ),
      ],
    );
  }
}
