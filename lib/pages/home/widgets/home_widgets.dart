import 'package:flutter/material.dart';
import 'package:finar/core/api/models/library.dart';
import 'package:finar/core/api/models/media_item.dart';

String? getItemSubtitle(MediaItem item) {
  switch (item.type) {
    case MediaType.episode:
      if (item.seriesName != null) {
        final season = item.parentIndexNumber ?? 0;
        final episode = item.indexNumber ?? 0;
        return '${item.seriesName} • S${season}E$episode';
      }
      return item.productionYear?.toString();
    case MediaType.audio:
      return item.albumArtist ?? item.album ?? item.productionYear?.toString();
    case MediaType.album:
      return item.albumArtist ?? item.productionYear?.toString();
    case MediaType.season:
      return item.seriesName;
    default:
      return item.productionYear?.toString();
  }
}

String getVideoSubtitle(MediaItem item) {
  final parts = <String>[];
  if (item.seriesName != null) {
    parts.add(item.seriesName!);
    if (item.parentIndexNumber != null && item.indexNumber != null) {
      parts.add('S${item.parentIndexNumber}E${item.indexNumber}');
    }
  } else if (item.productionYear != null) {
    parts.add(item.productionYear.toString());
  }
  return parts.join(' • ');
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

Map<String, List<MediaItem>> groupMediaByType(List<MediaItem> items) {
  final Map<String, List<MediaItem>> grouped = {};

  for (final item in items) {
    final category = getMediaCategory(item.type);
    grouped.putIfAbsent(category, () => []);
    grouped[category]!.add(item);
  }

  for (final category in grouped.keys) {
    grouped[category]!.sort((a, b) => a.name.compareTo(b.name));
  }

  return grouped;
}

String getMediaCategory(MediaType type) {
  switch (type) {
    case MediaType.movie:
      return 'Movies';
    case MediaType.series:
      return 'TV Shows';
    case MediaType.episode:
      return 'Episodes';
    case MediaType.season:
      return 'Seasons';
    case MediaType.audio:
    case MediaType.album:
    case MediaType.artist:
    case MediaType.musicVideo:
      return 'Music';
    case MediaType.playlist:
      return 'Playlists';
    case MediaType.boxSet:
      return 'Collections';
    default:
      return 'Other';
  }
}

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Movies':
      return Icons.movie_outlined;
    case 'TV Shows':
      return Icons.tv_outlined;
    case 'Episodes':
      return Icons.video_library_outlined;
    case 'Seasons':
      return Icons.folder_outlined;
    case 'Music':
      return Icons.music_note_outlined;
    case 'Playlists':
      return Icons.playlist_play_outlined;
    case 'Collections':
      return Icons.collections_bookmark_outlined;
    default:
      return Icons.folder_outlined;
  }
}

IconData getLibraryIcon(LibraryIcon icon) {
  switch (icon) {
    case LibraryIcon.movies:
      return Icons.movie_outlined;
    case LibraryIcon.tvShows:
      return Icons.tv_outlined;
    case LibraryIcon.music:
      return Icons.music_note_outlined;
    case LibraryIcon.photos:
      return Icons.photo_library_outlined;
    case LibraryIcon.collections:
      return Icons.collections_outlined;
    case LibraryIcon.homeVideos:
      return Icons.videocam_outlined;
    case LibraryIcon.playlists:
      return Icons.playlist_play_outlined;
    case LibraryIcon.liveTv:
      return Icons.live_tv_outlined;
    case LibraryIcon.books:
      return Icons.book_outlined;
    case LibraryIcon.folder:
      return Icons.folder_outlined;
  }
}

MediaType getMediaTypeFromString(String? typeString) {
  switch (typeString?.toLowerCase()) {
    case 'movie':
      return MediaType.movie;
    case 'episode':
      return MediaType.episode;
    case 'series':
      return MediaType.series;
    case 'audio':
      return MediaType.audio;
    case 'musicvideo':
      return MediaType.musicVideo;
    case 'album':
      return MediaType.album;
    default:
      return MediaType.movie;
  }
}
