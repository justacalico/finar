import 'package:finar/core/api/auth_service.dart';
import 'package:finar/core/api/media_service.dart';
import 'package:finar/core/api/models/library.dart';
import 'package:finar/core/api/models/media_item.dart';
import 'package:finar/core/api/models/user.dart';

const goldenServerUrl = 'https://jellyfin.test';

const goldenLibraries = [
  Library(id: 'lib-movies', name: 'Movies', collectionType: 'movies'),
  Library(id: 'lib-shows', name: 'TV Shows', collectionType: 'tvshows'),
  Library(id: 'lib-music', name: 'Music', collectionType: 'music'),
];

const goldenUser = User(
  id: 'user-1',
  name: 'Calico',
  serverName: 'Test Server',
);

final goldenProfiles = [
  SavedProfile(
    serverUrl: goldenServerUrl,
    userId: 'user-1',
    accessToken: 'token-1',
    userName: 'Calico',
    serverName: 'Test Server',
  ),
  const SavedProfile(
    serverUrl: goldenServerUrl,
    userId: 'user-2',
    accessToken: 'token-2',
    userName: 'Whiskers',
    serverName: 'Test Server',
  ),
];

MediaItem goldenMovie(
  String id,
  String name, {
  int year = 2024,
  double rating = 8.2,
  bool favorite = false,
}) {
  return MediaItem(
    id: id,
    name: name,
    type: MediaType.movie,
    typeString: 'Movie',
    productionYear: year,
    communityRating: rating,
    runtimeTicks: 7420000000,
    overview:
        'A sweeping sci-fi epic about a desert world, its spice, and the '
        'houses that fight to control both.',
    genres: const ['Sci-Fi', 'Adventure'],
    officialRating: 'PG-13',
    isFavorite: favorite,
  );
}

MediaItem goldenSeries(String id, String name, {int year = 2023}) {
  return MediaItem(
    id: id,
    name: name,
    type: MediaType.series,
    typeString: 'Series',
    productionYear: year,
    communityRating: 8.9,
    overview: 'A chemistry teacher turns to cooking meth.',
    genres: const ['Drama', 'Crime'],
    officialRating: 'TV-MA',
    childCount: 62,
  );
}

MediaItem goldenEpisode(
  String id,
  String name, {
  int index = 1,
  int season = 1,
}) {
  return MediaItem(
    id: id,
    name: name,
    type: MediaType.episode,
    typeString: 'Episode',
    seriesName: 'Breaking Bad',
    indexNumber: index,
    parentIndexNumber: season,
    runtimeTicks: 28200000000,
    overview: 'Walt and Jesse cook their first batch.',
  );
}

MediaItem goldenAlbum(String id, String name, {String artist = 'Radiohead'}) {
  return MediaItem(
    id: id,
    name: name,
    type: MediaType.album,
    typeString: 'MusicAlbum',
    albumArtist: artist,
    productionYear: 1997,
    childCount: 12,
  );
}

MediaItem goldenTrack(String id, String name, {int index = 1}) {
  return MediaItem(
    id: id,
    name: name,
    type: MediaType.audio,
    typeString: 'Audio',
    album: 'OK Computer',
    albumArtist: 'Radiohead',
    indexNumber: index,
    runtimeTicks: 2580000000,
  );
}

MediaItem goldenArtist(String id, String name) {
  return MediaItem(
    id: id,
    name: name,
    type: MediaType.artist,
    typeString: 'MusicArtist',
  );
}

final goldenMovies = [
  goldenMovie('movie-1', 'Dune: Part Two', rating: 8.6, favorite: true),
  goldenMovie('movie-2', 'Blade Runner 2049', year: 2017, rating: 8.0),
  goldenMovie('movie-3', 'Arrival', year: 2016, rating: 7.9),
  goldenMovie('movie-4', 'Interstellar', year: 2014, rating: 8.7),
  goldenMovie('movie-5', 'The Dark Knight', year: 2008, rating: 9.0),
  goldenMovie('movie-6', 'Spider-Verse', year: 2018, rating: 8.4),
];

final goldenSeriesList = [
  goldenSeries('series-1', 'Breaking Bad', year: 2008),
  goldenSeries('series-2', 'The Expanse', year: 2015),
  goldenSeries('series-3', 'Severance', year: 2022),
  goldenSeries('series-4', 'Andor', year: 2022),
];

final goldenEpisodes = [
  goldenEpisode('ep-1', 'Pilot'),
  goldenEpisode('ep-2', "Cat's in the Bag...", index: 2),
  goldenEpisode('ep-3', "...And the Bag's in the River", index: 3),
];

final goldenAlbums = [
  goldenAlbum('album-1', 'OK Computer'),
  goldenAlbum('album-2', 'In Rainbows'),
  goldenAlbum('album-3', 'Random Access Memories', artist: 'Daft Punk'),
  goldenAlbum('album-4', 'Discovery', artist: 'Daft Punk'),
];

final goldenTracks = [
  goldenTrack('track-1', 'Airbag'),
  goldenTrack('track-2', 'Paranoid Android', index: 2),
  goldenTrack('track-3', 'Subterranean Homesick Alien', index: 3),
  goldenTrack('track-4', 'Exit Music (For a Film)', index: 4),
];

final goldenArtists = [
  goldenArtist('artist-1', 'Radiohead'),
  goldenArtist('artist-2', 'Daft Punk'),
  goldenArtist('artist-3', 'Boards of Canada'),
];

final goldenHomeData = HomeData(
  continueWatching: [goldenMovies[0], goldenMovies[3]],
  nextUp: [goldenEpisodes[1]],
  recentlyAdded: goldenMovies.sublist(0, 4),
  recentlyReleased: goldenMovies.sublist(1, 5),
  topRated: [goldenMovies[4], goldenMovies[0], goldenMovies[3]],
  recommended: [goldenMovies[1], goldenMovies[2]],
  favorites: [goldenMovies[0], goldenSeriesList[0]],
  recentlyAddedMovies: goldenMovies.sublist(0, 3),
  recentlyAddedShows: goldenSeriesList.sublist(0, 2),
  libraries: goldenLibraries,
);
