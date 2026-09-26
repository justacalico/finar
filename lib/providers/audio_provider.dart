import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../core/api/models.dart';
import 'playback_provider.dart';
import 'providers.dart';

/// Pure queue model: ordering, shuffle, next/previous resolution.
/// Kept separate from the media_kit player so it is fully unit-testable.
class PlayQueue {
  final List<MediaItem> tracks;
  final int index;
  final bool shuffle;
  final List<int> _shuffleOrder;
  final int _shufflePos;

  const PlayQueue._(
    this.tracks,
    this.index,
    this.shuffle,
    this._shuffleOrder,
    this._shufflePos,
  );

  factory PlayQueue(
    List<MediaItem> tracks,
    int startIndex, {
    bool shuffle = false,
    Random? random,
  }) {
    if (tracks.isEmpty) {
      return const PlayQueue._([], -1, false, [], -1);
    }
    final start = startIndex.clamp(0, tracks.length - 1);
    var order = <int>[];
    var pos = -1;
    if (shuffle) {
      order = List.generate(tracks.length, (i) => i)
        ..remove(start)
        ..shuffle(random ?? Random());
      order.insert(0, start);
      pos = 0;
    }
    return PlayQueue._(tracks, start, shuffle, order, pos);
  }

  bool get isEmpty => tracks.isEmpty;
  MediaItem? get current =>
      index >= 0 && index < tracks.length ? tracks[index] : null;
  bool get hasNext => nextIndex() != null;
  bool get hasPrevious => previousIndex() != null;

  int? nextIndex() {
    if (!shuffle) {
      return index + 1 < tracks.length ? index + 1 : null;
    }
    return _shufflePos + 1 < _shuffleOrder.length
        ? _shuffleOrder[_shufflePos + 1]
        : null;
  }

  int? previousIndex() {
    if (!shuffle) {
      return index - 1 >= 0 ? index - 1 : null;
    }
    return _shufflePos > 0 ? _shuffleOrder[_shufflePos - 1] : null;
  }

  PlayQueue advance() {
    final next = nextIndex();
    if (next == null) return this;
    return PlayQueue._(
      tracks,
      next,
      shuffle,
      _shuffleOrder,
      shuffle ? _shufflePos + 1 : _shufflePos,
    );
  }

  PlayQueue back() {
    final prev = previousIndex();
    if (prev == null) return this;
    return PlayQueue._(
      tracks,
      prev,
      shuffle,
      _shuffleOrder,
      shuffle ? _shufflePos - 1 : _shufflePos,
    );
  }

  PlayQueue toggleShuffle({Random? random}) {
    if (!shuffle) {
      final order = List.generate(tracks.length, (i) => i)
        ..remove(index)
        ..shuffle(random ?? Random());
      order.insert(0, index);
      return PlayQueue._(tracks, index, true, order, 0);
    }
    return PlayQueue._(tracks, index, false, const [], -1);
  }

  PlayQueue jumpTo(int i) {
    if (i < 0 || i >= tracks.length) return this;
    return PlayQueue._(tracks, i, shuffle, _shuffleOrder, _shufflePos);
  }
}

class AudioState {
  final PlayQueue queue;
  final bool playing;
  final bool loading;
  final Duration position;
  final Duration duration;

  const AudioState({
    this.queue = const PlayQueue._([], -1, false, [], -1),
    this.playing = false,
    this.loading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  MediaItem? get current => queue.current;

  AudioState copyWith({
    PlayQueue? queue,
    bool? playing,
    bool? loading,
    Duration? position,
    Duration? duration,
  }) => AudioState(
    queue: queue ?? this.queue,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    position: position ?? this.position,
    duration: duration ?? this.duration,
  );
}

class AudioPlayerNotifier extends Notifier<AudioState> {
  Player? _player;

  @override
  AudioState build() {
    ref.onDispose(() {
      _player?.dispose();
      _player = null;
    });
    return const AudioState();
  }

  Player get player => _player ??= _createPlayer();

  Player _createPlayer() {
    final p = Player();
    p.stream.playing.listen((v) => state = state.copyWith(playing: v));
    p.stream.position.listen((v) => state = state.copyWith(position: v));
    p.stream.duration.listen((v) => state = state.copyWith(duration: v));
    p.stream.completed.listen((v) {
      if (v) _onTrackEnd();
    });
    return p;
  }

  Future<void> playTracks(
    List<MediaItem> tracks,
    int startIndex, {
    bool shuffle = false,
  }) async {
    if (tracks.isEmpty) return;
    final queue = PlayQueue(tracks, startIndex, shuffle: shuffle);
    state = state.copyWith(queue: queue, loading: true);
    await _openCurrent();
  }

  Future<void> _openCurrent() async {
    final item = state.queue.current;
    if (item == null) return;
    // Music and video are mutually exclusive: only one stream at a
    // time, otherwise both players run underneath each other.
    await ref.read(videoPlayerProvider.notifier).stop();
    final client = ref.read(jellyfinClientProvider);
    try {
      await player.open(Media(client.audioStreamUrl(item.id)), play: true);
      state = state.copyWith(loading: false);
      client.reportStart(item.id).catchError((_) {});
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  void _onTrackEnd() {
    final next = state.queue.advance();
    if (next.current == null || identical(next, state.queue)) return;
    state = state.copyWith(queue: next, loading: true);
    _openCurrent();
  }

  Future<void> toggle() => player.playOrPause();

  /// Pause without materializing a player when none exists.
  Future<void> pause() async {
    final p = _player;
    if (p != null) await p.pause();
  }

  Future<void> next() async {
    final q = state.queue.advance();
    if (identical(q, state.queue) || q.current == null) return;
    state = state.copyWith(queue: q, loading: true);
    await _openCurrent();
  }

  Future<void> previous() async {
    final q = state.queue.back();
    if (identical(q, state.queue) || q.current == null) {
      await player.seek(Duration.zero);
      return;
    }
    state = state.copyWith(queue: q, loading: true);
    await _openCurrent();
  }

  Future<void> jumpTo(int index) async {
    final q = state.queue.jumpTo(index);
    if (q.current == null) return;
    state = state.copyWith(queue: q, loading: true);
    await _openCurrent();
  }

  void toggleShuffle() {
    state = state.copyWith(queue: state.queue.toggleShuffle());
  }

  Future<void> seek(Duration position) => player.seek(position);

  Future<void> stop() async {
    await _player?.stop();
    state = const AudioState();
  }
}

final audioPlayerProvider = NotifierProvider<AudioPlayerNotifier, AudioState>(
  AudioPlayerNotifier.new,
);
