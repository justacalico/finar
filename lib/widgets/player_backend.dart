import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../providers/player_provider.dart';

class MediaKitBackend implements PlayerBackend {
  MediaKitBackend() {
    _player = Player();
    _controller = VideoController(_player);
  }

  late final Player _player;
  late final VideoController _controller;

  @override
  Stream<Duration> get position => _player.stream.position;
  @override
  Stream<Duration> get duration => _player.stream.duration;
  @override
  Stream<bool> get playing => _player.stream.playing;
  @override
  Stream<bool> get buffering => _player.stream.buffering;
  @override
  Stream<double> get volume => _player.stream.volume;
  @override
  Stream<double> get rate => _player.stream.rate;
  @override
  Stream<bool> get completed => _player.stream.completed;

  @override
  Future<void> open(Uri uri,
      {Duration? startAt, String? localFile}) async {
    await _player.open(Media(localFile ?? uri.toString(), start: startAt));
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  @override
  Future<void> setRate(double rate) => _player.setRate(rate);

  @override
  Future<void> setSubtitleTrack(int? streamIndex) async {
    if (streamIndex == null) {
      await _player.setSubtitleTrack(SubtitleTrack.no());
    } else {
      await _player.setSubtitleTrack(SubtitleTrack.auto());
    }
  }

  @override
  Future<void> setAudioTrack(int? streamIndex) async {
    if (streamIndex != null) {
      await _player.setAudioTrack(AudioTrack.auto());
    }
  }

  @override
  Widget buildVideo(BuildContext context) =>
      Video(controller: _controller, controls: NoVideoControls);

  @override
  Future<void> dispose() => _player.dispose();
}

final playerBackendProvider = Provider<PlayerBackend>((ref) {
  final backend = MediaKitBackend();
  ref.onDispose(backend.dispose);
  return backend;
});
