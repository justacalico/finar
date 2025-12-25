import 'package:hive/hive.dart';

part 'media_item.g.dart';

/// Helper to safely parse int from JSON (handles String and num)
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Helper to safely parse double from JSON (handles String and num)
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Enum for media types
@HiveType(typeId: 10)
enum MediaType {
  @HiveField(0)
  movie,
  @HiveField(1)
  series,
  @HiveField(2)
  season,
  @HiveField(3)
  episode,
  @HiveField(4)
  audio,
  @HiveField(5)
  album,
  @HiveField(6)
  artist,
  @HiveField(7)
  photo,
  @HiveField(8)
  folder,
  @HiveField(9)
  collectionFolder,
  @HiveField(10)
  musicVideo,
  @HiveField(11)
  boxSet,
  @HiveField(12)
  playlist,
  @HiveField(13)
  unknown,
}

MediaType mediaTypeFromString(String? type) {
  switch (type?.toLowerCase()) {
    case 'movie':
      return MediaType.movie;
    case 'series':
      return MediaType.series;
    case 'season':
      return MediaType.season;
    case 'episode':
      return MediaType.episode;
    case 'audio':
      return MediaType.audio;
    case 'musicalbum':
    case 'album':
      return MediaType.album;
    case 'musicartist':
    case 'artist':
      return MediaType.artist;
    case 'photo':
      return MediaType.photo;
    case 'folder':
      return MediaType.folder;
    case 'collectionfolder':
      return MediaType.collectionFolder;
    case 'musicvideo':
      return MediaType.musicVideo;
    case 'boxset':
      return MediaType.boxSet;
    case 'playlist':
      return MediaType.playlist;
    default:
      return MediaType.unknown;
  }
}

@HiveType(typeId: 4)
class MediaItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? originalTitle;

  @HiveField(3)
  final String? sortName;

  @HiveField(4)
  final String? overview;

  @HiveField(5)
  final MediaType type;

  @HiveField(6)
  final String? typeString;

  @HiveField(7)
  final int? productionYear;

  @HiveField(8)
  final String? premiereDate;

  @HiveField(9)
  final String? officialRating;

  @HiveField(10)
  final double? communityRating;

  @HiveField(11)
  final double? criticRating;

  @HiveField(12)
  final int? runtimeTicks;

  @HiveField(13)
  final int? playbackPositionTicks;

  @HiveField(14)
  final bool? isPlayed;

  @HiveField(15)
  final bool? isFavorite;

  @HiveField(16)
  final String? seriesId;

  @HiveField(17)
  final String? seriesName;

  @HiveField(18)
  final String? seasonId;

  @HiveField(19)
  final String? seasonName;

  @HiveField(20)
  final int? indexNumber;

  @HiveField(21)
  final int? parentIndexNumber;

  @HiveField(22)
  final ImageTags? imageTags;

  @HiveField(23)
  final List<String>? backdropImageTags;

  @HiveField(24)
  final String? parentBackdropItemId;

  @HiveField(25)
  final List<String>? parentBackdropImageTags;

  @HiveField(26)
  final List<PersonInfo>? people;

  @HiveField(27)
  final List<String>? genres;

  @HiveField(28)
  final List<MediaStream>? mediaStreams;

  @HiveField(29)
  final UserData? userData;

  @HiveField(30)
  final String? container;

  @HiveField(31)
  final String? path;

  @HiveField(32)
  final int? childCount;

  @HiveField(33)
  final int? recursiveItemCount;

  @HiveField(34)
  final String? collectionType;

  @HiveField(35)
  final List<ChapterInfo>? chapters;

  @HiveField(36)
  final String? parentId;

  @HiveField(37)
  final MediaSourceInfo? mediaSourceInfo;

  @HiveField(38)
  final List<MediaSourceInfo>? mediaSources;

  // Music-specific fields
  @HiveField(39)
  final String? albumArtist;

  @HiveField(40)
  final List<String>? artists;

  @HiveField(41)
  final String? album;

  @HiveField(42)
  final String? albumId;

  @HiveField(43)
  final String? playlistItemId;

  @HiveField(44)
  final int? localTrailerCount;

  @HiveField(45)
  final List<TrailerInfo>? remoteTrailers;

  const MediaItem({
    required this.id,
    required this.name,
    this.originalTitle,
    this.sortName,
    this.overview,
    this.type = MediaType.unknown,
    this.typeString,
    this.productionYear,
    this.premiereDate,
    this.officialRating,
    this.communityRating,
    this.criticRating,
    this.runtimeTicks,
    this.playbackPositionTicks,
    this.isPlayed,
    this.isFavorite,
    this.seriesId,
    this.seriesName,
    this.seasonId,
    this.seasonName,
    this.indexNumber,
    this.parentIndexNumber,
    this.imageTags,
    this.backdropImageTags,
    this.parentBackdropItemId,
    this.parentBackdropImageTags,
    this.people,
    this.genres,
    this.mediaStreams,
    this.userData,
    this.container,
    this.path,
    this.childCount,
    this.recursiveItemCount,
    this.collectionType,
    this.chapters,
    this.parentId,
    this.mediaSourceInfo,
    this.mediaSources,
    this.albumArtist,
    this.artists,
    this.album,
    this.albumId,
    this.playlistItemId,
    this.localTrailerCount,
    this.remoteTrailers,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['Id'] as String,
      name: json['Name'] as String? ?? '',
      originalTitle: json['OriginalTitle'] as String?,
      sortName: json['SortName'] as String?,
      overview: json['Overview'] as String?,
      type: mediaTypeFromString(json['Type'] as String?),
      typeString: json['Type'] as String?,
      productionYear: _parseInt(json['ProductionYear']),
      premiereDate: json['PremiereDate'] as String?,
      officialRating: json['OfficialRating'] as String?,
      communityRating: _parseDouble(json['CommunityRating']),
      criticRating: _parseDouble(json['CriticRating']),
      runtimeTicks: _parseInt(json['RunTimeTicks']),
      playbackPositionTicks: _parseInt(json['PlaybackPositionTicks']),
      isPlayed: json['IsPlayed'] as bool?,
      isFavorite: json['IsFavorite'] as bool?,
      seriesId: json['SeriesId'] as String?,
      seriesName: json['SeriesName'] as String?,
      seasonId: json['SeasonId'] as String?,
      seasonName: json['SeasonName'] as String?,
      indexNumber: _parseInt(json['IndexNumber']),
      parentIndexNumber: _parseInt(json['ParentIndexNumber']),
      imageTags: json['ImageTags'] != null
          ? ImageTags.fromJson(json['ImageTags'] as Map<String, dynamic>)
          : null,
      backdropImageTags: (json['BackdropImageTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      parentBackdropItemId: json['ParentBackdropItemId'] as String?,
      parentBackdropImageTags: (json['ParentBackdropImageTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      people: (json['People'] as List<dynamic>?)
          ?.map((e) => PersonInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      genres: (json['Genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
      mediaStreams: (json['MediaStreams'] as List<dynamic>?)
          ?.map((e) => MediaStream.fromJson(e as Map<String, dynamic>))
          .toList(),
      userData: json['UserData'] != null
          ? UserData.fromJson(json['UserData'] as Map<String, dynamic>)
          : null,
      container: json['Container'] as String?,
      path: json['Path'] as String?,
      childCount: _parseInt(json['ChildCount']),
      recursiveItemCount: _parseInt(json['RecursiveItemCount']),
      collectionType: json['CollectionType'] as String?,
      chapters: (json['Chapters'] as List<dynamic>?)
          ?.map((e) => ChapterInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      parentId: json['ParentId'] as String?,
      mediaSources: (json['MediaSources'] as List<dynamic>?)
          ?.map((e) => MediaSourceInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      // Music-specific fields
      albumArtist: json['AlbumArtist'] as String?,
      artists: (json['Artists'] as List<dynamic>?)?.map((e) => e as String).toList(),
      album: json['Album'] as String?,
      albumId: json['AlbumId'] as String?,
      playlistItemId: json['PlaylistItemId'] as String?,
      localTrailerCount: _parseInt(json['LocalTrailerCount']),
      remoteTrailers: (json['RemoteTrailers'] as List<dynamic>?)
          ?.map((e) => TrailerInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'OriginalTitle': originalTitle,
      'SortName': sortName,
      'Overview': overview,
      'Type': typeString,
      'ProductionYear': productionYear,
      'PremiereDate': premiereDate,
      'OfficialRating': officialRating,
      'CommunityRating': communityRating,
      'CriticRating': criticRating,
      'RunTimeTicks': runtimeTicks,
      'PlaybackPositionTicks': playbackPositionTicks,
      'IsPlayed': isPlayed,
      'IsFavorite': isFavorite,
      'SeriesId': seriesId,
      'SeriesName': seriesName,
      'SeasonId': seasonId,
      'SeasonName': seasonName,
      'IndexNumber': indexNumber,
      'ParentIndexNumber': parentIndexNumber,
      'ImageTags': imageTags?.toJson(),
      'BackdropImageTags': backdropImageTags,
      'ParentBackdropItemId': parentBackdropItemId,
      'ParentBackdropImageTags': parentBackdropImageTags,
      'People': people?.map((e) => e.toJson()).toList(),
      'Genres': genres,
      'MediaStreams': mediaStreams?.map((e) => e.toJson()).toList(),
      'UserData': userData?.toJson(),
      'Container': container,
      'Path': path,
      'ChildCount': childCount,
      'RecursiveItemCount': recursiveItemCount,
      'CollectionType': collectionType,
      'Chapters': chapters?.map((e) => e.toJson()).toList(),
      'ParentId': parentId,
      'MediaSources': mediaSources?.map((e) => e.toJson()).toList(),
      // Music-specific fields
      'AlbumArtist': albumArtist,
      'Artists': artists,
      'Album': album,
      'AlbumId': albumId,
      'PlaylistItemId': playlistItemId,
    };
  }

  /// Get primary image URL (the episode's own thumbnail for episodes)
  String getPrimaryImageUrl(String baseUrl, {int? width, int? height, int? quality}) {
    final tag = imageTags?.primary;
    if (tag == null) return '';
    
    final params = <String>[];
    if (width != null) params.add('maxWidth=$width');
    if (height != null) params.add('maxHeight=$height');
    if (quality != null) params.add('quality=$quality');
    params.add('tag=$tag');
    
    return '$baseUrl/Items/$id/Images/Primary?${params.join('&')}';
  }

  /// Get display image URL - for episodes, returns the series poster instead of episode thumbnail
  String getDisplayImageUrl(String baseUrl, {int? width, int? height, int? quality}) {
    // For episodes, use the series poster
    if (type == MediaType.episode && seriesId != null) {
      final params = <String>[];
      if (width != null) params.add('maxWidth=$width');
      if (height != null) params.add('maxHeight=$height');
      if (quality != null) params.add('quality=$quality');
      
      return '$baseUrl/Items/$seriesId/Images/Primary?${params.join('&')}';
    }
    
    // For other types, use the regular primary image
    return getPrimaryImageUrl(baseUrl, width: width, height: height, quality: quality);
  }

  /// Get backdrop image URL
  String getBackdropUrl(String baseUrl, {int index = 0, int? width, int? quality}) {
    String? tag;
    String itemId = id;
    
    if (backdropImageTags != null && backdropImageTags!.isNotEmpty) {
      tag = backdropImageTags![index.clamp(0, backdropImageTags!.length - 1)];
    } else if (parentBackdropImageTags != null && parentBackdropImageTags!.isNotEmpty) {
      tag = parentBackdropImageTags![index.clamp(0, parentBackdropImageTags!.length - 1)];
      itemId = parentBackdropItemId ?? id;
    }
    
    if (tag == null) return '';
    
    final params = <String>[];
    if (width != null) params.add('maxWidth=$width');
    if (quality != null) params.add('quality=$quality');
    params.add('tag=$tag');
    
    return '$baseUrl/Items/$itemId/Images/Backdrop/$index?${params.join('&')}';
  }

  /// Get thumb image URL
  String getThumbUrl(String baseUrl, {int? width, int? height, int? quality}) {
    final tag = imageTags?.thumb;
    if (tag == null) return getBackdropUrl(baseUrl, width: width, quality: quality);
    
    final params = <String>[];
    if (width != null) params.add('maxWidth=$width');
    if (height != null) params.add('maxHeight=$height');
    if (quality != null) params.add('quality=$quality');
    params.add('tag=$tag');
    
    return '$baseUrl/Items/$id/Images/Thumb?${params.join('&')}';
  }

  /// Get runtime in human readable format
  String get formattedRuntime {
    if (runtimeTicks == null) return '';
    final minutes = (runtimeTicks! / 600000000).round();
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  /// Get playback progress percentage
  double get playbackProgress {
    if (runtimeTicks == null || runtimeTicks == 0) return 0;
    final position = userData?.playbackPositionTicks ?? playbackPositionTicks ?? 0;
    return (position / runtimeTicks!).clamp(0.0, 1.0);
  }

  /// Get episode label (e.g., "S1 E5")
  String get episodeLabel {
    if (type != MediaType.episode) return '';
    final season = parentIndexNumber != null ? 'S$parentIndexNumber' : '';
    final episode = indexNumber != null ? 'E$indexNumber' : '';
    return '$season $episode'.trim();
  }

  /// Check if item has playable media
  bool get isPlayable {
    return type == MediaType.movie ||
        type == MediaType.episode ||
        type == MediaType.audio ||
        type == MediaType.musicVideo;
  }

  /// Check if item is a container (folder, series, etc.)
  bool get isContainer {
    return type == MediaType.series ||
        type == MediaType.season ||
        type == MediaType.album ||
        type == MediaType.folder ||
        type == MediaType.collectionFolder ||
        type == MediaType.boxSet ||
        type == MediaType.playlist;
  }

  /// Check if item has progress (partially watched)
  bool get hasProgress {
    final position = userData?.playbackPositionTicks ?? playbackPositionTicks ?? 0;
    return position > 0 && (isPlayed != true);
  }

  /// Get progress percentage (0.0 - 1.0)
  double get progressPercent {
    return playbackProgress;
  }

  /// Get backdrop image URL with width parameter
  String getBackdropImageUrl(String baseUrl, {int? width, int? quality}) {
    return getBackdropUrl(baseUrl, width: width, quality: quality);
  }

  /// Get logo image tag
  String? get logoImageTag => imageTags?.logo;

  /// Check if item has a trailer
  bool get hasTrailer {
    return (localTrailerCount != null && localTrailerCount! > 0) ||
           (remoteTrailers != null && remoteTrailers!.isNotEmpty);
  }

  /// Get taglines (from overview or empty)
  List<String>? get taglines => null;

  /// Get studios (would require additional API field)
  List<String>? get studios => null;
}

@HiveType(typeId: 5)
class ImageTags {
  @HiveField(0)
  final String? primary;

  @HiveField(1)
  final String? logo;

  @HiveField(2)
  final String? thumb;

  @HiveField(3)
  final String? art;

  @HiveField(4)
  final String? banner;

  @HiveField(5)
  final String? backdrop;

  const ImageTags({
    this.primary,
    this.logo,
    this.thumb,
    this.art,
    this.banner,
    this.backdrop,
  });

  factory ImageTags.fromJson(Map<String, dynamic> json) {
    return ImageTags(
      primary: json['Primary'] as String?,
      logo: json['Logo'] as String?,
      thumb: json['Thumb'] as String?,
      art: json['Art'] as String?,
      banner: json['Banner'] as String?,
      backdrop: json['Backdrop'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Primary': primary,
      'Logo': logo,
      'Thumb': thumb,
      'Art': art,
      'Banner': banner,
      'Backdrop': backdrop,
    };
  }
}

@HiveType(typeId: 6)
class PersonInfo {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? role;

  @HiveField(3)
  final String? type;

  @HiveField(4)
  final String? primaryImageTag;

  const PersonInfo({
    required this.id,
    required this.name,
    this.role,
    this.type,
    this.primaryImageTag,
  });

  factory PersonInfo.fromJson(Map<String, dynamic> json) {
    return PersonInfo(
      id: json['Id'] as String,
      name: json['Name'] as String,
      role: json['Role'] as String?,
      type: json['Type'] as String?,
      primaryImageTag: json['PrimaryImageTag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Role': role,
      'Type': type,
      'PrimaryImageTag': primaryImageTag,
    };
  }

  String getImageUrl(String baseUrl, {int? width, int? height}) {
    if (primaryImageTag == null) return '';
    final params = <String>[];
    if (width != null) params.add('maxWidth=$width');
    if (height != null) params.add('maxHeight=$height');
    params.add('tag=$primaryImageTag');
    return '$baseUrl/Items/$id/Images/Primary?${params.join('&')}';
  }
}

@HiveType(typeId: 7)
class MediaStream {
  @HiveField(0)
  final String? codec;

  @HiveField(1)
  final String? codecTag;

  @HiveField(2)
  final String? language;

  @HiveField(3)
  final String? displayTitle;

  @HiveField(4)
  final String? title;

  @HiveField(5)
  final String type;

  @HiveField(6)
  final int index;

  @HiveField(7)
  final bool? isDefault;

  @HiveField(8)
  final bool? isForced;

  @HiveField(9)
  final bool? isExternal;

  @HiveField(10)
  final int? width;

  @HiveField(11)
  final int? height;

  @HiveField(12)
  final double? aspectRatio;

  @HiveField(13)
  final int? bitRate;

  @HiveField(14)
  final int? channels;

  @HiveField(15)
  final int? sampleRate;

  @HiveField(16)
  final String? deliveryUrl;

  @HiveField(17)
  final String? path;

  const MediaStream({
    this.codec,
    this.codecTag,
    this.language,
    this.displayTitle,
    this.title,
    required this.type,
    required this.index,
    this.isDefault,
    this.isForced,
    this.isExternal,
    this.width,
    this.height,
    this.aspectRatio,
    this.bitRate,
    this.channels,
    this.sampleRate,
    this.deliveryUrl,
    this.path,
  });

  factory MediaStream.fromJson(Map<String, dynamic> json) {
    return MediaStream(
      codec: json['Codec'] as String?,
      codecTag: json['CodecTag'] as String?,
      language: json['Language'] as String?,
      displayTitle: json['DisplayTitle'] as String?,
      title: json['Title'] as String?,
      type: json['Type'] as String? ?? 'Unknown',
      index: _parseInt(json['Index']) ?? 0,
      isDefault: json['IsDefault'] as bool?,
      isForced: json['IsForced'] as bool?,
      isExternal: json['IsExternal'] as bool?,
      width: _parseInt(json['Width']),
      height: _parseInt(json['Height']),
      aspectRatio: _parseDouble(json['AspectRatio']),
      bitRate: _parseInt(json['BitRate']),
      channels: _parseInt(json['Channels']),
      sampleRate: _parseInt(json['SampleRate']),
      deliveryUrl: json['DeliveryUrl'] as String?,
      path: json['Path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Codec': codec,
      'CodecTag': codecTag,
      'Language': language,
      'DisplayTitle': displayTitle,
      'Title': title,
      'Type': type,
      'Index': index,
      'IsDefault': isDefault,
      'IsForced': isForced,
      'IsExternal': isExternal,
      'Width': width,
      'Height': height,
      'AspectRatio': aspectRatio,
      'BitRate': bitRate,
      'Channels': channels,
      'SampleRate': sampleRate,
      'DeliveryUrl': deliveryUrl,
      'Path': path,
    };
  }

  bool get isVideo => type == 'Video';
  bool get isAudio => type == 'Audio';
  bool get isSubtitle => type == 'Subtitle';

  /// Get video resolution string (e.g., "1080p", "4K")
  String? get videoResolution {
    if (!isVideo || height == null) return null;
    if (height! >= 2160) return '4K';
    if (height! >= 1440) return '1440p';
    if (height! >= 1080) return '1080p';
    if (height! >= 720) return '720p';
    if (height! >= 480) return '480p';
    return '${height}p';
  }

  /// Get channel layout string (e.g., "5.1", "7.1", "Stereo")
  String? get channelLayout {
    if (!isAudio || channels == null) return null;
    switch (channels) {
      case 1:
        return 'Mono';
      case 2:
        return 'Stereo';
      case 6:
        return '5.1';
      case 8:
        return '7.1';
      default:
        return '$channels ch';
    }
  }
}

@HiveType(typeId: 8)
class UserData {
  @HiveField(0)
  final double? playedPercentage;

  @HiveField(1)
  final int playbackPositionTicks;

  @HiveField(2)
  final int playCount;

  @HiveField(3)
  final bool isFavorite;

  @HiveField(4)
  final bool played;

  @HiveField(5)
  final String? lastPlayedDate;

  @HiveField(6)
  final int? unplayedItemCount;

  const UserData({
    this.playedPercentage,
    this.playbackPositionTicks = 0,
    this.playCount = 0,
    this.isFavorite = false,
    this.played = false,
    this.lastPlayedDate,
    this.unplayedItemCount,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      playedPercentage: _parseDouble(json['PlayedPercentage']),
      playbackPositionTicks: _parseInt(json['PlaybackPositionTicks']) ?? 0,
      playCount: _parseInt(json['PlayCount']) ?? 0,
      isFavorite: json['IsFavorite'] as bool? ?? false,
      played: json['Played'] as bool? ?? false,
      lastPlayedDate: json['LastPlayedDate'] as String?,
      unplayedItemCount: _parseInt(json['UnplayedItemCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PlayedPercentage': playedPercentage,
      'PlaybackPositionTicks': playbackPositionTicks,
      'PlayCount': playCount,
      'IsFavorite': isFavorite,
      'Played': played,
      'LastPlayedDate': lastPlayedDate,
      'UnplayedItemCount': unplayedItemCount,
    };
  }
}

@HiveType(typeId: 9)
class ChapterInfo {
  @HiveField(0)
  final int startPositionTicks;

  @HiveField(1)
  final String? name;

  @HiveField(2)
  final String? imagePath;

  @HiveField(3)
  final String? imageTag;

  const ChapterInfo({
    required this.startPositionTicks,
    this.name,
    this.imagePath,
    this.imageTag,
  });

  factory ChapterInfo.fromJson(Map<String, dynamic> json) {
    return ChapterInfo(
      startPositionTicks: _parseInt(json['StartPositionTicks']) ?? 0,
      name: json['Name'] as String?,
      imagePath: json['ImagePath'] as String?,
      imageTag: json['ImageTag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'StartPositionTicks': startPositionTicks,
      'Name': name,
      'ImagePath': imagePath,
      'ImageTag': imageTag,
    };
  }

  String get formattedTime {
    final seconds = startPositionTicks ~/ 10000000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return '$hours:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

@HiveType(typeId: 11)
class MediaSourceInfo {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? name;

  @HiveField(2)
  final String? path;

  @HiveField(3)
  final String? container;

  @HiveField(4)
  final int? size;

  @HiveField(5)
  final int? bitrate;

  @HiveField(6)
  final bool? supportsDirectPlay;

  @HiveField(7)
  final bool? supportsDirectStream;

  @HiveField(8)
  final bool? supportsTranscoding;

  @HiveField(9)
  final String? directStreamUrl;

  @HiveField(10)
  final String? transcodingUrl;

  @HiveField(11)
  final List<MediaStream>? mediaStreams;

  @HiveField(12)
  final int? defaultAudioStreamIndex;

  @HiveField(13)
  final int? defaultSubtitleStreamIndex;

  const MediaSourceInfo({
    required this.id,
    this.name,
    this.path,
    this.container,
    this.size,
    this.bitrate,
    this.supportsDirectPlay,
    this.supportsDirectStream,
    this.supportsTranscoding,
    this.directStreamUrl,
    this.transcodingUrl,
    this.mediaStreams,
    this.defaultAudioStreamIndex,
    this.defaultSubtitleStreamIndex,
  });

  factory MediaSourceInfo.fromJson(Map<String, dynamic> json) {
    return MediaSourceInfo(
      id: json['Id'] as String,
      name: json['Name'] as String?,
      path: json['Path'] as String?,
      container: json['Container'] as String?,
      size: _parseInt(json['Size']),
      bitrate: _parseInt(json['Bitrate']),
      supportsDirectPlay: json['SupportsDirectPlay'] as bool?,
      supportsDirectStream: json['SupportsDirectStream'] as bool?,
      supportsTranscoding: json['SupportsTranscoding'] as bool?,
      directStreamUrl: json['DirectStreamUrl'] as String?,
      transcodingUrl: json['TranscodingUrl'] as String?,
      mediaStreams: (json['MediaStreams'] as List<dynamic>?)
          ?.map((e) => MediaStream.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultAudioStreamIndex: _parseInt(json['DefaultAudioStreamIndex']),
      defaultSubtitleStreamIndex: _parseInt(json['DefaultSubtitleStreamIndex']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Path': path,
      'Container': container,
      'Size': size,
      'Bitrate': bitrate,
      'SupportsDirectPlay': supportsDirectPlay,
      'SupportsDirectStream': supportsDirectStream,
      'SupportsTranscoding': supportsTranscoding,
      'DirectStreamUrl': directStreamUrl,
      'TranscodingUrl': transcodingUrl,
      'MediaStreams': mediaStreams?.map((e) => e.toJson()).toList(),
      'DefaultAudioStreamIndex': defaultAudioStreamIndex,
      'DefaultSubtitleStreamIndex': defaultSubtitleStreamIndex,
    };
  }

  /// Get video streams
  List<MediaStream> get videoStreams =>
      mediaStreams?.where((s) => s.isVideo).toList() ?? [];

  /// Get audio streams
  List<MediaStream> get audioStreams =>
      mediaStreams?.where((s) => s.isAudio).toList() ?? [];

  /// Get subtitle streams
  List<MediaStream> get subtitleStreams =>
      mediaStreams?.where((s) => s.isSubtitle).toList() ?? [];
}

/// Remote trailer info
class TrailerInfo {
  final String? url;
  final String? name;

  const TrailerInfo({
    this.url,
    this.name,
  });

  factory TrailerInfo.fromJson(Map<String, dynamic> json) {
    return TrailerInfo(
      url: json['Url'] as String?,
      name: json['Name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Url': url,
      'Name': name,
    };
  }
}
