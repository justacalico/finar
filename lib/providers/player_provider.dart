import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../core/api/media_service.dart';
import '../core/api/models/media_item.dart';
import '../core/api/models/playback_info.dart';
import 'library_provider.dart';

/// Player state
class PlayerState {
  final MediaItem? currentItem;
  final StreamInfo? streamInfo;
  final bool isPlaying;
  final bool isBuffering;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final double volume;
  final int? audioTrackIndex;
  final int? subtitleTrackIndex;
  final String? error;
  final MediaItem? nextItem;
  final List<MediaItem>? playlist;
  final int? playlistIndex;
  final List<ChapterInfo>? chapters;
  final int? currentSubtitleTrack;
  final List<String> availableQualities;
  final String? currentQuality;

  const PlayerState({
    this.currentItem,
    this.streamInfo,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.volume = 1.0,
    this.audioTrackIndex,
    this.subtitleTrackIndex,
    this.error,
    this.nextItem,
    this.playlist,
    this.playlistIndex,
    this.chapters,
    this.currentSubtitleTrack,
    this.availableQualities = const ['Auto', '1080p', '720p', '480p'],
    this.currentQuality = 'Auto',
  });

  PlayerState copyWith({
    MediaItem? currentItem,
    StreamInfo? streamInfo,
    bool? isPlaying,
    bool? isBuffering,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? volume,
    int? audioTrackIndex,
    int? subtitleTrackIndex,
    String? error,
    MediaItem? nextItem,
    List<MediaItem>? playlist,
    int? playlistIndex,
    List<ChapterInfo>? chapters,
    int? currentSubtitleTrack,
    List<String>? availableQualities,
    String? currentQuality,
  }) {
    return PlayerState(
      currentItem: currentItem ?? this.currentItem,
      streamInfo: streamInfo ?? this.streamInfo,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      volume: volume ?? this.volume,
      audioTrackIndex: audioTrackIndex ?? this.audioTrackIndex,
      subtitleTrackIndex: subtitleTrackIndex ?? this.subtitleTrackIndex,
      error: error,
      nextItem: nextItem ?? this.nextItem,
      playlist: playlist ?? this.playlist,
      playlistIndex: playlistIndex ?? this.playlistIndex,
      chapters: chapters ?? this.chapters,
      currentSubtitleTrack: currentSubtitleTrack ?? this.currentSubtitleTrack,
      availableQualities: availableQualities ?? this.availableQualities,
      currentQuality: currentQuality ?? this.currentQuality,
    );
  }

  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  bool get hasNext =>
      playlist != null &&
      playlistIndex != null &&
      playlistIndex! < playlist!.length - 1;

  bool get hasPrevious =>
      playlist != null && playlistIndex != null && playlistIndex! > 0;
}

/// Player notifier
class PlayerNotifier extends StateNotifier<PlayerState> {
  final MediaService _mediaService;
  late final Player _player;
  late final VideoController _videoController;
  Timer? _progressTimer;
  final List<StreamSubscription> _subscriptions = [];

  PlayerNotifier(this._mediaService) : super(const PlayerState()) {
    _initPlayer();
  }

  void _initPlayer() {
    _player = Player();
    _videoController = VideoController(_player);

    _subscriptions.add(_player.stream.playing.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    }));

    _subscriptions.add(_player.stream.buffering.listen((buffering) {
      state = state.copyWith(isBuffering: buffering);
    }));

    _subscriptions.add(_player.stream.position.listen((position) {
      state = state.copyWith(position: position);
    }));

    _subscriptions.add(_player.stream.duration.listen((duration) {
      state = state.copyWith(duration: duration);
    }));

    _subscriptions.add(_player.stream.buffer.listen((buffer) {
      state = state.copyWith(bufferedPosition: buffer);
    }));

    _subscriptions.add(_player.stream.volume.listen((volume) {
      state = state.copyWith(volume: volume / 100);
    }));

    _subscriptions.add(_player.stream.completed.listen((completed) {
      if (completed && state.hasNext) {
        playNext();
      }
    }));
  }

  Player get player => _player;
  VideoController get videoController => _videoController;

  /// Play a media item
  Future<void> play(
    MediaItem item, {
    int? startPositionTicks,
    List<MediaItem>? playlist,
    int? playlistIndex,
  }) async {
    state = state.copyWith(
      isLoading: true,
      currentItem: item,
      error: null,
      playlist: playlist,
      playlistIndex: playlistIndex,
    );

    try {
      final streamInfo = await _mediaService.getStreamInfo(
        item.id,
        startTimeTicks: startPositionTicks,
      );

      state = state.copyWith(
        streamInfo: streamInfo,
        audioTrackIndex: streamInfo.defaultAudioIndex,
        subtitleTrackIndex: streamInfo.defaultSubtitleIndex,
      );

      await _player.open(Media(streamInfo.url));

      // Report playback started
      await _mediaService.reportPlaybackStarted(
        item.id,
        mediaSourceId: streamInfo.mediaSource.id,
        playSessionId: streamInfo.playSessionId,
        audioStreamIndex: streamInfo.defaultAudioIndex,
        subtitleStreamIndex: streamInfo.defaultSubtitleIndex,
        positionTicks: startPositionTicks,
        playMethod: streamInfo.isTranscoding ? 'Transcode' : 'DirectPlay',
      );

      // Start progress reporting
      _startProgressReporting();

      state = state.copyWith(isLoading: false);

      // Load next item info
      _loadNextItem();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Play from a playlist
  Future<void> playPlaylist(List<MediaItem> playlist, int startIndex) async {
    if (playlist.isEmpty || startIndex >= playlist.length) return;
    await play(
      playlist[startIndex],
      playlist: playlist,
      playlistIndex: startIndex,
    );
  }

  /// Resume playback
  Future<void> resume(MediaItem item) async {
    final startPosition = item.userData?.playbackPositionTicks;
    await play(item, startPositionTicks: startPosition);
  }

  /// Play/pause toggle
  Future<void> playOrPause() async {
    await _player.playOrPause();
  }

  /// Pause
  Future<void> pause() async {
    await _player.pause();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Seek to position (alias for compatibility)
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  /// Seek relative
  Future<void> seekRelative(Duration offset) async {
    final newPosition = state.position + offset;
    final clamped = Duration(
      milliseconds:
          newPosition.inMilliseconds.clamp(0, state.duration.inMilliseconds),
    );
    await _player.seek(clamped);
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume * 100);
  }

  /// Set audio track
  Future<void> setAudioTrack(int index) async {
    state = state.copyWith(audioTrackIndex: index);
    // In a real implementation, you'd need to reload the stream with new audio track
    // or use native audio track selection if supported
  }

  /// Set subtitle track
  Future<void> setSubtitleTrack(int? index) async {
    state = state.copyWith(subtitleTrackIndex: index, currentSubtitleTrack: index);
    // In a real implementation, you'd need to handle subtitle loading
  }

  /// Set quality
  Future<void> setQuality(String quality) async {
    state = state.copyWith(currentQuality: quality);
    // In a real implementation, you'd reload the stream with different bitrate/resolution
  }

  /// Play next item
  Future<void> playNext() async {
    if (!state.hasNext) return;
    final nextIndex = state.playlistIndex! + 1;
    await play(
      state.playlist![nextIndex],
      playlist: state.playlist,
      playlistIndex: nextIndex,
    );
  }

  /// Play previous item
  Future<void> playPrevious() async {
    if (!state.hasPrevious) return;
    final prevIndex = state.playlistIndex! - 1;
    await play(
      state.playlist![prevIndex],
      playlist: state.playlist,
      playlistIndex: prevIndex,
    );
  }

  /// Stop playback
  Future<void> stop() async {
    _stopProgressReporting();

    final item = state.currentItem;
    final streamInfo = state.streamInfo;

    if (item != null) {
      try {
        await _mediaService.reportPlaybackStopped(
          item.id,
          mediaSourceId: streamInfo?.mediaSource.id,
          playSessionId: streamInfo?.playSessionId,
          positionTicks: state.position.inMicroseconds * 10,
        );
      } catch (_) {}
    }

    await _player.stop();
    state = const PlayerState();
  }

  void _startProgressReporting() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _reportProgress();
    });
  }

  void _stopProgressReporting() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> _reportProgress() async {
    final item = state.currentItem;
    final streamInfo = state.streamInfo;

    if (item == null) return;

    try {
      await _mediaService.reportPlaybackProgress(
        item.id,
        mediaSourceId: streamInfo?.mediaSource.id,
        playSessionId: streamInfo?.playSessionId,
        positionTicks: state.position.inMicroseconds * 10,
        isPaused: !state.isPlaying,
        volumeLevel: (state.volume * 100).round(),
        audioStreamIndex: state.audioTrackIndex,
        subtitleStreamIndex: state.subtitleTrackIndex,
        playMethod: streamInfo?.isTranscoding == true ? 'Transcode' : 'DirectPlay',
      );
    } catch (_) {}
  }

  Future<void> _loadNextItem() async {
    if (!state.hasNext) {
      state = state.copyWith(nextItem: null);
      return;
    }
    state = state.copyWith(nextItem: state.playlist![state.playlistIndex! + 1]);
  }

  @override
  void dispose() {
    _stopProgressReporting();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}

/// Player provider
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final mediaService = ref.watch(mediaServiceProvider);
  return PlayerNotifier(mediaService);
});

/// Video controller provider
final videoControllerProvider = Provider<VideoController>((ref) {
  final playerNotifier = ref.watch(playerProvider.notifier);
  return playerNotifier.videoController;
});

/// Player instance provider
final playerInstanceProvider = Provider<Player>((ref) {
  final playerNotifier = ref.watch(playerProvider.notifier);
  return playerNotifier.player;
});

/// Mini player visibility provider
final showMiniPlayerProvider = Provider<bool>((ref) {
  final playerState = ref.watch(playerProvider);
  return playerState.currentItem != null;
});
