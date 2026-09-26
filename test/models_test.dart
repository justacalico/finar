import 'package:finar/core/api/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> itemJson(Map<String, dynamic> over) => {
  'Id': 'abc',
  'Name': 'Test',
  'Type': 'Movie',
  ...over,
};

void main() {
  group('MediaKind.fromString', () {
    test('maps known types', () {
      expect(MediaKind.fromString('Movie'), MediaKind.movie);
      expect(MediaKind.fromString('Series'), MediaKind.series);
      expect(MediaKind.fromString('Episode'), MediaKind.episode);
      expect(MediaKind.fromString('Audio'), MediaKind.audio);
      expect(MediaKind.fromString('MusicAlbum'), MediaKind.album);
      expect(MediaKind.fromString('MusicArtist'), MediaKind.artist);
      expect(
        MediaKind.fromString('CollectionFolder'),
        MediaKind.collectionFolder,
      );
      expect(MediaKind.fromString('BoxSet'), MediaKind.boxSet);
      expect(MediaKind.fromString('nonsense'), MediaKind.unknown);
      expect(MediaKind.fromString(null), MediaKind.unknown);
    });
  });

  group('MediaItem.fromJson', () {
    test('parses a full movie payload', () {
      final item = MediaItem.fromJson(
        itemJson({
          'Overview': 'A film',
          'ProductionYear': 2020,
          'OfficialRating': 'PG-13',
          'CommunityRating': 8.2,
          'RunTimeTicks': 54000000000,
          'Genres': ['Drama', 'Sci-Fi'],
          'ImageTags': {'Primary': 'tag1', 'Logo': 'tag2'},
          'BackdropImageTags': ['b1', 'b2'],
          'People': [
            {'Id': 'p1', 'Name': 'Actor', 'Role': 'Lead', 'Type': 'Actor'},
          ],
          'UserData': {
            'Played': true,
            'IsFavorite': true,
            'PlaybackPositionTicks': 1000,
            'PlayCount': 2,
          },
        }),
      );

      expect(item.id, 'abc');
      expect(item.name, 'Test');
      expect(item.kind, MediaKind.movie);
      expect(item.productionYear, 2020);
      expect(item.communityRating, 8.2);
      expect(item.imageTags.primary, 'tag1');
      expect(item.backdropImageTags, ['b1', 'b2']);
      expect(item.people.single.name, 'Actor');
      expect(item.isPlayed, isTrue);
      expect(item.isFavorite, isTrue);
      expect(item.genres, ['Drama', 'Sci-Fi']);
    });

    test('tolerates missing fields and stringly numbers', () {
      final item = MediaItem.fromJson(
        itemJson({'ProductionYear': '1999', 'RunTimeTicks': '600000000'}),
      );
      expect(item.productionYear, 1999);
      expect(item.runtimeTicks, 600000000);
      expect(item.overview, isNull);
      expect(item.people, isEmpty);
      expect(item.mediaSources, isEmpty);
    });

    test('parses nested media sources and streams', () {
      final item = MediaItem.fromJson(
        itemJson({
          'MediaSources': [
            {
              'Id': 'ms1',
              'Container': 'mkv',
              'SupportsDirectPlay': true,
              'MediaStreams': [
                {'Type': 'Video', 'Index': 0, 'Codec': 'hevc'},
                {
                  'Type': 'Audio',
                  'Index': 1,
                  'Codec': 'aac',
                  'Language': 'eng',
                  'IsDefault': true,
                },
                {
                  'Type': 'Subtitle',
                  'Index': 3,
                  'Codec': 'srt',
                  'Language': 'spa',
                },
              ],
            },
          ],
        }),
      );
      final src = item.mediaSources.single;
      expect(src.supportsDirectPlay, isTrue);
      expect(src.audioStreams.single.language, 'eng');
      expect(src.subtitleStreams.single.codec, 'srt');
      expect(src.videoStream?.codec, 'hevc');
    });
  });

  group('MediaItem helpers', () {
    test('progress uses user data position', () {
      final item = MediaItem.fromJson(
        itemJson({
          'RunTimeTicks': 1000,
          'UserData': {'PlaybackPositionTicks': 250},
        }),
      );
      expect(item.progress, 0.25);
      expect(item.hasProgress, isTrue);
    });

    test('hasProgress is false when played', () {
      final item = MediaItem.fromJson(
        itemJson({
          'RunTimeTicks': 1000,
          'UserData': {'PlaybackPositionTicks': 250, 'Played': true},
        }),
      );
      expect(item.hasProgress, isFalse);
    });

    test('episodeLabel formats season and episode', () {
      final ep = MediaItem.fromJson(
        itemJson({
          'Type': 'Episode',
          'ParentIndexNumber': 2,
          'IndexNumber': 7,
          'SeriesName': 'Show',
        }),
      );
      expect(ep.episodeLabel, 'S2 E7');
      expect(ep.displayTitle, 'Show - Test');
    });

    test('metaLine combines year rating runtime', () {
      final item = MediaItem.fromJson(
        itemJson({
          'ProductionYear': 2020,
          'OfficialRating': 'R',
          'RunTimeTicks': 36000000000,
        }),
      );
      expect(item.metaLine, '2020  •  R  •  1h 0m');
    });

    test('isPlayable / isContainer classify kinds', () {
      final movie = MediaItem.fromJson(itemJson({'Type': 'Movie'}));
      final series = MediaItem.fromJson(itemJson({'Type': 'Series'}));
      final album = MediaItem.fromJson(itemJson({'Type': 'MusicAlbum'}));
      expect(movie.isPlayable, isTrue);
      expect(movie.isVideo, isTrue);
      expect(series.isContainer, isTrue);
      expect(album.isContainer, isTrue);
      expect(album.isPlayable, isFalse);
    });

    test('toJson round trips core fields', () {
      final item = MediaItem.fromJson(
        itemJson({
          'ProductionYear': 2021,
          'UserData': {'Played': false, 'IsFavorite': true},
        }),
      );
      final json = item.toJson();
      expect(json['Id'], 'abc');
      expect(json['Type'], 'Movie');
      expect(json['UserData']['IsFavorite'], isTrue);
      final reparsed = MediaItem.fromJson(json);
      expect(reparsed.name, item.name);
      expect(reparsed.isFavorite, isTrue);
    });
  });

  group('Other models', () {
    test('JfUser parses', () {
      final u = JfUser.fromJson({
        'Id': 'u1',
        'Name': 'Cal',
        'PrimaryImageTag': 't',
        'HasPassword': true,
      });
      expect(u.id, 'u1');
      expect(u.hasPassword, isTrue);
      expect(u.toJson()['Name'], 'Cal');
    });

    test('AuthResult parses', () {
      final r = AuthResult.fromJson({
        'User': {'Id': 'u1', 'Name': 'Cal'},
        'AccessToken': 'tok',
        'ServerId': 's1',
      });
      expect(r.accessToken, 'tok');
      expect(r.user.id, 'u1');
    });

    test('SearchHint parses and resolves kind', () {
      final h = SearchHint.fromJson({
        'ItemId': 'i1',
        'Name': 'Alien',
        'Type': 'Movie',
        'ProductionYear': '1979',
      });
      expect(h.kind, MediaKind.movie);
      expect(h.productionYear, 1979);
    });

    test('parseItemsResult reads totals', () {
      final r = parseItemsResult({
        'Items': [
          itemJson({}),
          itemJson({'Id': 'def'}),
        ],
        'TotalRecordCount': 42,
        'StartIndex': 10,
      });
      expect(r.items.length, 2);
      expect(r.totalCount, 42);
      expect(r.startIndex, 10);
    });

    test('MediaStream label prefers display title', () {
      final s = MediaStream.fromJson({
        'Type': 'Audio',
        'Index': 1,
        'DisplayTitle': 'English 5.1',
      });
      expect(s.label, 'English 5.1');
      final s2 = MediaStream.fromJson({
        'Type': 'Audio',
        'Index': 2,
        'Language': 'jpn',
        'Codec': 'aac',
      });
      expect(s2.label, 'jpn AAC');
      final s3 = const MediaStream(type: 'Audio', index: 5);
      expect(s3.label, 'Track 5');
    });

    test('PlaybackInfo parses sources', () {
      final p = PlaybackInfo.fromJson({
        'PlaySessionId': 'ps1',
        'MediaSources': [
          {'Id': 'm1', 'SupportsDirectPlay': true},
        ],
      });
      expect(p.playSessionId, 'ps1');
      expect(p.mediaSources.single.id, 'm1');
    });

    test('JfLibrary parses and flags music', () {
      final l = JfLibrary.fromJson({
        'Id': 'l1',
        'Name': 'Music',
        'CollectionType': 'music',
      });
      expect(l.isMusic, isTrue);
    });
  });
}
