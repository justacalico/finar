import 'dart:async';

import '../api/jellyfin_client.dart';
import '../models/models.dart';

class PlaybackReporter {
  PlaybackReporter(this._client);

  final JellyfinClient _client;
  Timer? _timer;
  BaseItem? _item;
  bool _paused = false;
  int _positionTicks = 0;

  static const _interval = Duration(seconds: 10);

  void start(BaseItem item, {int positionTicks = 0}) {
    stop();
    _item = item;
    _paused = false;
    _positionTicks = positionTicks;
    _client.reportPlaybackStart(item, positionTicks: positionTicks);
    _timer = Timer.periodic(_interval, (_) {
      final item = _item;
      if (item != null) {
        _client.reportPlaybackProgress(item,
            positionTicks: _positionTicks, isPaused: _paused);
      }
    });
  }

  void updatePosition(Duration position) {
    _positionTicks = position.inMicroseconds * 10;
  }

  void setPaused(bool paused) => _paused = paused;

  void stop({Duration? position}) {
    _timer?.cancel();
    _timer = null;
    final item = _item;
    _item = null;
    if (item != null) {
      _client.reportPlaybackStopped(item,
          positionTicks: position != null
              ? position.inMicroseconds * 10
              : _positionTicks);
    }
  }
}
