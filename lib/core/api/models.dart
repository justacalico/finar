import 'format.dart';

int? _int(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _double(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

List<String> _stringList(dynamic v) =>
    (v as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];

enum MediaKind {
  movie,
  series,
  season,
  episode,
  audio,
  album,
  artist,
  folder,
  collectionFolder,
  boxSet,
  playlist,
  musicVideo,
  photo,
  unknown;

  static MediaKind fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'movie':
        return MediaKind.movie;
      case 'series':
        return MediaKind.series;
      case 'season':
        return MediaKind.season;
      case 'episode':
        return MediaKind.episode;
      case 'audio':
        return MediaKind.audio;
      case 'musicalbum':
      case 'album':
        return MediaKind.album;
      case 'musicartist':
      case 'artist':
        return MediaKind.artist;
      case 'folder':
        return MediaKind.folder;
      case 'collectionfolder':
        return MediaKind.collectionFolder;
      case 'boxset':
        return MediaKind.boxSet;
      case 'playlist':
        return MediaKind.playlist;
      case 'musicvideo':
        return MediaKind.musicVideo;
      case 'photo':
        return MediaKind.photo;
      default:
        return MediaKind.unknown;
    }
  }
}

class ServerInfo {
  final String id;
  final String name;
  final String version;
  final String serverUrl;

  const ServerInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.serverUrl,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json, String serverUrl) {
    return ServerInfo(
      id: json['Id'] as String? ?? '',
      name: json['ServerName'] as String? ?? 'Jellyfin Server',
      version: json['Version'] as String? ?? '',
      serverUrl: serverUrl,
    );
  }
}

class JfUser {
  final String id;
  final String name;
  final String? primaryImageTag;
  final bool hasPassword;
  final bool hasConfiguredPassword;
  final DateTime? lastLoginDate;

  const JfUser({
    required this.id,
    required this.name,
    this.primaryImageTag,
    this.hasPassword = false,
    this.hasConfiguredPassword = false,
    this.lastLoginDate,
  });

  factory JfUser.fromJson(Map<String, dynamic> json) {
    return JfUser(
      id: json['Id'] as String,
      name: json['Name'] as String? ?? '',
      primaryImageTag: json['PrimaryImageTag'] as String?,
      hasPassword: json['HasPassword'] as bool? ?? false,
      hasConfiguredPassword: json['HasConfiguredPassword'] as bool? ?? false,
      lastLoginDate: DateTime.tryParse(json['LastLoginDate'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Name': name,
    'PrimaryImageTag': primaryImageTag,
    'HasPassword': hasPassword,
    'HasConfiguredPassword': hasConfiguredPassword,
  };
}

class AuthResult {
  final JfUser user;
  final String accessToken;
  final String serverId;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.serverId,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      user: JfUser.fromJson(json['User'] as Map<String, dynamic>),
      accessToken: json['AccessToken'] as String,
      serverId: json['ServerId'] as String? ?? '',
    );
  }
}

class JfLibrary {
  final String id;
  final String name;
  final String? collectionType;
  final ImageTags imageTags;

  const JfLibrary({
    required this.id,
    required this.name,
    this.collectionType,
    this.imageTags = const ImageTags(),
  });

  factory JfLibrary.fromJson(Map<String, dynamic> json) {
    return JfLibrary(
      id: json['Id'] as String,
      name: json['Name'] as String? ?? '',
      collectionType: json['CollectionType'] as String?,
      imageTags: json['ImageTags'] != null
          ? ImageTags.fromJson(json['ImageTags'] as Map<String, dynamic>)
          : const ImageTags(),
    );
  }

  bool get isMusic => collectionType == 'music';
}

class ImageTags {
  final String? primary;
  final String? logo;
  final String? thumb;
  final String? banner;
  final String? backdrop;

  const ImageTags({
    this.primary,
    this.logo,
    this.thumb,
    this.banner,
    this.backdrop,
  });

  factory ImageTags.fromJson(Map<String, dynamic> json) => ImageTags(
    primary: json['Primary'] as String?,
    logo: json['Logo'] as String?,
    thumb: json['Thumb'] as String?,
    banner: json['Banner'] as String?,
    backdrop: json['Backdrop'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'Primary': primary,
    'Logo': logo,
    'Thumb': thumb,
    'Banner': banner,
    'Backdrop': backdrop,
  };
}

class UserData {
  final double? rating;
  final double? playedPercentage;
  final int? playbackPositionTicks;
  final int? playCount;
  final bool isFavorite;
  final bool played;
  final DateTime? lastPlayedDate;

  const UserData({
    this.rating,
    this.playedPercentage,
    this.playbackPositionTicks,
    this.playCount,
    this.isFavorite = false,
    this.played = false,
    this.lastPlayedDate,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    rating: _double(json['Rating']),
    playedPercentage: _double(json['PlayedPercentage']),
    playbackPositionTicks: _int(json['PlaybackPositionTicks']),
    playCount: _int(json['PlayCount']),
    isFavorite: json['IsFavorite'] as bool? ?? false,
    played: json['Played'] as bool? ?? false,
    lastPlayedDate: DateTime.tryParse(json['LastPlayedDate'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'Rating': rating,
    'PlayedPercentage': playedPercentage,
    'PlaybackPositionTicks': playbackPositionTicks,
    'PlayCount': playCount,
    'IsFavorite': isFavorite,
    'Played': played,
  };
}

class Person {
  final String id;
  final String name;
  final String? role;
  final String? type;
  final String? primaryImageTag;

  const Person({
    required this.id,
    required this.name,
    this.role,
    this.type,
    this.primaryImageTag,
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json['Id'] as String? ?? '',
    name: json['Name'] as String? ?? '',
    role: json['Role'] as String?,
    type: json['Type'] as String?,
    primaryImageTag: json['PrimaryImageTag'] as String?,
  );
}

class Chapter {
  final String name;
  final int startTicks;

  const Chapter({required this.name, required this.startTicks});

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    name: json['Name'] as String? ?? '',
    startTicks: _int(json['StartPositionTicks']) ?? 0,
  );
}

class MediaStream {
  final String type;
  final int index;
  final String? codec;
  final String? language;
  final String? title;
  final String? displayTitle;
  final bool isDefault;
  final bool isForced;
  final bool isExternal;
  final int? width;
  final int? height;
  final int? channels;
  final String? deliveryUrl;

  const MediaStream({
    required this.type,
    required this.index,
    this.codec,
    this.language,
    this.title,
    this.displayTitle,
    this.isDefault = false,
    this.isForced = false,
    this.isExternal = false,
    this.width,
    this.height,
    this.channels,
    this.deliveryUrl,
  });

  factory MediaStream.fromJson(Map<String, dynamic> json) => MediaStream(
    type: json['Type'] as String? ?? 'Unknown',
    index: _int(json['Index']) ?? 0,
    codec: json['Codec'] as String?,
    language: json['Language'] as String?,
    title: json['Title'] as String?,
    displayTitle: json['DisplayTitle'] as String?,
    isDefault: json['IsDefault'] as bool? ?? false,
    isForced: json['IsForced'] as bool? ?? false,
    isExternal: json['IsExternal'] as bool? ?? false,
    width: _int(json['Width']),
    height: _int(json['Height']),
    channels: _int(json['Channels']),
    deliveryUrl: json['DeliveryUrl'] as String?,
  );

  bool get isVideo => type == 'Video';
  bool get isAudio => type == 'Audio';
  bool get isSubtitle => type == 'Subtitle';

  String get label {
    if (displayTitle != null && displayTitle!.isNotEmpty) {
      return displayTitle!;
    }
    final parts = <String>[
      if (language != null && language!.isNotEmpty) language!,
      if (codec != null && codec!.isNotEmpty) codec!.toUpperCase(),
    ];
    return parts.isEmpty ? 'Track $index' : parts.join(' ');
  }
}

class MediaSource {
  final String id;
  final String? container;
  final int? size;
  final int? bitrate;
  final String? path;
  final bool supportsDirectPlay;
  final bool supportsDirectStream;
  final bool supportsTranscoding;
  final List<MediaStream> streams;

  const MediaSource({
    required this.id,
    this.container,
    this.size,
    this.bitrate,
    this.path,
    this.supportsDirectPlay = false,
    this.supportsDirectStream = false,
    this.supportsTranscoding = false,
    this.streams = const [],
  });

  factory MediaSource.fromJson(Map<String, dynamic> json) => MediaSource(
    id: json['Id'] as String? ?? '',
    container: json['Container'] as String?,
    size: _int(json['Size']),
    bitrate: _int(json['Bitrate']),
    path: json['Path'] as String?,
    supportsDirectPlay: json['SupportsDirectPlay'] as bool? ?? false,
    supportsDirectStream: json['SupportsDirectStream'] as bool? ?? false,
    supportsTranscoding: json['SupportsTranscoding'] as bool? ?? false,
    streams:
        (json['MediaStreams'] as List<dynamic>?)
            ?.map((e) => MediaStream.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  List<MediaStream> get audioStreams =>
      streams.where((s) => s.isAudio).toList();
  List<MediaStream> get subtitleStreams =>
      streams.where((s) => s.isSubtitle).toList();
  MediaStream? get videoStream {
    for (final s in streams) {
      if (s.isVideo) return s;
    }
    return null;
  }
}

class PlaybackInfo {
  final List<MediaSource> mediaSources;
  final String? playSessionId;

  const PlaybackInfo({this.mediaSources = const [], this.playSessionId});

  factory PlaybackInfo.fromJson(Map<String, dynamic> json) => PlaybackInfo(
    mediaSources:
        (json['MediaSources'] as List<dynamic>?)
            ?.map((e) => MediaSource.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    playSessionId: json['PlaySessionId'] as String?,
  );
}

class ItemsResult {
  final List<MediaItem> items;
  final int totalCount;
  final int startIndex;

  const ItemsResult({
    required this.items,
    required this.totalCount,
    this.startIndex = 0,
  });
}

ItemsResult parseItemsResult(Map<String, dynamic> json) => ItemsResult(
  items:
      (json['Items'] as List<dynamic>?)
          ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalCount: _int(json['TotalRecordCount']) ?? 0,
  startIndex: _int(json['StartIndex']) ?? 0,
);

List<MediaItem> parseItemList(List<dynamic> json) =>
    json.map((e) => MediaItem.fromJson(e as Map<String, dynamic>)).toList();

MediaItem parseItem(Map<String, dynamic> json) => MediaItem.fromJson(json);

class Genre {
  final String id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
    id: json['Id'] as String? ?? '',
    name: json['Name'] as String? ?? '',
  );
}

class SearchHint {
  final String itemId;
  final String name;
  final String type;
  final int? productionYear;
  final String? series;
  final String? primaryImageTag;
  final String? matchedTerm;

  const SearchHint({
    required this.itemId,
    required this.name,
    required this.type,
    this.productionYear,
    this.series,
    this.primaryImageTag,
    this.matchedTerm,
  });

  factory SearchHint.fromJson(Map<String, dynamic> json) => SearchHint(
    itemId: json['ItemId'] as String? ?? '',
    name: json['Name'] as String? ?? '',
    type: json['Type'] as String? ?? '',
    productionYear: _int(json['ProductionYear']),
    series: json['Series'] as String?,
    primaryImageTag: json['PrimaryImageTag'] as String?,
    matchedTerm: json['MatchedTerm'] as String?,
  );

  MediaKind get kind => MediaKind.fromString(type);
}

class MediaItem {
  final String id;
  final String name;
  final String? overview;
  final MediaKind kind;
  final String? typeString;
  final int? productionYear;
  final String? premiereDate;
  final String? officialRating;
  final double? communityRating;
  final int? runtimeTicks;
  final ImageTags imageTags;
  final List<String> backdropImageTags;
  final String? parentBackdropItemId;
  final List<String> parentBackdropImageTags;
  final String? seriesId;
  final String? seriesName;
  final String? seriesPrimaryImageTag;
  final String? seasonId;
  final String? seasonName;
  final int? indexNumber;
  final int? parentIndexNumber;
  final List<Person> people;
  final List<String> genres;
  final List<MediaSource> mediaSources;
  final List<Chapter> chapters;
  final UserData userData;
  final String? parentId;
  final String? collectionType;
  final int? childCount;
  final int? recursiveItemCount;
  final String? albumArtist;
  final List<String> artists;
  final String? album;
  final String? albumId;
  final String? albumPrimaryImageTag;
  final String? playlistItemId;
  final int? localTrailerCount;
  final String? primaryImageAspectRatio;

  const MediaItem({
    required this.id,
    required this.name,
    this.overview,
    this.kind = MediaKind.unknown,
    this.typeString,
    this.productionYear,
    this.premiereDate,
    this.officialRating,
    this.communityRating,
    this.runtimeTicks,
    this.imageTags = const ImageTags(),
    this.backdropImageTags = const [],
    this.parentBackdropItemId,
    this.parentBackdropImageTags = const [],
    this.seriesId,
    this.seriesName,
    this.seriesPrimaryImageTag,
    this.seasonId,
    this.seasonName,
    this.indexNumber,
    this.parentIndexNumber,
    this.people = const [],
    this.genres = const [],
    this.mediaSources = const [],
    this.chapters = const [],
    this.userData = const UserData(),
    this.parentId,
    this.collectionType,
    this.childCount,
    this.recursiveItemCount,
    this.albumArtist,
    this.artists = const [],
    this.album,
    this.albumId,
    this.albumPrimaryImageTag,
    this.playlistItemId,
    this.localTrailerCount,
    this.primaryImageAspectRatio,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
    id: json['Id'] as String,
    name: json['Name'] as String? ?? '',
    overview: json['Overview'] as String?,
    kind: MediaKind.fromString(json['Type'] as String?),
    typeString: json['Type'] as String?,
    productionYear: _int(json['ProductionYear']),
    premiereDate: json['PremiereDate'] as String?,
    officialRating: json['OfficialRating'] as String?,
    communityRating: _double(json['CommunityRating']),
    runtimeTicks: _int(json['RunTimeTicks']),
    imageTags: json['ImageTags'] != null
        ? ImageTags.fromJson(json['ImageTags'] as Map<String, dynamic>)
        : const ImageTags(),
    backdropImageTags: _stringList(json['BackdropImageTags']),
    parentBackdropItemId: json['ParentBackdropItemId'] as String?,
    parentBackdropImageTags: _stringList(json['ParentBackdropImageTags']),
    seriesId: json['SeriesId'] as String?,
    seriesName: json['SeriesName'] as String?,
    seriesPrimaryImageTag: json['SeriesPrimaryImageTag'] as String?,
    seasonId: json['SeasonId'] as String?,
    seasonName: json['SeasonName'] as String?,
    indexNumber: _int(json['IndexNumber']),
    parentIndexNumber: _int(json['ParentIndexNumber']),
    people:
        (json['People'] as List<dynamic>?)
            ?.map((e) => Person.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    genres: _stringList(json['Genres']),
    mediaSources:
        (json['MediaSources'] as List<dynamic>?)
            ?.map((e) => MediaSource.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    chapters:
        (json['Chapters'] as List<dynamic>?)
            ?.map((e) => Chapter.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    userData: json['UserData'] != null
        ? UserData.fromJson(json['UserData'] as Map<String, dynamic>)
        : const UserData(),
    parentId: json['ParentId'] as String?,
    collectionType: json['CollectionType'] as String?,
    childCount: _int(json['ChildCount']),
    recursiveItemCount: _int(json['RecursiveItemCount']),
    albumArtist: json['AlbumArtist'] as String?,
    artists: _stringList(json['Artists']),
    album: json['Album'] as String?,
    albumId: json['AlbumId'] as String?,
    albumPrimaryImageTag: json['AlbumPrimaryImageTag'] as String?,
    playlistItemId: json['PlaylistItemId'] as String?,
    localTrailerCount: _int(json['LocalTrailerCount']),
    primaryImageAspectRatio: json['PrimaryImageAspectRatio']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Name': name,
    'Overview': overview,
    'Type': typeString,
    'ProductionYear': productionYear,
    'PremiereDate': premiereDate,
    'OfficialRating': officialRating,
    'CommunityRating': communityRating,
    'RunTimeTicks': runtimeTicks,
    'ImageTags': imageTags.toJson(),
    'BackdropImageTags': backdropImageTags,
    'ParentBackdropItemId': parentBackdropItemId,
    'ParentBackdropImageTags': parentBackdropImageTags,
    'SeriesId': seriesId,
    'SeriesName': seriesName,
    'SeriesPrimaryImageTag': seriesPrimaryImageTag,
    'SeasonId': seasonId,
    'SeasonName': seasonName,
    'IndexNumber': indexNumber,
    'ParentIndexNumber': parentIndexNumber,
    'Genres': genres,
    'UserData': userData.toJson(),
    'ParentId': parentId,
    'CollectionType': collectionType,
    'ChildCount': childCount,
    'RecursiveItemCount': recursiveItemCount,
    'AlbumArtist': albumArtist,
    'Artists': artists,
    'Album': album,
    'AlbumId': albumId,
    'AlbumPrimaryImageTag': albumPrimaryImageTag,
    'PlaylistItemId': playlistItemId,
  };

  bool get isPlayable =>
      kind == MediaKind.movie ||
      kind == MediaKind.episode ||
      kind == MediaKind.audio ||
      kind == MediaKind.musicVideo;

  bool get isVideo =>
      kind == MediaKind.movie ||
      kind == MediaKind.episode ||
      kind == MediaKind.musicVideo;

  bool get isContainer =>
      kind == MediaKind.series ||
      kind == MediaKind.season ||
      kind == MediaKind.album ||
      kind == MediaKind.folder ||
      kind == MediaKind.collectionFolder ||
      kind == MediaKind.boxSet ||
      kind == MediaKind.playlist;

  bool get isPlayed => userData.played;
  bool get isFavorite => userData.isFavorite;

  int get resumeTicks => userData.playbackPositionTicks ?? 0;

  bool get hasProgress => resumeTicks > 0 && !isPlayed;

  double get progress {
    if (runtimeTicks == null || runtimeTicks == 0) return 0;
    return (resumeTicks / runtimeTicks!).clamp(0.0, 1.0);
  }

  String get runtimeLabel => formatRuntime(runtimeTicks);

  String get episodeLabel {
    if (kind != MediaKind.episode) return '';
    final s = parentIndexNumber != null ? 'S$parentIndexNumber' : '';
    final e = indexNumber != null ? 'E$indexNumber' : '';
    return '$s $e'.trim();
  }

  /// Title for large hero surfaces: "Show - Episode" for episodes.
  String get displayTitle {
    if (kind == MediaKind.episode && seriesName != null) {
      return '$seriesName - $name';
    }
    return name;
  }

  String? get metaLine {
    final parts = <String>[
      if (productionYear != null) '$productionYear',
      if (officialRating != null) officialRating!,
      if (runtimeLabel.isNotEmpty) runtimeLabel,
    ];
    return parts.isEmpty ? null : parts.join('  •  ');
  }

  MediaItem copyWith({UserData? userData}) => MediaItem(
    id: id,
    name: name,
    overview: overview,
    kind: kind,
    typeString: typeString,
    productionYear: productionYear,
    premiereDate: premiereDate,
    officialRating: officialRating,
    communityRating: communityRating,
    runtimeTicks: runtimeTicks,
    imageTags: imageTags,
    backdropImageTags: backdropImageTags,
    parentBackdropItemId: parentBackdropItemId,
    parentBackdropImageTags: parentBackdropImageTags,
    seriesId: seriesId,
    seriesName: seriesName,
    seriesPrimaryImageTag: seriesPrimaryImageTag,
    seasonId: seasonId,
    seasonName: seasonName,
    indexNumber: indexNumber,
    parentIndexNumber: parentIndexNumber,
    people: people,
    genres: genres,
    mediaSources: mediaSources,
    chapters: chapters,
    userData: userData ?? this.userData,
    parentId: parentId,
    collectionType: collectionType,
    childCount: childCount,
    recursiveItemCount: recursiveItemCount,
    albumArtist: albumArtist,
    artists: artists,
    album: album,
    albumId: albumId,
    albumPrimaryImageTag: albumPrimaryImageTag,
    playlistItemId: playlistItemId,
    localTrailerCount: localTrailerCount,
    primaryImageAspectRatio: primaryImageAspectRatio,
  );
}
