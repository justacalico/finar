import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/player_backend.dart' show playerBackendProvider;

import '../core/models/models.dart';
import '../core/playback/playback_reporter.dart';
import 'session_provider.dart';

class TrackOption {
  const TrackOption({required this.index, required this.label});

  final int index;
  final String label;
}

class PlayerState {
  const PlayerState({
    this.item,
    this.queue = const [],
    this.queueIndex = 0,
    this.playing = false,
    this.buffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100,
    this.rate = 1,
    this.subtitleTrack,
    this.audioTrack,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.localFile,
  });

  final BaseItem? item;
  final List<BaseItem> queue;
  final int queueIndex;
  final bool playing;
  final bool buffering;
  final Duration position;
  final Duration duration;
  final double volume;
  final double rate;
  final int? subtitleTrack;
  final int? audioTrack;
  final List<TrackOption> audioTracks;
  final List<TrackOption> subtitleTracks;
  final String? localFile;

  BaseItem? get nextItem =>
      queueIndex + 1 < queue.length ? queue[queueIndex + 1] : null;

  PlayerState copyWith({
    BaseItem? item,
    List<BaseItem>? queue,
    int? queueIndex,
    bool? playing,
    bool? buffering,
    Duration? position,
    Duration? duration,
    double? volume,
    double? rate,
    int? Function()? subtitleTrack,
    int? Function()? audioTrack,
    List<TrackOption>? audioTracks,
    List<TrackOption>? subtitleTracks,
    String? Function()? localFile,
  }) =>
      PlayerState(
        item: item ?? this.item,
        queue: queue ?? this.queue,
        queueIndex: queueIndex ?? this.queueIndex,
        playing: playing ?? this.playing,
        buffering: buffering ?? this.buffering,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        volume: volume ?? this.volume,
        rate: rate ?? this.rate,
        subtitleTrack: subtitleTrack != null
            ? subtitleTrack()
            : this.subtitleTrack,
        audioTrack:
            audioTrack != null ? audioTrack() : this.audioTrack,
        audioTracks: audioTracks ?? this.audioTracks,
        subtitleTracks: subtitleTracks ?? this.subtitleTracks,
        localFile: localFile != null ? localFile() : this.localFile,
      );
}

abstract class PlayerBackend {
  Stream<Duration> get position;
  Stream<Duration> get duration;
  Stream<bool> get playing;
  Stream<bool> get buffering;
  Stream<double> get volume;
  Stream<double> get rate;
  Stream<bool> get completed;

  Future<void> open(Uri uri, {Duration? startAt, String? localFile});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setRate(double rate);
  Future<void> setSubtitleTrack(int? streamIndex);
  Future<void> setAudioTrack(int? streamIndex);
  Widget buildVideo(BuildContext context);
  Future<void> dispose();
}



final playerProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);

class PlayerNotifier extends Notifier<PlayerState> {
  PlaybackReporter? _reporter;
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  PlayerState build() {
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _reporter?.stop();
    });
    final backend = ref.watch(playerBackendProvider);
    _subs.addAll([
      backend.position.listen((p) {
        state = state.copyWith(position: p);
        _reporter?.updatePosition(p);
      }),
      backend.duration.listen((d) => state = state.copyWith(duration: d)),
      backend.playing.listen((p) {
        state = state.copyWith(playing: p);
        _reporter?.setPaused(!p);
      }),
      backend.buffering
          .listen((b) => state = state.copyWith(buffering: b)),
      backend.volume.listen((v) => state = state.copyWith(volume: v)),
      backend.rate.listen((r) => state = state.copyWith(rate: r)),
      backend.completed.listen((done) {
        if (done) _onCompleted();
      }),
    ]);
    return const PlayerState();
  }

  PlayerBackend get _backend => ref.read(playerBackendProvider);

  PlaybackReporter? _reporterFor() {
    final client = ref.read(jellyfinClientProvider);
    if (client == null) return null;
    return _reporter ??= PlaybackReporter(client);
  }

  Future<void> playItem(BaseItem item,
      {List<BaseItem>? queue,
      int queueIndex = 0,
      Duration? startAt,
      String? localFile}) async {
    final client = ref.read(jellyfinClientProvider);
    final uri = localFile != null
        ? Uri.file(localFile)
        : client?.streamUrl(item.id, isAudio: item.isAudio) ??
            Uri.parse('about:blank');
    state = state.copyWith(
      item: item,
      queue: queue ?? [item],
      queueIndex: queueIndex,
      position: Duration.zero,
      duration: Duration.zero,
      playing: false,
      subtitleTrack: () => null,
      audioTrack: () => null,
      localFile: () => localFile,
      audioTracks: [
        for (final s in item.mediaSources.expand((m) => m.mediaStreams))
          if (s.isAudio) TrackOption(index: s.index, label: s.label),
        for (final s in item.mediaStreams)
          if (s.isAudio) TrackOption(index: s.index, label: s.label),
      ],
      subtitleTracks: [
        for (final s in item.mediaSources.expand((m) => m.mediaStreams))
          if (s.isSubtitle) TrackOption(index: s.index, label: s.label),
        for (final s in item.mediaStreams)
          if (s.isSubtitle) TrackOption(index: s.index, label: s.label),
      ],
    );
    await _backend.open(uri,
        startAt: item.userData.playbackPositionTicks > 0 && startAt == null
            ? Duration(microseconds:
                item.userData.playbackPositionTicks ~/ 10)
            : startAt,
        localFile: localFile);
    await _backend.play();
    _reporterFor()?.start(item,
        positionTicks: item.userData.playbackPositionTicks);
  }

  Future<void> playQueue(List<BaseItem> queue, int index,
          {Duration? startAt}) =>
      playItem(queue[index], queue: queue, queueIndex: index, startAt: startAt);

  Future<void> next() async {
    final next = state.queueIndex + 1;
    if (next < state.queue.length) {
      await playQueue(state.queue, next);
    }
  }

  Future<void> previous() async {
    final prev = state.queueIndex - 1;
    if (prev >= 0) {
      await playQueue(state.queue, prev);
    }
  }

  void _onCompleted() {
    _reporter?.stop(position: state.position);
    if (state.nextItem != null) {
      next();
    } else {
      state = state.copyWith(playing: false);
    }
  }

  Future<void> toggle() => state.playing ? pause() : resume();

  Future<void> pause() => _backend.pause();
  Future<void> resume() => _backend.play();
  Future<void> seek(Duration position) => _backend.seek(position);
  Future<void> seekBy(Duration delta) =>
      _backend.seek(state.position + delta);
  Future<void> setVolume(double volume) => _backend.setVolume(volume);
  Future<void> setRate(double rate) => _backend.setRate(rate);

  Future<void> selectSubtitle(int? streamIndex) async {
    state = state.copyWith(subtitleTrack: () => streamIndex);
    await _backend.setSubtitleTrack(streamIndex);
  }

  Future<void> selectAudio(int? streamIndex) async {
    state = state.copyWith(audioTrack: () => streamIndex);
    await _backend.setAudioTrack(streamIndex);
  }

  Future<void> stop() async {
    _reporter?.stop(position: state.position);
    state = const PlayerState();
  }
}
