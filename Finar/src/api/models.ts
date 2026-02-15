/** User and auth */
export interface User {
  id: string;
  name: string;
  serverId?: string;
  serverName?: string;
  primaryImageTag?: string;
  hasPassword?: boolean;
}

export interface AuthenticationResult {
  user: User;
  accessToken: string;
  serverId: string;
  serverUrl: string;
}

export interface SavedServer {
  url: string;
  name: string;
  serverId?: string;
  lastUserId?: string;
  lastUserName?: string;
  lastConnected?: string;
}

/** Media types */
export type MediaType =
  | 'movie'
  | 'series'
  | 'season'
  | 'episode'
  | 'audio'
  | 'album'
  | 'artist'
  | 'photo'
  | 'folder'
  | 'collectionFolder'
  | 'musicVideo'
  | 'boxSet'
  | 'playlist'
  | 'unknown';

export interface ImageTags {
  primary?: string;
  logo?: string;
  thumb?: string;
  art?: string;
  banner?: string;
  backdrop?: string;
}

export interface UserData {
  playedPercentage?: number;
  playbackPositionTicks: number;
  playCount: number;
  isFavorite: boolean;
  played: boolean;
  lastPlayedDate?: string;
  unplayedItemCount?: number;
}

export interface MediaItem {
  id: string;
  name: string;
  originalTitle?: string;
  sortName?: string;
  overview?: string;
  type: MediaType;
  typeString?: string;
  productionYear?: number;
  premiereDate?: string;
  officialRating?: string;
  communityRating?: number;
  criticRating?: number;
  runtimeTicks?: number;
  playbackPositionTicks?: number;
  isPlayed?: boolean;
  isFavorite?: boolean;
  seriesId?: string;
  seriesName?: string;
  seasonId?: string;
  seasonName?: string;
  indexNumber?: number;
  parentIndexNumber?: number;
  imageTags?: ImageTags;
  backdropImageTags?: string[];
  parentBackdropItemId?: string;
  parentBackdropImageTags?: string[];
  people?: PersonInfo[];
  genres?: string[];
  userData?: UserData;
  container?: string;
  path?: string;
  childCount?: number;
  collectionType?: string;
  parentId?: string;
  mediaSources?: MediaSourceInfo[];
  albumArtist?: string;
  artists?: string[];
  album?: string;
  albumId?: string;
  playlistItemId?: string;
}

export interface PersonInfo {
  id: string;
  name: string;
  role?: string;
  type?: string;
  primaryImageTag?: string;
}

export interface MediaSourceInfo {
  id: string;
  container?: string;
  supportsDirectPlay?: boolean;
  supportsDirectStream?: boolean;
  mediaStreams?: MediaStream[];
  defaultAudioStreamIndex?: number;
  defaultSubtitleStreamIndex?: number;
}

export interface MediaStream {
  type: string;
  index: number;
  codec?: string;
  language?: string;
  displayTitle?: string;
  isDefault?: boolean;
  isForced?: boolean;
  width?: number;
  height?: number;
  channels?: number;
}

export interface Library {
  id: string;
  name: string;
  collectionType?: string;
  primaryImageTag?: string;
  childCount?: number;
  isFolder?: boolean;
  backdropImageTag?: string;
}

export interface ItemsResult {
  items: MediaItem[];
  totalCount: number;
  startIndex: number;
}

export interface ServerInfo {
  id: string;
  name: string;
  url: string;
  version?: string;
  operatingSystem?: string;
}

export interface SearchHint {
  itemId: string;
  name: string;
  type?: string;
  productionYear?: number;
  primaryImageTag?: string;
  thumbImageTag?: string;
  backdropImageTag?: string;
  series?: string;
  album?: string;
  albumArtist?: string;
  indexNumber?: number;
  parentIndexNumber?: number;
}

export interface GenreInfo {
  id: string;
  name: string;
  primaryImageTag?: string;
}

/** Playback */
export interface PlaybackInfo {
  mediaSources: MediaSourceData[];
  playSessionId?: string;
}

export interface MediaSourceData {
  id: string;
  container?: string;
  supportsDirectPlay?: boolean;
  supportsDirectStream?: boolean;
  mediaStreams?: MediaStreamData[];
  defaultAudioStreamIndex?: number;
  defaultSubtitleStreamIndex?: number;
}

export interface MediaStreamData {
  type: string;
  index: number;
  displayTitle?: string;
  language?: string;
  codec?: string;
  width?: number;
  height?: number;
  channels?: number;
}

/** Home & media service */
export interface HomeData {
  continueWatching: MediaItem[];
  nextUp: MediaItem[];
  recentlyAdded: MediaItem[];
  recentlyReleased: MediaItem[];
  topRated: MediaItem[];
  recommended: MediaItem[];
  favorites: MediaItem[];
  recentlyAddedMovies: MediaItem[];
  recentlyAddedShows: MediaItem[];
  libraries: Library[];
}

export interface LibraryContent {
  items: MediaItem[];
  totalCount: number;
  hasMore: boolean;
}

export interface StreamInfo {
  url: string;
  mediaSource: MediaSourceData;
  playSessionId?: string;
  isTranscoding: boolean;
  audioStreams: MediaStreamData[];
  subtitleStreams: MediaStreamData[];
  defaultAudioIndex?: number;
  defaultSubtitleIndex?: number;
}

export interface SearchResults {
  movies: SearchHint[];
  series: SearchHint[];
  episodes: SearchHint[];
  music: SearchHint[];
  all: SearchHint[];
}
