import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../core/api/format.dart';
import '../core/api/jellyfin_client.dart';
import '../core/api/models.dart';
import 'downloads_provider.dart';
import 'providers.dart';
import 'settings_provider.dart';

/// Resolved playback target for an item.
class StreamChoice {
  final String url;
  final String? mediaSourceId;
  final String? playSessionId;
  final bool directPlay;
  final List<MediaStream> audioStreams;
  final List<MediaStream> subtitleStreams;

  const StreamChoice({
    required this.url,
    this.mediaSourceId,
    this.playSessionId,
    this.directPlay = true,
    this.audioStreams = const [],
    this.subtitleStreams = const [],
  });
}

/// Decide how to play [item]: prefer a local download, then direct play,
/// falling back to HLS transcoding when the source needs it.
StreamChoice resolveStream(
  JellyfinClient client,
  MediaItem item,
  PlaybackInfo info, {
  String? localPath,
  int maxBitrate = 0,
  int startTimeTicks = 0,
}) {
  if (localPath != null) {
    return StreamChoice(
      url: localPath,
      directPlay: true,
      mediaSourceId: item.mediaSources.firstOrNull?.id,
      audioStreams: item.mediaSources.firstOrNull?.audioStreams ?? const [],
      subtitleStreams:
          item.mediaSources.firstOrNull?.subtitleStreams ?? const [],
    );
  }

  final source = info.mediaSources.firstOrNull;
  if (source != null && !source.supportsDirectPlay) {
    return StreamChoice(
      url: client.hlsUrl(
        item.id,
        mediaSourceId: source.id,
        playSessionId: info.playSessionId,
        maxBitrate: maxBitrate > 0 ? maxBitrate : null,
        startTimeTicks: startTimeTicks > 0 ? startTimeTicks : null,
      ),
      mediaSourceId: source.id,
      playSessionId: info.playSessionId,
      directPlay: false,
      audioStreams: source.audioStreams,
      subtitleStreams: source.subtitleStreams,
    );
  }

  final sourceId = source?.id;
  return StreamChoice(
    url: client.streamUrl(
      item.id,
      mediaSourceId: sourceId,
      startTimeTicks: startTimeTicks > 0 ? startTimeTicks : null,
    ),
    mediaSourceId: sourceId,
    playSessionId: info.playSessionId,
    directPlay: true,
    audioStreams: source?.audioStreams ?? const [],
    subtitleStreams: source?.subtitleStreams ?? const [],
  );
}

/// Pick the initial audio stream index honouring the preferred language.
int? preferredAudioIndex(List<MediaStream> streams, String language) {
  if (streams.isEmpty) return null;
  if (language.isNotEmpty) {
    for (final s in streams) {
      if (s.language == language) return s.index;
    }
  }
  for (final s in streams) {
    if (s.isDefault) return s.index;
  }
  return streams.first.index;
}

/// Pick the initial subtitle index honouring preferences. -1 = none.
int preferredSubtitleIndex(
    List<MediaStream> streams, String language, bool enabled) {
  if (!enabled || streams.isEmpty) return -1;
  if (language.isNotEmpty) {
    for (final s in streams) {
      if (s.language == language) return s.index;
    }
  }
  for (final s in streams) {
    if (s.isDefault || s.isForced) return s.index;
  }
  return -1;
}

class VideoState {
  final MediaItem item;
  final Player? player;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final bool playing;
  final bool buffering;
  final int? audioIndex;
  final int? subtitleIndex;
  final List<MediaStream> audioStreams;
  final List<MediaStream> subtitleStreams;
  final double speed;

  const VideoState({
    required this.item,
    this.player,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.playing = false,
    this.buffering = true,
    this.audioIndex,
    this.subtitleIndex,
    this.audioStreams = const [],
    this.subtitleStreams = const [],
    this.speed = 1.0,
  });

  VideoState copyWith({
    Duration? position,
    Duration? duration,
    Duration? buffered,
    bool? playing,
    bool? buffering,
    int? audioIndex,
    int? subtitleIndex,
    double? speed,
  }) =>
      VideoState(
        item: item,
        player: player,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        buffered: buffered ?? this.buffered,
        playing: playing ?? this.playing,
        buffering: buffering ?? this.buffering,
        audioIndex: audioIndex ?? this.audioIndex,
        subtitleIndex: subtitleIndex ?? this.subtitleIndex,
        audioStreams: audioStreams,
        subtitleStreams: subtitleStreams,
        speed: speed ?? this.speed,
      );
}

/// Owns the media_kit [Player] for the currently playing item, plus
/// Jellyfin progress reporting.
class VideoPlayerNotifier extends Notifier<VideoState?> {
  Timer? _reportTimer;
  StreamChoice? _choice;

  @override
  VideoState? build() => null;

  Future<void> play(MediaItem item,
      {int startTimeTicks = 0, List<MediaItem>? upNext}) async {
    await stop();
    final client = ref.read(jellyfinClientProvider);
    final settings = ref.read(settingsProvider);
    final localPath =
        ref.read(downloadsProvider.notifier).localPathFor(item.id);

    PlaybackInfo info = const PlaybackInfo();
    if (localPath == null) {
      try {
        info = await client.getPlaybackInfo(
          item.id,
          startTimeTicks: startTimeTicks > 0 ? startTimeTicks : null,
          maxStreamingBitrate: settings.maxStreamingBitrate > 0
              ? settings.maxStreamingBitrate
              : null,
        );
      } catch (_) {}
    }

    _choice = resolveStream(client, item, info,
        localPath: localPath,
        maxBitrate: settings.maxStreamingBitrate,
        startTimeTicks: startTimeTicks);

    final player = Player();
    state = VideoState(
      item: item,
      player: player,
      buffering: true,
      audioStreams: _choice!.audioStreams,
      subtitleStreams: _choice!.subtitleStreams,
      audioIndex: preferredAudioIndex(
          _choice!.audioStreams, settings.preferredAudioLanguage),
      subtitleIndex: preferredSubtitleIndex(_choice!.subtitleStreams,
          settings.preferredSubtitleLanguage, settings.subtitlesEnabled),
    );

    player.stream.playing
        .listen((v) => _update((s) => s.copyWith(playing: v)));
    player.stream.position
        .listen((v) => _update((s) => s.copyWith(position: v)));
    player.stream.duration
        .listen((v) => _update((s) => s.copyWith(duration: v)));
    player.stream.buffer
        .listen((v) => _update((s) => s.copyWith(buffered: v)));
    player.stream.buffering
        .listen((v) => _update((s) => s.copyWith(buffering: v)));

    try {
      await player.open(Media(_choice!.url,
          start: startTimeTicks > 0
              ? ticksToDuration(startTimeTicks)
              : null));
      client
          .reportStart(item.id,
              mediaSourceId: _choice!.mediaSourceId,
              playSessionId: _choice!.playSessionId,
              positionTicks: startTimeTicks)
          .catchError((_) {});
      _reportTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        final s = state;
        if (s == null) return;
        client
            .reportProgress(item.id,
                mediaSourceId: _choice!.mediaSourceId,
                playSessionId: _choice!.playSessionId,
                positionTicks: durationToTicks(s.position),
                isPaused: !s.playing)
            .catchError((_) {});
      });
    } catch (_) {
      _update((s) => s.copyWith(buffering: false));
    }
  }

  void _update(VideoState Function(VideoState) fn) {
    final s = state;
    if (s != null) state = fn(s);
  }

  Future<void> toggle() async {
    final p = state?.player;
    if (p != null) await p.playOrPause();
  }

  Future<void> seek(Duration position) async {
    final p = state?.player;
    if (p != null) await p.seek(position);
  }

  Future<void> seekBy(Duration offset) async {
    final s = state;
    if (s == null) return;
    var target = s.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (s.duration > Duration.zero && target > s.duration) {
      target = s.duration;
    }
    await s.player?.seek(target);
  }

  Future<void> setSpeed(double speed) async {
    await state?.player?.setRate(speed);
    _update((s) => s.copyWith(speed: speed));
  }

  Future<void> selectAudio(int index) async {
    _update((v) => v.copyWith(audioIndex: index));
  }

  Future<void> selectSubtitle(int index) async {
    _update((v) => v.copyWith(subtitleIndex: index));
  }

  Future<void> stop() async {
    _reportTimer?.cancel();
    _reportTimer = null;
    final s = state;
    if (s != null) {
      final client = ref.read(jellyfinClientProvider);
      client
          .reportStop(s.item.id,
              mediaSourceId: _choice?.mediaSourceId,
              playSessionId: _choice?.playSessionId,
              positionTicks: durationToTicks(s.position))
          .catchError((_) {});
      await s.player?.dispose();
    }
    _choice = null;
    state = null;
  }
}

final videoPlayerProvider =
    NotifierProvider<VideoPlayerNotifier, VideoState?>(VideoPlayerNotifier.new);
