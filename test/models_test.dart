import 'package:finar/core/models/models.dart';

import 'helpers/fake_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaseItem.fromJson', () {
    final json = {
      'Id': 'abc',
      'Name': 'Big Buck Bunny',
      'Type': 'Movie',
      'ServerId': 'srv',
      'Overview': 'A rabbit.',
      'ProductionYear': 2008,
      'RunTimeTicks': 5960000000,
      'CommunityRating': 7.8,
      'OfficialRating': 'PG',
      'Genres': ['Animation', 'Comedy'],
      'ImageTags': {'Primary': 'p1'},
      'BackdropImageTags': ['b1'],
      'UserData': {
        'Played': true,
        'IsFavorite': true,
        'PlaybackPositionTicks': 1000000,
      },
      'MediaSources': [
        {
          'Id': 'ms1',
          'Container': 'mkv',
          'Size': 100,
          'MediaStreams': [
            {
              'Index': 2,
              'Type': 'Subtitle',
              'Codec': 'srt',
              'Language': 'eng',
              'DisplayTitle': 'English',
              'IsDefault': true,
            }
          ]
        }
      ],
      'People': [
        {'Id': 'p1', 'Name': 'Sacha', 'Role': 'Director', 'Type': 'Director'}
      ],
      'CollectionType': 'movies',
      'IsFolder': false,
    };

    test('parses all fields', () {
      final item = BaseItem.fromJson(json);
      expect(item.id, 'abc');
      expect(item.name, 'Big Buck Bunny');
      expect(item.type, 'Movie');
      expect(item.productionYear, 2008);
      expect(item.genres, ['Animation', 'Comedy']);
      expect(item.userData.played, isTrue);
      expect(item.userData.isFavorite, isTrue);
      expect(item.mediaSources.single.mediaStreams.single.isSubtitle,
          isTrue);
      expect(item.people.single.role, 'Director');
      expect(item.primaryImageTag, 'p1');
      expect(item.backdropImageTag, 'b1');
    });

    test('tolerates sparse payloads', () {
      final item = BaseItem.fromJson({'Id': 'x'});
      expect(item.name, '');
      expect(item.isPlayable, isFalse);
      expect(item.imageTags, isEmpty);
    });
  });

  test('BaseItem resumeFraction clamps 0..1', () {
    final half = BaseItem(
        id: 'a',
        name: 'x',
        type: 'Movie',
        runTimeTicks: 1000,
        userData: const UserData(playbackPositionTicks: 500));
    expect(half.resumeFraction, 0.5);
    final over = BaseItem(
        id: 'a',
        name: 'x',
        type: 'Movie',
        runTimeTicks: 1000,
        userData: const UserData(playbackPositionTicks: 2000));
    expect(over.resumeFraction, 1);
    const none = BaseItem(id: 'a', name: 'x', type: 'Movie');
    expect(none.resumeFraction, 0);
  });

  test('isPlayable for media types only', () {
    expect(
        BaseItem.fromJson({'Id': 'x', 'Type': 'Movie'}).isPlayable, isTrue);
    expect(
        BaseItem.fromJson({'Id': 'x', 'Type': 'Audio'}).isPlayable, isTrue);
    expect(
        BaseItem.fromJson({'Id': 'x', 'Type': 'Series'}).isPlayable, isFalse);
    expect(
        BaseItem.fromJson({'Id': 'x', 'Type': 'Episode'}).isPlayable, isTrue);
  });

  test('effectiveBackdropId falls back to parent', () {
    final item = BaseItem.fromJson({
      'Id': 'e1',
      'Type': 'Episode',
      'BackdropImageTags': [],
      'ParentBackdropItemId': 'series9',
    });
    expect(item.effectiveBackdropId, 'series9');
  });

  test('JellyfinUser parses admin flag', () {
    final user = JellyfinUser.fromJson({
      'Id': 'u',
      'Name': 'n',
      'Policy': {'IsAdministrator': true}
    });
    expect(user.isAdministrator, isTrue);
  });

  test('AuthResult parses token payload', () {
    final result = AuthResult.fromJson({
      'AccessToken': 'tok',
      'ServerId': 's1',
      'SessionId': 'sess',
      'User': {'Id': 'u1', 'Name': 'Cal'}
    });
    expect(result.accessToken, 'tok');
    expect(result.user.name, 'Cal');
    expect(result.sessionId, 'sess');
  });

  test('ItemsResult parses totals', () {
    final result = ItemsResult.fromJson({
      'Items': [
        {'Id': 'a', 'Name': 'A', 'Type': 'Movie'}
      ],
      'TotalRecordCount': 42,
      'StartIndex': 10,
    });
    expect(result.items.single.id, 'a');
    expect(result.totalRecordCount, 42);
    expect(result.startIndex, 10);
  });

  test('copyWith overrides userData and keeps the rest', () {
    final item = makeItem(
        id: 'm1',
        name: 'Film',
        type: 'Movie',
        positionTicks: 10,
        favorite: false);
    final fav =
        item.copyWith(userData: const UserData(isFavorite: true));
    expect(fav.userData.isFavorite, isTrue);
    expect(fav.id, 'm1');
    expect(fav.name, 'Film');
    expect(fav.type, 'Movie');
    expect(fav.imageTags, item.imageTags);
  });

  test('copyWith with no args keeps everything', () {
    final item = makeItem(id: 'm1', name: 'Film');
    expect(identical(item.copyWith().userData, item.userData), isTrue);
  });

  test('userData copyWith merges fields', () {
    const data = UserData(playCount: 3, playedPercentage: 50);
    final next = data.copyWith(played: true);
    expect(next.played, isTrue);
    expect(next.playCount, 3);
    expect(next.playedPercentage, 50);
    final other = data.copyWith(playbackPositionTicks: 99);
    expect(other.playbackPositionTicks, 99);
  });
}
