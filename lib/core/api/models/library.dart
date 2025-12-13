import 'package:hive/hive.dart';

part 'library.g.dart';

/// Helper to safely parse int from JSON (handles String and num)
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

@HiveType(typeId: 12)
class Library {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? collectionType;

  @HiveField(3)
  final String? primaryImageTag;

  @HiveField(4)
  final int? childCount;

  @HiveField(5)
  final bool isFolder;

  @HiveField(6)
  final String? backdropImageTag;

  const Library({
    required this.id,
    required this.name,
    this.collectionType,
    this.primaryImageTag,
    this.childCount,
    this.isFolder = true,
    this.backdropImageTag,
  });

  factory Library.fromJson(Map<String, dynamic> json) {
    return Library(
      id: json['Id'] as String,
      name: json['Name'] as String,
      collectionType: json['CollectionType'] as String?,
      primaryImageTag: json['ImageTags']?['Primary'] as String?,
      childCount: _parseInt(json['ChildCount']),
      isFolder: json['IsFolder'] as bool? ?? true,
      backdropImageTag: (json['BackdropImageTags'] as List<dynamic>?)?.firstOrNull as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'CollectionType': collectionType,
      'PrimaryImageTag': primaryImageTag,
      'ChildCount': childCount,
      'IsFolder': isFolder,
      'BackdropImageTag': backdropImageTag,
    };
  }

  String getPrimaryImageUrl(String baseUrl, {int? width, int? height}) {
    if (primaryImageTag == null) return '';
    final params = <String>[];
    if (width != null) params.add('maxWidth=$width');
    if (height != null) params.add('maxHeight=$height');
    params.add('tag=$primaryImageTag');
    return '$baseUrl/Items/$id/Images/Primary?${params.join('&')}';
  }

  String getBackdropUrl(String baseUrl, {int? width}) {
    if (backdropImageTag == null) return '';
    final params = <String>[];
    if (width != null) params.add('maxWidth=$width');
    params.add('tag=$backdropImageTag');
    return '$baseUrl/Items/$id/Images/Backdrop?${params.join('&')}';
  }

  /// Get the icon for this library type
  LibraryIcon get icon {
    switch (collectionType?.toLowerCase()) {
      case 'movies':
        return LibraryIcon.movies;
      case 'tvshows':
        return LibraryIcon.tvShows;
      case 'music':
        return LibraryIcon.music;
      case 'photos':
        return LibraryIcon.photos;
      case 'boxsets':
      case 'collections':
        return LibraryIcon.collections;
      case 'homevideos':
        return LibraryIcon.homeVideos;
      case 'playlists':
        return LibraryIcon.playlists;
      case 'livetv':
        return LibraryIcon.liveTv;
      case 'books':
        return LibraryIcon.books;
      default:
        return LibraryIcon.folder;
    }
  }
}

enum LibraryIcon {
  movies,
  tvShows,
  music,
  photos,
  collections,
  homeVideos,
  playlists,
  liveTv,
  books,
  folder,
}

@HiveType(typeId: 13)
class ServerInfo {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String? version;

  @HiveField(4)
  final String? operatingSystem;

  @HiveField(5)
  final bool hasUpdateAvailable;

  @HiveField(6)
  final String? localAddress;

  @HiveField(7)
  final String? wanAddress;

  const ServerInfo({
    required this.id,
    required this.name,
    required this.url,
    this.version,
    this.operatingSystem,
    this.hasUpdateAvailable = false,
    this.localAddress,
    this.wanAddress,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json, String serverUrl) {
    return ServerInfo(
      id: json['Id'] as String? ?? '',
      name: json['ServerName'] as String? ?? 'Jellyfin Server',
      url: serverUrl,
      version: json['Version'] as String?,
      operatingSystem: json['OperatingSystem'] as String?,
      hasUpdateAvailable: json['HasUpdateAvailable'] as bool? ?? false,
      localAddress: json['LocalAddress'] as String?,
      wanAddress: json['WanAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'ServerName': name,
      'Url': url,
      'Version': version,
      'OperatingSystem': operatingSystem,
      'HasUpdateAvailable': hasUpdateAvailable,
      'LocalAddress': localAddress,
      'WanAddress': wanAddress,
    };
  }
}

/// Search hints model for quick search
@HiveType(typeId: 14)
class SearchHint {
  @HiveField(0)
  final String itemId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? type;

  @HiveField(3)
  final int? productionYear;

  @HiveField(4)
  final String? primaryImageTag;

  @HiveField(5)
  final String? thumbImageTag;

  @HiveField(6)
  final String? backdropImageTag;

  @HiveField(7)
  final String? series;

  @HiveField(8)
  final String? album;

  @HiveField(9)
  final String? albumArtist;

  @HiveField(10)
  final int? indexNumber;

  @HiveField(11)
  final int? parentIndexNumber;

  const SearchHint({
    required this.itemId,
    required this.name,
    this.type,
    this.productionYear,
    this.primaryImageTag,
    this.thumbImageTag,
    this.backdropImageTag,
    this.series,
    this.album,
    this.albumArtist,
    this.indexNumber,
    this.parentIndexNumber,
  });

  factory SearchHint.fromJson(Map<String, dynamic> json) {
    return SearchHint(
      itemId: json['ItemId'] as String,
      name: json['Name'] as String,
      type: json['Type'] as String?,
      productionYear: _parseInt(json['ProductionYear']),
      primaryImageTag: json['PrimaryImageTag'] as String?,
      thumbImageTag: json['ThumbImageTag'] as String?,
      backdropImageTag: json['BackdropImageTag'] as String?,
      series: json['Series'] as String?,
      album: json['Album'] as String?,
      albumArtist: json['AlbumArtist'] as String?,
      indexNumber: _parseInt(json['IndexNumber']),
      parentIndexNumber: _parseInt(json['ParentIndexNumber']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ItemId': itemId,
      'Name': name,
      'Type': type,
      'ProductionYear': productionYear,
      'PrimaryImageTag': primaryImageTag,
      'ThumbImageTag': thumbImageTag,
      'BackdropImageTag': backdropImageTag,
      'Series': series,
      'Album': album,
      'AlbumArtist': albumArtist,
      'IndexNumber': indexNumber,
      'ParentIndexNumber': parentIndexNumber,
    };
  }

  String getPrimaryImageUrl(String baseUrl, {int? width, int? height}) {
    if (primaryImageTag == null) return '';
    final params = <String>[];
    if (width != null) params.add('maxWidth=$width');
    if (height != null) params.add('maxHeight=$height');
    params.add('tag=$primaryImageTag');
    return '$baseUrl/Items/$itemId/Images/Primary?${params.join('&')}';
  }
}
