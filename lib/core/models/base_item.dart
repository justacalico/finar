import 'media.dart';

class UserData {
  const UserData({
    this.played = false,
    this.isFavorite = false,
    this.playbackPositionTicks = 0,
    this.playCount = 0,
    this.playedPercentage,
    this.unplayedItemCount,
  });

  final bool played;
  final bool isFavorite;
  final int playbackPositionTicks;
  final int playCount;
  final double? playedPercentage;
  final int? unplayedItemCount;

  UserData copyWith({bool? played, bool? isFavorite, int? playbackPositionTicks}) =>
      UserData(
        played: played ?? this.played,
        isFavorite: isFavorite ?? this.isFavorite,
        playbackPositionTicks:
            playbackPositionTicks ?? this.playbackPositionTicks,
        playCount: playCount,
        playedPercentage: playedPercentage,
        unplayedItemCount: unplayedItemCount,
      );

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        played: json['Played'] as bool? ?? false,
        isFavorite: json['IsFavorite'] as bool? ?? false,
        playbackPositionTicks: json['PlaybackPositionTicks'] as int? ?? 0,
        playCount: json['PlayCount'] as int? ?? 0,
        playedPercentage: (json['PlayedPercentage'] as num?)?.toDouble(),
        unplayedItemCount: json['UnplayedItemCount'] as int?,
      );
}

class Person {
  const Person({required this.id, required this.name, this.role, this.type});

  final String id;
  final String name;
  final String? role;
  final String? type;

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['Id'] as String? ?? '',
        name: json['Name'] as String? ?? '',
        role: json['Role'] as String?,
        type: json['Type'] as String?,
      );
}

class BaseItem {
  const BaseItem({
    required this.id,
    required this.name,
    required this.type,
    this.serverId,
    this.overview,
    this.productionYear,
    this.runTimeTicks,
    this.communityRating,
    this.officialRating,
    this.genres = const [],
    this.imageTags = const {},
    this.backdropImageTags = const [],
    this.parentBackdropItemId,
    this.seriesName,
    this.seriesId,
    this.seasonId,
    this.seasonName,
    this.albumId,
    this.indexNumber,
    this.parentIndexNumber,
    this.albumArtist,
    this.artists = const [],
    this.userData = const UserData(),
    this.mediaSources = const [],
    this.mediaStreams = const [],
    this.collectionType,
    this.isFolder = false,
    this.premiereDate,
    this.people = const [],
    this.childCount,
    this.primaryImageAspectRatio,
    this.locationType,
  });

  final String id;
  final String name;
  final String type;
  final String? serverId;
  final String? overview;
  final int? productionYear;
  final int? runTimeTicks;
  final double? communityRating;
  final String? officialRating;
  final List<String> genres;
  final Map<String, String> imageTags;
  final List<String> backdropImageTags;
  final String? parentBackdropItemId;
  final String? seriesName;
  final String? seriesId;
  final String? seasonId;
  final String? seasonName;
  final String? albumId;
  final int? indexNumber;
  final int? parentIndexNumber;
  final String? albumArtist;
  final List<String> artists;
  final UserData userData;
  final List<MediaSource> mediaSources;
  final List<MediaStream> mediaStreams;
  final String? collectionType;
  final bool isFolder;
  final String? premiereDate;
  final List<Person> people;
  final int? childCount;
  final double? primaryImageAspectRatio;
  final String? locationType;

  String? get primaryImageTag => imageTags['Primary'];

  String? get backdropImageTag => backdropImageTags.isNotEmpty
      ? backdropImageTags.first
      : null;

  String get effectiveBackdropId => backdropImageTag != null
      ? id
      : (parentBackdropItemId ?? id);

  bool get isAudio => type == 'Audio' || type == 'MusicAlbum' || type == 'MusicArtist';
  bool get isVideo => type == 'Movie' || type == 'Episode' || type == 'Video';
  bool get isPlayable => isAudio || isVideo || type == 'MusicVideo';

  double get resumeFraction {
    final total = runTimeTicks;
    if (total == null || total == 0) return 0;
    return (userData.playbackPositionTicks / total).clamp(0.0, 1.0);
  }

  BaseItem copyWith({UserData? userData}) => BaseItem(
        id: id,
        name: name,
        type: type,
        serverId: serverId,
        overview: overview,
        productionYear: productionYear,
        runTimeTicks: runTimeTicks,
        communityRating: communityRating,
        officialRating: officialRating,
        genres: genres,
        imageTags: imageTags,
        backdropImageTags: backdropImageTags,
        parentBackdropItemId: parentBackdropItemId,
        seriesName: seriesName,
        seriesId: seriesId,
        seasonId: seasonId,
        seasonName: seasonName,
        albumId: albumId,
        indexNumber: indexNumber,
        parentIndexNumber: parentIndexNumber,
        albumArtist: albumArtist,
        artists: artists,
        userData: userData ?? this.userData,
        mediaSources: mediaSources,
        mediaStreams: mediaStreams,
        collectionType: collectionType,
        isFolder: isFolder,
        premiereDate: premiereDate,
        people: people,
        childCount: childCount,
        primaryImageAspectRatio: primaryImageAspectRatio,
        locationType: locationType,
      );

  factory BaseItem.fromJson(Map<String, dynamic> json) => BaseItem(
        id: json['Id'] as String? ?? '',
        name: json['Name'] as String? ?? '',
        type: json['Type'] as String? ?? '',
        serverId: json['ServerId'] as String?,
        overview: json['Overview'] as String?,
        productionYear: json['ProductionYear'] as int?,
        runTimeTicks: json['RunTimeTicks'] as int?,
        communityRating: (json['CommunityRating'] as num?)?.toDouble(),
        officialRating: json['OfficialRating'] as String?,
        genres: (json['Genres'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        imageTags: (json['ImageTags'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v.toString())),
        backdropImageTags:
            (json['BackdropImageTags'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList(),
        parentBackdropItemId: json['ParentBackdropItemId'] as String?,
        seriesName: json['SeriesName'] as String?,
        seriesId: json['SeriesId'] as String?,
        seasonId: json['SeasonId'] as String?,
        seasonName: json['SeasonName'] as String?,
        albumId: json['AlbumId'] as String?,
        indexNumber: json['IndexNumber'] as int?,
        parentIndexNumber: json['ParentIndexNumber'] as int?,
        albumArtist: json['AlbumArtist'] as String?,
        artists: (json['Artists'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        userData: UserData.fromJson(
            json['UserData'] as Map<String, dynamic>? ?? const {}),
        mediaSources:
            (json['MediaSources'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(MediaSource.fromJson)
                .toList(),
        mediaStreams:
            (json['MediaStreams'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(MediaStream.fromJson)
                .toList(),
        collectionType: json['CollectionType'] as String?,
        isFolder: json['IsFolder'] as bool? ?? false,
        premiereDate: json['PremiereDate'] as String?,
        people: (json['People'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Person.fromJson)
            .toList(),
        childCount: json['ChildCount'] as int?,
        primaryImageAspectRatio:
            (json['PrimaryImageAspectRatio'] as num?)?.toDouble(),
        locationType: json['LocationType'] as String?,
      );
}

class ItemsResult {
  const ItemsResult({
    required this.items,
    required this.totalRecordCount,
    this.startIndex = 0,
  });

  final List<BaseItem> items;
  final int totalRecordCount;
  final int startIndex;

  factory ItemsResult.fromJson(Map<String, dynamic> json) => ItemsResult(
        items: (json['Items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(BaseItem.fromJson)
            .toList(),
        totalRecordCount: json['TotalRecordCount'] as int? ?? 0,
        startIndex: json['StartIndex'] as int? ?? 0,
      );
}
