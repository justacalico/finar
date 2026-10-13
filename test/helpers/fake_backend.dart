import 'dart:async';

import 'package:flutter/material.dart';
import 'package:finar/providers/player_provider.dart';

class FakePlayerBackend implements PlayerBackend {
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _buffering = StreamController<bool>.broadcast();
  final _volume = StreamController<double>.broadcast();
  final _rate = StreamController<double>.broadcast();
  final _completed = StreamController<bool>.broadcast();

  Duration currentPosition = Duration.zero;
  bool isPlaying = false;
  double currentVolume = 100;
  double currentRate = 1;
  bool opened = false;
  Uri? lastUri;
  int? lastSubtitle;
  int? lastAudio;
  bool disposed = false;

  @override
  Stream<Duration> get position => _position.stream;
  @override
  Stream<Duration> get duration => _duration.stream;
  @override
  Stream<bool> get playing => _playing.stream;
  @override
  Stream<bool> get buffering => _buffering.stream;
  @override
  Stream<double> get volume => _volume.stream;
  @override
  Stream<double> get rate => _rate.stream;
  @override
  Stream<bool> get completed => _completed.stream;

  @override
  Future<void> open(Uri uri,
      {Duration? startAt, String? localFile}) async {
    opened = true;
    lastUri = uri;
    currentPosition = startAt ?? Duration.zero;
    _duration.add(const Duration(hours: 2));
    _position.add(currentPosition);
    _volume.add(100);
    _rate.add(1);
  }

  @override
  Future<void> play() async {
    isPlaying = true;
    _playing.add(true);
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
    _playing.add(false);
  }

  @override
  Future<void> seek(Duration position) async {
    currentPosition = position;
    _position.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    currentVolume = volume;
    _volume.add(volume);
  }

  @override
  Future<void> setRate(double rate) async {
    currentRate = rate;
    _rate.add(rate);
  }

  @override
  Future<void> setSubtitleTrack(int? streamIndex) async {
    lastSubtitle = streamIndex;
  }

  @override
  Future<void> setAudioTrack(int? streamIndex) async {
    lastAudio = streamIndex;
  }

  void emitCompleted() => _completed.add(true);

  @override
  Widget buildVideo(BuildContext context) => const ColoredBox(
      color: Color(0xFF111827), child: SizedBox.expand());

  @override
  Future<void> dispose() async {
    disposed = true;
    for (final c in [
      _position,
      _duration,
      _playing,
      _buffering,
      _volume,
      _rate,
      _completed
    ]) {
      await c.close();
    }
  }
}
