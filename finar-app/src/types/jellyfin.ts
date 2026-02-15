// Jellyfin API types (from Flutter models)

export interface User {
  Id: string;
  Name: string;
  ServerId?: string;
  ServerName?: string;
  PrimaryImageTag?: string;
}

export interface AuthenticationResult {
  user: User;
  accessToken: string;
  serverId: string;
  serverUrl: string;
}

export interface Library {
  Id: string;
  Name: string;
  CollectionType?: string;
  PrimaryImageTag?: string;
  ChildCount?: number;
  IsFolder?: boolean;
  BackdropImageTag?: string;
}

export type MediaType =
  | "Movie"
  | "Series"
  | "Season"
  | "Episode"
  | "Audio"
  | "MusicAlbum"
  | "MusicArtist"
  | "Photo"
  | "Folder"
  | "CollectionFolder"
  | "MusicVideo"
  | "BoxSet"
  | "Playlist"
  | "Unknown";

export interface ImageTags {
  Primary?: string;
  Logo?: string;
  Thumb?: string;
  Art?: string;
  Banner?: string;
  Backdrop?: string;
}

export interface UserData {
  PlayedPercentage?: number;
  PlaybackPositionTicks?: number;
  PlayCount?: number;
  IsFavorite?: boolean;
  Played?: boolean;
  LastPlayedDate?: string;
  UnplayedItemCount?: number;
}

export interface MediaItem {
  Id: string;
  Name: string;
  OriginalTitle?: string;
  Overview?: string;
  Type: MediaType;
  ProductionYear?: number;
  PremiereDate?: string;
  OfficialRating?: string;
  CommunityRating?: number;
  RunTimeTicks?: number;
  PlaybackPositionTicks?: number;
  IsPlayed?: boolean;
  IsFavorite?: boolean;
  SeriesId?: string;
  SeriesName?: string;
  SeasonId?: string;
  SeasonName?: string;
  IndexNumber?: number;
  ParentIndexNumber?: number;
  ImageTags?: ImageTags;
  BackdropImageTags?: string[];
  ParentBackdropItemId?: string;
  ParentBackdropImageTags?: string[];
  Genres?: string[];
  UserData?: UserData;
  Container?: string;
  ChildCount?: number;
  ParentId?: string;
  AlbumArtist?: string;
  Artists?: string[];
  Album?: string;
  AlbumId?: string;
  PlaylistItemId?: string;
}

export interface ItemsResult {
  Items: MediaItem[];
  TotalRecordCount: number;
  StartIndex: number;
}

export interface PlaybackInfo {
  MediaSources: MediaSourceData[];
  PlaySessionId?: string;
}

export interface MediaSourceData {
  Id: string;
  Name?: string;
  DirectStreamUrl?: string;
  TranscodingUrl?: string;
  SupportsDirectPlay?: boolean;
  SupportsDirectStream?: boolean;
  RunTimeTicks?: number;
  MediaStreams?: MediaStreamData[];
  DefaultAudioStreamIndex?: number;
  DefaultSubtitleStreamIndex?: number;
}

export interface MediaStreamData {
  Index: number;
  Type: string;
  Codec?: string;
  Language?: string;
  DisplayTitle?: string;
  Width?: number;
  Height?: number;
  Channels?: number;
}

export interface SearchHint {
  ItemId: string;
  Name: string;
  Type?: string;
  ProductionYear?: number;
  PrimaryImageTag?: string;
  Series?: string;
  Album?: string;
  AlbumArtist?: string;
  IndexNumber?: number;
  ParentIndexNumber?: number;
}

export interface GenreInfo {
  Id: string;
  Name: string;
  ImageTags?: ImageTags;
}

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
