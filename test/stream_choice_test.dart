import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/api/models.dart';
import 'package:finar/providers/playback_provider.dart';
import 'package:flutter_test/flutter_test.dart';

JellyfinClient client() => JellyfinClient(deviceId: 'd')
  ..setServerUrl('http://srv')
  ..setCredentials(accessToken: 'tok', userId: 'u');

const item = MediaItem(id: 'i1', name: 'Movie');

MediaSource source({
  bool directPlay = true,
  bool transcode = true,
  List<MediaStream> streams = const [],
}) => MediaSource(
  id: 'ms1',
  supportsDirectPlay: directPlay,
  supportsTranscoding: transcode,
  streams: streams,
);

void main() {
  group('resolveStream', () {
    test('prefers the local file when downloaded', () {
      final choice = resolveStream(
        client(),
        item,
        const PlaybackInfo(),
        localPath: '/tmp/i1.mkv',
      );
      expect(choice.url, '/tmp/i1.mkv');
      expect(choice.directPlay, isTrue);
    });

    test('direct plays when the source allows it', () {
      final choice = resolveStream(
        client(),
        item,
        PlaybackInfo(mediaSources: [source()], playSessionId: 'ps'),
      );
      expect(choice.directPlay, isTrue);
      expect(choice.url, contains('/Videos/i1/stream'));
      expect(choice.url, contains('MediaSourceId=ms1'));
    });

    test('falls back to hls when direct play unsupported', () {
      final choice = resolveStream(
        client(),
        item,
        PlaybackInfo(
          mediaSources: [source(directPlay: false)],
          playSessionId: 'ps',
        ),
        maxBitrate: 8000000,
      );
      expect(choice.directPlay, isFalse);
      expect(choice.url, contains('master.m3u8'));
      expect(choice.url, contains('PlaySessionId=ps'));
      expect(choice.url, contains('MaxStreamingBitrate=8000000'));
    });

    test('exposes tracks from the chosen source', () {
      const streams = [
        MediaStream(type: 'Video', index: 0),
        MediaStream(type: 'Audio', index: 1, language: 'eng', isDefault: true),
        MediaStream(type: 'Subtitle', index: 2, language: 'spa'),
      ];
      final choice = resolveStream(
        client(),
        item,
        PlaybackInfo(mediaSources: [source(streams: streams)]),
      );
      expect(choice.audioStreams.length, 1);
      expect(choice.subtitleStreams.length, 1);
    });
  });

  group('preferredAudioIndex', () {
    const streams = [
      MediaStream(type: 'Audio', index: 1, language: 'eng'),
      MediaStream(type: 'Audio', index: 2, language: 'jpn', isDefault: true),
    ];

    test('honours preferred language', () {
      expect(preferredAudioIndex(streams, 'eng'), 1);
      expect(preferredAudioIndex(streams, 'jpn'), 2);
    });

    test('falls back to default then first', () {
      expect(preferredAudioIndex(streams, 'fra'), 2);
      expect(
        preferredAudioIndex(const [MediaStream(type: 'Audio', index: 7)], ''),
        7,
      );
      expect(preferredAudioIndex(const [], 'eng'), isNull);
    });
  });

  group('preferredSubtitleIndex', () {
    const streams = [
      MediaStream(type: 'Subtitle', index: 5, language: 'eng'),
      MediaStream(type: 'Subtitle', index: 6, language: 'spa', isForced: true),
    ];

    test('off when disabled or empty', () {
      expect(preferredSubtitleIndex(streams, 'eng', false), -1);
      expect(preferredSubtitleIndex(const [], 'eng', true), -1);
    });

    test('matches preferred language, then default/forced', () {
      expect(preferredSubtitleIndex(streams, 'eng', true), 5);
      expect(preferredSubtitleIndex(streams, '', true), 6);
      expect(preferredSubtitleIndex(streams, 'zho', true), 6);
    });
  });
}
