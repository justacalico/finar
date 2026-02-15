import axios, { AxiosInstance } from 'axios';
import type {
  User,
  Library,
  MediaItem,
  MediaSourceInfo,
  MediaSourceData,
  ItemsResult,
  ServerInfo,
  SearchHint,
  PlaybackInfo,
  AuthenticationResult,
} from './models';

const CLIENT_NAME = 'Finar';
const CLIENT_VERSION = '1.0.0';

function getDeviceId(): string {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  return 'finar-' + Math.random().toString(36).slice(2) + Date.now().toString(36);
}

function getDeviceName(): string {
  if (typeof navigator !== 'undefined' && navigator.userAgent) {
    if (/Mobile|Android|iPhone/i.test(navigator.userAgent)) return 'Finar Mobile';
    return 'Finar Web';
  }
  return 'Finar Client';
}

function buildAuthHeader(accessToken: string | null, deviceId: string, deviceName: string): string {
  const parts = [
    `MediaBrowser Client="${CLIENT_NAME}"`,
    `Device="${deviceName}"`,
    `DeviceId="${deviceId}"`,
    `Version="${CLIENT_VERSION}"`,
  ];
  if (accessToken) parts.push(`Token="${accessToken}"`);
  return parts.join(', ');
}

export class JellyfinApi {
  private client: AxiosInstance;
  private _serverUrl: string | null = null;
  private _accessToken: string | null = null;
  private _userId: string | null = null;
  private readonly deviceId = getDeviceId();
  private readonly deviceName = getDeviceName();

  constructor() {
    this.client = axios.create({
      timeout: 30000,
      headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
    });
    this.client.interceptors.request.use((config) => {
      config.headers['X-Emby-Authorization'] = buildAuthHeader(
        this._accessToken,
        this.deviceId,
        this.deviceName
      );
      return config;
    });
  }

  get serverUrl(): string | null {
    return this._serverUrl;
  }
  get accessToken(): string | null {
    return this._accessToken;
  }
  get userId(): string | null {
    return this._userId;
  }
  get deviceIdValue(): string {
    return this.deviceId;
  }
  get isAuthenticated(): boolean {
    return !!(this._accessToken && this._userId);
  }

  setServerUrl(url: string): void {
    this._serverUrl = url.replace(/\/$/, '');
    this.client.defaults.baseURL = this._serverUrl!;
  }

  setCredentials(accessToken: string, userId: string): void {
    this._accessToken = accessToken;
    this._userId = userId;
  }

  clearCredentials(): void {
    this._accessToken = null;
    this._userId = null;
  }

  get authHeader(): string {
    return buildAuthHeader(this._accessToken, this.deviceId, this.deviceName);
  }

  async testConnection(serverUrl: string): Promise<boolean> {
    try {
      this.setServerUrl(serverUrl);
      await this.client.get('/System/Info/Public');
      return true;
    } catch {
      return false;
    }
  }

  async getServerInfo(): Promise<ServerInfo> {
    const { data } = await this.client.get<Record<string, unknown>>('/System/Info/Public');
    return {
      id: (data.Id as string) ?? '',
      name: (data.ServerName as string) ?? 'Jellyfin Server',
      url: this._serverUrl!,
      version: data.Version as string | undefined,
      operatingSystem: data.OperatingSystem as string | undefined,
    };
  }

  async getPublicUsers(): Promise<User[]> {
    const { data } = await this.client.get<Record<string, unknown>[]>('/Users/Public');
    return (data ?? []).map((u) => ({
      id: u.Id as string,
      name: u.Name as string,
      serverId: u.ServerId as string | undefined,
      serverName: u.ServerName as string | undefined,
      primaryImageTag: u.PrimaryImageTag as string | undefined,
      hasPassword: (u.HasPassword as boolean) ?? false,
    }));
  }

  async authenticate(username: string, password: string): Promise<AuthenticationResult> {
    const { data } = await this.client.post<{
      User: Record<string, unknown>;
      AccessToken: string;
      ServerId: string;
    }>('/Users/AuthenticateByName', { Username: username, Pw: password });
    const user = data.User;
    this.setCredentials(data.AccessToken, user.Id as string);
    return {
      user: {
        id: user.Id as string,
        name: user.Name as string,
        serverId: user.ServerId as string | undefined,
        serverName: user.ServerName as string | undefined,
        primaryImageTag: user.PrimaryImageTag as string | undefined,
      },
      accessToken: data.AccessToken,
      serverId: data.ServerId,
      serverUrl: this._serverUrl!,
    };
  }

  async initiateQuickConnect(): Promise<string> {
    const { data } = await this.client.get<{ Code: string }>('/QuickConnect/Initiate');
    return data.Code;
  }

  async checkQuickConnect(secret: string): Promise<AuthenticationResult | null> {
    const { data } = await this.client.get<{
      Authenticated: boolean;
      AccessToken?: string;
      ServerId?: string;
    }>('/QuickConnect/Connect', { params: { secret } });
    if (!data.Authenticated || !data.AccessToken) return null;
    this.setCredentials(data.AccessToken, '');
    const userRes = await this.client.get<Record<string, unknown>>('/Users/Me', {
      headers: { 'X-Emby-Token': data.AccessToken },
    });
    const user = userRes.data;
    this.setCredentials(data.AccessToken, user.Id as string);
    return {
      user: {
        id: user.Id as string,
        name: user.Name as string,
        serverId: user.ServerId as string | undefined,
        serverName: user.ServerName as string | undefined,
        primaryImageTag: user.PrimaryImageTag as string | undefined,
      },
      accessToken: data.AccessToken,
      serverId: (data.ServerId as string) ?? '',
      serverUrl: this._serverUrl!,
    };
  }

  async logout(): Promise<void> {
    try {
      await this.client.post('/Sessions/Logout');
    } finally {
      this.clearCredentials();
    }
  }

  async getCurrentUser(): Promise<User> {
    const { data } = await this.client.get<Record<string, unknown>>(`/Users/${this._userId}`);
    return {
      id: data.Id as string,
      name: data.Name as string,
      serverId: data.ServerId as string | undefined,
      serverName: data.ServerName as string | undefined,
      primaryImageTag: data.PrimaryImageTag as string | undefined,
    };
  }

  async getLibraries(): Promise<Library[]> {
    const { data } = await this.client.get<{ Items: Record<string, unknown>[] }>(
      `/Users/${this._userId}/Views`
    );
    return (data.Items ?? []).map((item) => ({
      id: item.Id as string,
      name: item.Name as string,
      collectionType: item.CollectionType as string | undefined,
      primaryImageTag: (item.ImageTags as Record<string, string>)?.Primary,
      childCount: typeof item.ChildCount === 'number' ? item.ChildCount : undefined,
      isFolder: (item.IsFolder as boolean) ?? true,
      backdropImageTag: (item.BackdropImageTags as string[])?.[0],
    }));
  }

  async getItems(params: {
    parentId?: string;
    includeItemTypes?: string[];
    excludeItemTypes?: string[];
    startIndex?: number;
    limit?: number;
    sortBy?: string;
    sortOrder?: string;
    recursive?: boolean;
    fields?: string[];
    searchTerm?: string;
    isFavorite?: boolean;
    genres?: string;
    ids?: string;
  }): Promise<ItemsResult> {
    const q: Record<string, string | number | boolean | undefined> = {};
    if (params.parentId) q.parentId = params.parentId;
    if (params.includeItemTypes?.length) q.IncludeItemTypes = params.includeItemTypes.join(',');
    if (params.excludeItemTypes?.length) q.ExcludeItemTypes = params.excludeItemTypes.join(',');
    if (params.startIndex != null) q.StartIndex = params.startIndex;
    if (params.limit != null) q.Limit = params.limit;
    if (params.sortBy) q.SortBy = params.sortBy;
    if (params.sortOrder) q.SortOrder = params.sortOrder;
    if (params.recursive != null) q.Recursive = params.recursive;
    if (params.fields?.length) q.Fields = params.fields.join(',');
    if (params.searchTerm) q.SearchTerm = params.searchTerm;
    if (params.isFavorite != null) q.IsFavorite = params.isFavorite;
    if (params.genres) q.Genres = params.genres;
    if (params.ids) q.Ids = params.ids;

    const { data } = await this.client.get<{
      Items: Record<string, unknown>[];
      TotalRecordCount: number;
      StartIndex: number;
    }>(`/Users/${this._userId}/Items`, { params: q });
    return {
      items: (data.Items ?? []).map(parseMediaItem),
      totalCount: data.TotalRecordCount ?? 0,
      startIndex: data.StartIndex ?? 0,
    };
  }

  async getItem(itemId: string): Promise<MediaItem> {
    const { data } = await this.client.get<Record<string, unknown>>(
      `/Users/${this._userId}/Items/${itemId}`,
      {
        params: {
          Fields:
            'Overview,People,Genres,MediaStreams,Chapters,Path,MediaSources,LocalTrailerCount,RemoteTrailers',
        },
      }
    );
    return parseMediaItem(data);
  }

  async getContinueWatching(limit = 12): Promise<MediaItem[]> {
    const res = await this.client.get<{ Items: Record<string, unknown>[] }>(
      `/Users/${this._userId}/Items/Resume`,
      {
        params: { Limit: limit, Recursive: true, MediaTypes: 'Video', Fields: 'Overview' },
      }
    );
    return (res.data.Items ?? []).map(parseMediaItem);
  }

  async getNextUp(limit = 12, seriesId?: string): Promise<MediaItem[]> {
    const params: Record<string, unknown> = { UserId: this._userId, Limit: limit, Fields: 'Overview' };
    if (seriesId) params.SeriesId = seriesId;
    const { data } = await this.client.get<{ Items: Record<string, unknown>[] }>(
      '/Shows/NextUp',
      { params }
    );
    return (data.Items ?? []).map(parseMediaItem);
  }

  async getRecentlyAdded(limit = 16, parentId?: string, includeItemTypes?: string[]): Promise<MediaItem[]> {
    const params: Record<string, unknown> = {
      Limit: limit,
      Fields: 'Overview',
    };
    if (parentId) params.ParentId = parentId;
    if (includeItemTypes?.length) params.IncludeItemTypes = includeItemTypes.join(',');
    const { data } = await this.client.get<Record<string, unknown>[]>(
      `/Users/${this._userId}/Items/Latest`,
      { params }
    );
    return (data ?? []).map((item) => parseMediaItem(item as Record<string, unknown>));
  }

  async getSimilarItems(itemId: string, limit = 12): Promise<MediaItem[]> {
    const { data } = await this.client.get<{ Items: Record<string, unknown>[] }>(
      `/Items/${itemId}/Similar`,
      { params: { UserId: this._userId, Limit: limit, Fields: 'Overview' } }
    );
    return (data.Items ?? []).map(parseMediaItem);
  }

  async getSeasons(seriesId: string): Promise<MediaItem[]> {
    const { data } = await this.client.get<Record<string, unknown>[]>(
      `/Shows/${seriesId}/Seasons`,
      { params: { UserId: this._userId, Fields: 'Overview' } }
    );
    return (data ?? []).map((item) => parseMediaItem(item as Record<string, unknown>));
  }

  async getEpisodes(seriesId: string, seasonId?: string): Promise<MediaItem[]> {
    const params: Record<string, unknown> = { UserId: this._userId, Fields: 'Overview,MediaSources' };
    if (seasonId) params.SeasonId = seasonId;
    const { data } = await this.client.get<Record<string, unknown>[]>(
      `/Shows/${seriesId}/Episodes`,
      { params }
    );
    return (data ?? []).map((item) => parseMediaItem(item as Record<string, unknown>));
  }

  async getFavorites(limit?: number, includeItemTypes?: string[]): Promise<MediaItem[]> {
    const result = await this.getItems({
      isFavorite: true,
      limit: limit ?? 16,
      includeItemTypes,
      recursive: true,
      sortBy: 'SortName',
      sortOrder: 'Ascending',
      fields: ['Overview'],
    });
    return result.items;
  }

  async getRecommended(limit = 16): Promise<MediaItem[]> {
    const { data } = await this.client.get<{ Items: Record<string, unknown>[] }>(
      '/Users/' + this._userId + '/Suggestions',
      { params: { Limit: limit + 10, Fields: 'Overview' } }
    );
    const items = (data.Items ?? []).map(parseMediaItem);
    return items
      .filter(
        (i) =>
          !['collectionFolder', 'season', 'folder', 'playlist', 'boxSet'].includes(
            (i.typeString ?? i.type)?.toLowerCase() ?? ''
          )
      )
      .slice(0, limit);
  }

  async getTopRated(limit = 16, includeItemTypes?: string[]): Promise<MediaItem[]> {
    return (
      await this.getItems({
        includeItemTypes: includeItemTypes ?? ['Movie', 'Series'],
        limit,
        recursive: true,
        sortBy: 'CommunityRating',
        sortOrder: 'Descending',
        fields: ['Overview', 'CommunityRating'],
      })
    ).items;
  }

  async getRecentlyReleased(limit = 16, includeItemTypes?: string[]): Promise<MediaItem[]> {
    return (
      await this.getItems({
        includeItemTypes: includeItemTypes ?? ['Movie'],
        limit,
        recursive: true,
        sortBy: 'PremiereDate',
        sortOrder: 'Descending',
        fields: ['Overview', 'PremiereDate'],
      })
    ).items;
  }

  async search(query: string, limit = 20): Promise<SearchHint[]> {
    const { data } = await this.client.get<{ SearchHints: Record<string, unknown>[] }>(
      '/Search/Hints',
      {
        params: {
          SearchTerm: query,
          Limit: limit,
          UserId: this._userId,
          IncludeItemTypes: 'Movie,Series,Episode,Audio,MusicAlbum,MusicArtist',
        },
      }
    );
    return (data.SearchHints ?? []).map((h) => ({
      itemId: h.ItemId as string,
      name: h.Name as string,
      type: h.Type as string | undefined,
      productionYear: typeof h.ProductionYear === 'number' ? h.ProductionYear : undefined,
      primaryImageTag: h.PrimaryImageTag as string | undefined,
      thumbImageTag: h.ThumbImageTag as string | undefined,
      backdropImageTag: h.BackdropImageTag as string | undefined,
      series: h.Series as string | undefined,
      album: h.Album as string | undefined,
      albumArtist: h.AlbumArtist as string | undefined,
      indexNumber: typeof h.IndexNumber === 'number' ? h.IndexNumber : undefined,
      parentIndexNumber: typeof h.ParentIndexNumber === 'number' ? h.ParentIndexNumber : undefined,
    }));
  }

  async getPlaybackInfo(
    itemId: string,
    options?: {
      audioStreamIndex?: number;
      subtitleStreamIndex?: number;
      startTimeTicks?: number;
      mediaSourceId?: string;
    }
  ): Promise<PlaybackInfo> {
    const params: Record<string, unknown> = { UserId: this._userId };
    if (options?.audioStreamIndex != null) params.AudioStreamIndex = options.audioStreamIndex;
    if (options?.subtitleStreamIndex != null)
      params.SubtitleStreamIndex = options.subtitleStreamIndex;
    if (options?.startTimeTicks != null) params.StartTimeTicks = options.startTimeTicks;
    if (options?.mediaSourceId) params.MediaSourceId = options.mediaSourceId;
    const { data } = await this.client.post<{
      MediaSources: Record<string, unknown>[];
      PlaySessionId?: string;
    }>(`/Items/${itemId}/PlaybackInfo`, { DeviceProfile: getDeviceProfile() }, { params });
    const mediaSources = (data.MediaSources ?? []).map(parseMediaSourceData);
    return {
      mediaSources,
      playSessionId: data.PlaySessionId,
    };
  }

  getStreamUrl(
    itemId: string,
    opts?: {
      mediaSourceId?: string;
      container?: string;
      audioStreamIndex?: number;
      subtitleStreamIndex?: number;
      startTimeTicks?: number;
      static?: boolean;
    }
  ): string {
    const p: Record<string, string> = { api_key: this._accessToken ?? '' };
    if (opts?.mediaSourceId) p.MediaSourceId = opts.mediaSourceId;
    if (opts?.container) p.Container = opts.container;
    if (opts?.audioStreamIndex != null) p.AudioStreamIndex = String(opts.audioStreamIndex);
    if (opts?.subtitleStreamIndex != null) p.SubtitleStreamIndex = String(opts.subtitleStreamIndex);
    if (opts?.startTimeTicks != null) p.StartTimeTicks = String(opts.startTimeTicks);
    if (opts?.static != null) p.Static = String(opts.static);
    const q = new URLSearchParams(p).toString();
    return `${this._serverUrl}/Videos/${itemId}/stream?${q}`;
  }

  getHlsStreamUrl(
    itemId: string,
    opts?: {
      mediaSourceId?: string;
      playSessionId?: string;
      audioStreamIndex?: number;
      subtitleStreamIndex?: number;
      startTimeTicks?: number;
    }
  ): string {
    const p: Record<string, string> = {
      api_key: this._accessToken ?? '',
      DeviceId: this.deviceId,
      TranscodingMaxAudioChannels: '6',
      SegmentContainer: 'ts',
      MinSegments: '2',
    };
    if (opts?.mediaSourceId) p.MediaSourceId = opts.mediaSourceId;
    if (opts?.playSessionId) p.PlaySessionId = opts.playSessionId;
    if (opts?.audioStreamIndex != null) p.AudioStreamIndex = String(opts.audioStreamIndex);
    if (opts?.subtitleStreamIndex != null) p.SubtitleStreamIndex = String(opts.subtitleStreamIndex);
    if (opts?.startTimeTicks != null) p.StartTimeTicks = String(opts.startTimeTicks);
    const q = new URLSearchParams(p).toString();
    return `${this._serverUrl}/Videos/${itemId}/master.m3u8?${q}`;
  }

  getImageUrl(
    itemId: string,
    imageType: string,
    opts?: { width?: number; height?: number; quality?: number; tag?: string; index?: number }
  ): string {
    const p: Record<string, string> = {};
    if (opts?.width != null) p.maxWidth = String(opts.width);
    if (opts?.height != null) p.maxHeight = String(opts.height);
    if (opts?.quality != null) p.quality = String(opts.quality);
    if (opts?.tag) p.tag = opts.tag;
    const indexSuffix = opts?.index != null ? `/${opts.index}` : '';
    const q = new URLSearchParams(p).toString();
    return `${this._serverUrl}/Items/${itemId}/Images/${imageType}${indexSuffix}?${q}`;
  }

  getSubtitleUrl(itemId: string, mediaSourceId: string, subtitleIndex: number, format: string): string {
    return `${this._serverUrl}/Videos/${itemId}/${mediaSourceId}/Subtitles/${subtitleIndex}/Stream.${format}?api_key=${this._accessToken}`;
  }

  async reportPlaybackStart(info: {
    itemId: string;
    mediaSourceId?: string;
    playSessionId?: string;
    positionTicks?: number;
    playMethod?: string;
  }): Promise<void> {
    await this.client.post('/Sessions/Playing', {
      ItemId: info.itemId,
      MediaSourceId: info.mediaSourceId,
      PlaySessionId: info.playSessionId,
      PositionTicks: info.positionTicks,
      PlayMethod: info.playMethod ?? 'DirectPlay',
      CanSeek: true,
    });
  }

  async reportPlaybackProgress(info: {
    itemId: string;
    mediaSourceId?: string;
    playSessionId?: string;
    positionTicks: number;
    isPaused?: boolean;
    playMethod?: string;
  }): Promise<void> {
    await this.client.post('/Sessions/Playing/Progress', {
      ItemId: info.itemId,
      MediaSourceId: info.mediaSourceId,
      PlaySessionId: info.playSessionId,
      PositionTicks: info.positionTicks,
      IsPaused: info.isPaused ?? false,
      PlayMethod: info.playMethod ?? 'DirectPlay',
      CanSeek: true,
    });
  }

  async reportPlaybackStopped(info: {
    itemId: string;
    mediaSourceId?: string;
    playSessionId?: string;
    positionTicks: number;
  }): Promise<void> {
    await this.client.post('/Sessions/Playing/Stopped', {
      ItemId: info.itemId,
      MediaSourceId: info.mediaSourceId,
      PlaySessionId: info.playSessionId,
      PositionTicks: info.positionTicks,
    });
  }

  async markPlayed(itemId: string): Promise<void> {
    await this.client.post(`/Users/${this._userId}/PlayedItems/${itemId}`);
  }

  async markUnplayed(itemId: string): Promise<void> {
    await this.client.delete(`/Users/${this._userId}/PlayedItems/${itemId}`);
  }

  async addFavorite(itemId: string): Promise<void> {
    await this.client.post(`/Users/${this._userId}/FavoriteItems/${itemId}`);
  }

  async removeFavorite(itemId: string): Promise<void> {
    await this.client.delete(`/Users/${this._userId}/FavoriteItems/${itemId}`);
  }
}

function parseNum(v: unknown): number | undefined {
  if (v == null) return undefined;
  if (typeof v === 'number') return v;
  if (typeof v === 'string') return parseInt(v, 10);
  return undefined;
}

function parseMediaItem(json: Record<string, unknown>): MediaItem {
  const typeStr = (json.Type as string) ?? '';
  const type = typeStr.toLowerCase() as MediaItem['type'];
  const imageTags = json.ImageTags as Record<string, string> | undefined;
  const userData = json.UserData as Record<string, unknown> | undefined;
  return {
    id: json.Id as string,
    name: (json.Name as string) ?? '',
    originalTitle: json.OriginalTitle as string | undefined,
    sortName: json.SortName as string | undefined,
    overview: json.Overview as string | undefined,
    type: type || 'unknown',
    typeString: typeStr,
    productionYear: parseNum(json.ProductionYear),
    premiereDate: json.PremiereDate as string | undefined,
    officialRating: json.OfficialRating as string | undefined,
    communityRating: typeof json.CommunityRating === 'number' ? json.CommunityRating : undefined,
    criticRating: typeof json.CriticRating === 'number' ? json.CriticRating : undefined,
    runtimeTicks: parseNum(json.RunTimeTicks),
    playbackPositionTicks: parseNum(json.PlaybackPositionTicks),
    isPlayed: json.IsPlayed as boolean | undefined,
    isFavorite: json.IsFavorite as boolean | undefined,
    seriesId: json.SeriesId as string | undefined,
    seriesName: json.SeriesName as string | undefined,
    seasonId: json.SeasonId as string | undefined,
    seasonName: json.SeasonName as string | undefined,
    indexNumber: parseNum(json.IndexNumber),
    parentIndexNumber: parseNum(json.ParentIndexNumber),
    imageTags: imageTags
      ? {
          primary: imageTags.Primary,
          logo: imageTags.Logo,
          thumb: imageTags.Thumb,
          art: imageTags.Art,
          banner: imageTags.Banner,
          backdrop: imageTags.Backdrop,
        }
      : undefined,
    backdropImageTags: json.BackdropImageTags as string[] | undefined,
    parentBackdropItemId: json.ParentBackdropItemId as string | undefined,
    parentBackdropImageTags: json.ParentBackdropImageTags as string[] | undefined,
    people: (json.People as Record<string, unknown>[] | undefined)?.map((p) => ({
      id: p.Id as string,
      name: p.Name as string,
      role: p.Role as string | undefined,
      type: p.Type as string | undefined,
      primaryImageTag: p.PrimaryImageTag as string | undefined,
    })),
    genres: json.Genres as string[] | undefined,
    userData: userData
      ? {
          playedPercentage: typeof userData.PlayedPercentage === 'number' ? userData.PlayedPercentage : undefined,
          playbackPositionTicks: parseNum(userData.PlaybackPositionTicks) ?? 0,
          playCount: parseNum(userData.PlayCount) ?? 0,
          isFavorite: (userData.IsFavorite as boolean) ?? false,
          played: (userData.Played as boolean) ?? false,
          lastPlayedDate: userData.LastPlayedDate as string | undefined,
          unplayedItemCount: parseNum(userData.UnplayedItemCount),
        }
      : undefined,
    container: json.Container as string | undefined,
    path: json.Path as string | undefined,
    childCount: parseNum(json.ChildCount),
    collectionType: json.CollectionType as string | undefined,
    parentId: json.ParentId as string | undefined,
    mediaSources: (json.MediaSources as Record<string, unknown>[] | undefined)?.map(parseMediaSourceInfo),
    albumArtist: json.AlbumArtist as string | undefined,
    artists: json.Artists as string[] | undefined,
    album: json.Album as string | undefined,
    albumId: json.AlbumId as string | undefined,
    playlistItemId: json.PlaylistItemId as string | undefined,
  };
}

function parseMediaSourceInfo(json: Record<string, unknown>): MediaSourceInfo {
  const streams = json.MediaStreams as Record<string, unknown>[] | undefined;
  return {
    id: json.Id as string,
    container: json.Container as string | undefined,
    supportsDirectPlay: json.SupportsDirectPlay as boolean | undefined,
    supportsDirectStream: json.SupportsDirectStream as boolean | undefined,
    mediaStreams: streams?.map((s) => ({
      type: (s.Type as string) ?? 'Unknown',
      index: parseNum(s.Index) ?? 0,
      codec: s.Codec as string | undefined,
      language: s.Language as string | undefined,
      displayTitle: s.DisplayTitle as string | undefined,
      isDefault: s.IsDefault as boolean | undefined,
      isForced: s.IsForced as boolean | undefined,
      width: parseNum(s.Width),
      height: parseNum(s.Height),
      channels: parseNum(s.Channels),
    })),
    defaultAudioStreamIndex: parseNum(json.DefaultAudioStreamIndex),
    defaultSubtitleStreamIndex: parseNum(json.DefaultSubtitleStreamIndex),
  };
}

function parseMediaSourceData(json: Record<string, unknown>): MediaSourceData {
  const streams = json.MediaStreams as Record<string, unknown>[] | undefined;
  return {
    id: json.Id as string,
    container: json.Container as string | undefined,
    supportsDirectPlay: json.SupportsDirectPlay as boolean | undefined,
    supportsDirectStream: json.SupportsDirectStream as boolean | undefined,
    mediaStreams: streams?.map((s) => ({
      type: (s.Type as string) ?? 'Unknown',
      index: parseNum(s.Index) ?? 0,
      displayTitle: s.DisplayTitle as string | undefined,
      language: s.Language as string | undefined,
      codec: s.Codec as string | undefined,
      width: parseNum(s.Width),
      height: parseNum(s.Height),
      channels: parseNum(s.Channels),
    })),
    defaultAudioStreamIndex: parseNum(json.DefaultAudioStreamIndex),
    defaultSubtitleStreamIndex: parseNum(json.DefaultSubtitleStreamIndex),
  };
}

function getDeviceProfile(): Record<string, unknown> {
  return {
    Name: CLIENT_NAME,
    MaxStreamingBitrate: 120000000,
    MusicStreamingTranscodingBitrate: 384000,
    DirectPlayProfiles: [
      {
        Container: 'mp4,m4v,mkv,webm',
        Type: 'Video',
        VideoCodec: 'h264,hevc,vp8,vp9,av1',
        AudioCodec: 'aac,mp3,opus,flac,vorbis',
      },
      { Container: 'mp3,flac,opus,aac,m4a,webm', Type: 'Audio' },
    ],
    TranscodingProfiles: [
      {
        Container: 'ts',
        Type: 'Video',
        AudioCodec: 'aac,mp3',
        VideoCodec: 'h264',
        Context: 'Streaming',
        Protocol: 'hls',
        MaxAudioChannels: '6',
        MinSegments: '2',
        BreakOnNonKeyFrames: true,
      },
      {
        Container: 'mp3',
        Type: 'Audio',
        AudioCodec: 'mp3',
        Context: 'Streaming',
        Protocol: 'http',
      },
    ],
    ContainerProfiles: [],
    CodecProfiles: [],
    SubtitleProfiles: [
      { Format: 'srt', Method: 'External' },
      { Format: 'vtt', Method: 'External' },
      { Format: 'ass', Method: 'External' },
    ],
  };
}
