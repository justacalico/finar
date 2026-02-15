import type {
  User,
  AuthenticationResult,
  Library,
  MediaItem,
  ItemsResult,
  PlaybackInfo,
  SearchHint,
} from "../types/jellyfin";
import { cacheGet, cacheSet, cacheClear, CACHE_TTL } from "../utils/cache";

const CLIENT_NAME = "Finar";
const CLIENT_VERSION = "1.0.0";

function getDeviceId(): string {
  let id = localStorage.getItem("finar_device_id");
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem("finar_device_id", id);
  }
  return id;
}

function buildAuthHeader(accessToken: string | null): string {
  const parts = [
    `MediaBrowser Client="${CLIENT_NAME}"`,
    `Device="${typeof navigator !== "undefined" ? navigator.userAgent.slice(0, 50) : "Finar"}"`,
    `DeviceId="${getDeviceId()}"`,
    `Version="${CLIENT_VERSION}"`,
  ];
  if (accessToken) parts.push(`Token="${accessToken}"`);
  return parts.join(", ");
}

export class JellyfinApi {
  private baseUrl: string = "";
  private accessToken: string | null = null;
  private userId: string | null = null;
  private readonly deviceId = getDeviceId();

  setServerUrl(url: string) {
    this.baseUrl = url.replace(/\/$/, "");
  }

  setCredentials(accessToken: string, userId: string) {
    this.accessToken = accessToken;
    this.userId = userId;
  }

  clearCredentials() {
    this.accessToken = null;
    this.userId = null;
    cacheClear();
  }

  get serverUrl(): string {
    return this.baseUrl;
  }

  get isAuthenticated(): boolean {
    return !!(this.accessToken && this.userId);
  }

  private async request<T>(
    path: string,
    options: RequestInit & { searchParams?: Record<string, string> } = {}
  ): Promise<T> {
    const url = new URL(path, this.baseUrl);
    if (options.searchParams) {
      Object.entries(options.searchParams).forEach(([k, v]) =>
        url.searchParams.set(k, v)
      );
    }
    const { searchParams: _, ...fetchOptions } = options;
    const res = await fetch(url.toString(), {
      ...fetchOptions,
      headers: {
        "Content-Type": "application/json",
        "X-Emby-Authorization": buildAuthHeader(this.accessToken),
        ...(fetchOptions.headers as Record<string, string>),
      },
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`API ${res.status}: ${text || res.statusText}`);
    }
    if (res.status === 204 || res.headers.get("content-length") === "0")
      return undefined as T;
    return res.json() as Promise<T>;
  }

  async testConnection(serverUrl: string): Promise<boolean> {
    try {
      const url = `${serverUrl.replace(/\/$/, "")}/System/Info/Public`;
      await fetch(url);
      return true;
    } catch {
      return false;
    }
  }

  async authenticate(username: string, password: string): Promise<AuthenticationResult> {
    const data = await this.request<{
      User: User;
      AccessToken: string;
      ServerId: string;
    }>(`${this.baseUrl}/Users/AuthenticateByName`, {
      method: "POST",
      body: JSON.stringify({ Username: username, Pw: password }),
    });
    const result: AuthenticationResult = {
      user: data.User,
      accessToken: data.AccessToken,
      serverId: data.ServerId,
      serverUrl: this.baseUrl,
    };
    this.setCredentials(result.accessToken, result.user.Id);
    return result;
  }

  async initiateQuickConnect(): Promise<string> {
    const data = await this.request<{ Code: string }>(
      `${this.baseUrl}/QuickConnect/Initiate`
    );
    return data.Code;
  }

  async checkQuickConnect(secret: string): Promise<AuthenticationResult | null> {
    const data = await this.request<{
      Authenticated: boolean;
      AccessToken?: string;
      ServerId?: string;
    }>(`${this.baseUrl}/QuickConnect/Connect`, {
      searchParams: { secret },
    });
    if (!data.Authenticated || !data.AccessToken) return null;
    this.setCredentials(data.AccessToken, "");
    const userRes = await this.request<User>(`${this.baseUrl}/Users/Me`, {
      headers: { "X-Emby-Token": data.AccessToken },
    });
    this.setCredentials(data.AccessToken, userRes.Id);
    return {
      user: userRes,
      accessToken: data.AccessToken,
      serverId: data.ServerId ?? "",
      serverUrl: this.baseUrl,
    };
  }

  async getCurrentUser(): Promise<User> {
    return this.request<User>(`${this.baseUrl}/Users/${this.userId}`);
  }

  async getLibraries(): Promise<Library[]> {
    const key = `libs:${this.userId}`;
    const cached = cacheGet<Library[]>(key);
    if (cached) return cached;
    const data = await this.request<{ Items: Library[] }>(
      `${this.baseUrl}/Users/${this.userId}/Views`
    );
    const items = data.Items ?? [];
    cacheSet(key, items, CACHE_TTL.LONG);
    return items;
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
    filters?: string[];
    searchTerm?: string;
    isFavorite?: boolean;
    genres?: string;
    ids?: string[];
  }): Promise<ItemsResult> {
    const searchParams: Record<string, string> = {};
    if (params.parentId) searchParams.ParentId = params.parentId;
    if (params.ids?.length) searchParams.Ids = params.ids.join(",");
    if (params.includeItemTypes?.length)
      searchParams.IncludeItemTypes = params.includeItemTypes.join(",");
    if (params.excludeItemTypes?.length)
      searchParams.ExcludeItemTypes = params.excludeItemTypes.join(",");
    if (params.startIndex != null) searchParams.StartIndex = String(params.startIndex);
    if (params.limit != null) searchParams.Limit = String(params.limit);
    if (params.sortBy) searchParams.SortBy = params.sortBy;
    if (params.sortOrder) searchParams.SortOrder = params.sortOrder;
    if (params.recursive != null) searchParams.Recursive = String(params.recursive);
    if (params.fields?.length) searchParams.Fields = params.fields.join(",");
    if (params.filters?.length) searchParams.Filters = params.filters.join(",");
    if (params.searchTerm) searchParams.SearchTerm = params.searchTerm;
    if (params.isFavorite != null) searchParams.IsFavorite = String(params.isFavorite);
    if (params.genres) searchParams.Genres = params.genres;

    const q = new URLSearchParams(searchParams).toString();
    const key = `items:${this.userId}:${q}`;
    const cached = cacheGet<ItemsResult>(key);
    if (cached) return cached;
    const result = await this.request<ItemsResult>(
      `${this.baseUrl}/Users/${this.userId}/Items?${q}`
    );
    cacheSet(key, result, CACHE_TTL.MEDIUM);
    return result;
  }

  async getItem(itemId: string): Promise<MediaItem> {
    const key = `item:${this.userId}:${itemId}`;
    const cached = cacheGet<MediaItem>(key);
    if (cached) return cached;
    const item = await this.request<MediaItem>(
      `${this.baseUrl}/Users/${this.userId}/Items/${itemId}`,
      {
        searchParams: {
          Fields:
            "Overview,People,Genres,MediaStreams,Chapters,Path,MediaSources,LocalTrailerCount,RemoteTrailers",
        },
      }
    );
    cacheSet(key, item, CACHE_TTL.LONG);
    return item;
  }

  async getContinueWatching(limit = 12): Promise<MediaItem[]> {
    const key = `resume:${this.userId}:${limit}`;
    const cached = cacheGet<MediaItem[]>(key);
    if (cached) return cached;
    const data = await this.request<{ Items: MediaItem[] }>(
      `${this.baseUrl}/Users/${this.userId}/Items/Resume`,
      {
        searchParams: {
          Limit: String(limit),
          Recursive: "true",
          MediaTypes: "Video",
          Fields: "Overview",
        },
      }
    );
    const items = data.Items ?? [];
    cacheSet(key, items, CACHE_TTL.SHORT);
    return items;
  }

  async getNextUp(limit = 12, seriesId?: string): Promise<MediaItem[]> {
    const key = `nextup:${this.userId}:${limit}:${seriesId ?? ""}`;
    const cached = cacheGet<MediaItem[]>(key);
    if (cached) return cached;
    const params: Record<string, string> = {
      UserId: this.userId!,
      Limit: String(limit),
      Fields: "Overview",
    };
    if (seriesId) params.SeriesId = seriesId;
    const q = new URLSearchParams(params).toString();
    const data = await this.request<{ Items: MediaItem[] }>(
      `${this.baseUrl}/Shows/NextUp?${q}`
    );
    const items = data.Items ?? [];
    cacheSet(key, items, CACHE_TTL.SHORT);
    return items;
  }

  async getRecentlyAdded(limit = 16, includeItemTypes?: string[]): Promise<MediaItem[]> {
    const key = `latest:${this.userId}:${limit}:${(includeItemTypes ?? []).join(",")}`;
    const cached = cacheGet<MediaItem[]>(key);
    if (cached) return cached;
    const params: Record<string, string> = {
      Limit: String(limit),
      Fields: "Overview",
    };
    if (includeItemTypes?.length)
      params.IncludeItemTypes = includeItemTypes.join(",");
    const q = new URLSearchParams(params).toString();
    const data = await this.request<MediaItem[]>(
      `${this.baseUrl}/Users/${this.userId}/Items/Latest?${q}`
    );
    const items = Array.isArray(data) ? data : [];
    cacheSet(key, items, CACHE_TTL.MEDIUM);
    return items;
  }

  async getRecentlyReleased(limit = 16): Promise<MediaItem[]> {
    const result = await this.getItems({
      includeItemTypes: ["Movie"],
      limit,
      recursive: true,
      sortBy: "PremiereDate",
      sortOrder: "Descending",
      fields: ["Overview", "PremiereDate"],
    });
    return result.Items;
  }

  async getTopRated(limit = 16): Promise<MediaItem[]> {
    const result = await this.getItems({
      includeItemTypes: ["Movie", "Series"],
      limit,
      recursive: true,
      sortBy: "CommunityRating",
      sortOrder: "Descending",
      fields: ["Overview", "CommunityRating"],
    });
    return result.Items;
  }

  async getRecommended(limit = 16): Promise<MediaItem[]> {
    const key = `suggestions:${this.userId}:${limit}`;
    const cached = cacheGet<MediaItem[]>(key);
    if (cached) return cached;
    const data = await this.request<{ Items: MediaItem[] }>(
      `${this.baseUrl}/Users/${this.userId}/Suggestions`,
      { searchParams: { Limit: String(limit + 10), Fields: "Overview" } }
    );
    const items = (data.Items ?? [])
      .filter(
        (i) =>
          !["CollectionFolder", "Season", "Folder", "Playlist", "BoxSet"].includes(
            i.Type
          )
      )
      .slice(0, limit);
    cacheSet(key, items, CACHE_TTL.MEDIUM);
    return items;
  }

  async getFavorites(limit = 16): Promise<MediaItem[]> {
    const result = await this.getItems({
      isFavorite: true,
      limit,
      recursive: true,
      sortBy: "SortName",
      sortOrder: "Ascending",
      fields: ["Overview"],
    });
    return result.Items;
  }

  async getSeasons(seriesId: string): Promise<MediaItem[]> {
    const key = `seasons:${this.userId}:${seriesId}`;
    const cached = cacheGet<MediaItem[]>(key);
    if (cached) return cached;
    const data = await this.request<{ Items: MediaItem[] }>(
      `${this.baseUrl}/Shows/${seriesId}/Seasons`,
      { searchParams: { UserId: this.userId!, Fields: "Overview" } }
    );
    const items = data.Items ?? [];
    cacheSet(key, items, CACHE_TTL.LONG);
    return items;
  }

  async getEpisodes(seriesId: string, seasonId?: string): Promise<MediaItem[]> {
    const key = `episodes:${this.userId}:${seriesId}:${seasonId ?? ""}`;
    const cached = cacheGet<MediaItem[]>(key);
    if (cached) return cached;
    const params: Record<string, string> = {
      UserId: this.userId!,
      Fields: "Overview,MediaSources",
    };
    if (seasonId) params.SeasonId = seasonId;
    const q = new URLSearchParams(params).toString();
    const data = await this.request<{ Items: MediaItem[] }>(
      `${this.baseUrl}/Shows/${seriesId}/Episodes?${q}`
    );
    const items = data.Items ?? [];
    cacheSet(key, items, CACHE_TTL.LONG);
    return items;
  }

  async getSimilarItems(itemId: string, limit = 12): Promise<MediaItem[]> {
    const key = `similar:${this.userId}:${itemId}:${limit}`;
    const cached = cacheGet<MediaItem[]>(key);
    if (cached) return cached;
    const data = await this.request<{ Items: MediaItem[] }>(
      `${this.baseUrl}/Items/${itemId}/Similar`,
      {
        searchParams: {
          UserId: this.userId!,
          Limit: String(limit),
          Fields: "Overview",
        },
      }
    );
    const items = data.Items ?? [];
    cacheSet(key, items, CACHE_TTL.LONG);
    return items;
  }

  async search(query: string, limit = 20): Promise<SearchHint[]> {
    const key = `search:${this.userId}:${query}:${limit}`;
    const cached = cacheGet<SearchHint[]>(key);
    if (cached) return cached;
    const data = await this.request<{ SearchHints: SearchHint[] }>(
      `${this.baseUrl}/Search/Hints`,
      {
        searchParams: {
          SearchTerm: query,
          Limit: String(limit),
          UserId: this.userId!,
          IncludeItemTypes: "Movie,Series,Episode,Audio,MusicAlbum,MusicArtist",
        },
      }
    );
    const hints = data.SearchHints ?? [];
    cacheSet(key, hints, CACHE_TTL.SHORT);
    return hints;
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
    const body = {
      DeviceProfile: {
        Name: CLIENT_NAME,
        MaxStreamingBitrate: 120000000,
        DirectPlayProfiles: [
          {
            Container: "mp4,m4v,mkv,webm",
            Type: "Video",
            VideoCodec: "h264,hevc,vp8,vp9,av1",
            AudioCodec: "aac,mp3,opus,flac,vorbis",
          },
          { Container: "mp3,flac,opus,aac,m4a,webm", Type: "Audio" },
        ],
        TranscodingProfiles: [
          {
            Container: "ts",
            Type: "Video",
            AudioCodec: "aac,mp3",
            VideoCodec: "h264",
            Context: "Streaming",
            Protocol: "hls",
            MaxAudioChannels: "6",
            MinSegments: "2",
            BreakOnNonKeyFrames: true,
          },
        ],
        SubtitleProfiles: [
          { Format: "srt", Method: "External" },
          { Format: "vtt", Method: "External" },
        ],
      },
    };
    const params: Record<string, string> = { UserId: this.userId! };
    if (options?.audioStreamIndex != null)
      params.AudioStreamIndex = String(options.audioStreamIndex);
    if (options?.subtitleStreamIndex != null)
      params.SubtitleStreamIndex = String(options.subtitleStreamIndex);
    if (options?.startTimeTicks != null)
      params.StartTimeTicks = String(options.startTimeTicks);
    if (options?.mediaSourceId) params.MediaSourceId = options.mediaSourceId;
    const q = new URLSearchParams(params).toString();
    return this.request<PlaybackInfo>(
      `${this.baseUrl}/Items/${itemId}/PlaybackInfo?${q}`,
      { method: "POST", body: JSON.stringify(body) }
    );
  }

  getStreamUrl(
    itemId: string,
    opts?: {
      mediaSourceId?: string;
      audioStreamIndex?: number;
      subtitleStreamIndex?: number;
      startTimeTicks?: number;
    }
  ): string {
    const params: Record<string, string> = {
      api_key: this.accessToken ?? "",
    };
    if (opts?.mediaSourceId) params.MediaSourceId = opts.mediaSourceId;
    if (opts?.audioStreamIndex != null)
      params.AudioStreamIndex = String(opts.audioStreamIndex);
    if (opts?.subtitleStreamIndex != null)
      params.SubtitleStreamIndex = String(opts.subtitleStreamIndex);
    if (opts?.startTimeTicks != null)
      params.StartTimeTicks = String(opts.startTimeTicks);
    const q = new URLSearchParams(params).toString();
    return `${this.baseUrl}/Videos/${itemId}/stream?${q}`;
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
    const params: Record<string, string> = {
      api_key: this.accessToken ?? "",
      DeviceId: this.deviceId,
      TranscodingMaxAudioChannels: "6",
      SegmentContainer: "ts",
      MinSegments: "2",
    };
    if (opts?.mediaSourceId) params.MediaSourceId = opts.mediaSourceId;
    if (opts?.playSessionId) params.PlaySessionId = opts.playSessionId;
    if (opts?.audioStreamIndex != null)
      params.AudioStreamIndex = String(opts.audioStreamIndex);
    if (opts?.subtitleStreamIndex != null)
      params.SubtitleStreamIndex = String(opts.subtitleStreamIndex);
    if (opts?.startTimeTicks != null)
      params.StartTimeTicks = String(opts.startTimeTicks);
    const q = new URLSearchParams(params).toString();
    return `${this.baseUrl}/Videos/${itemId}/master.m3u8?${q}`;
  }

  async reportPlaybackStart(info: {
    ItemId: string;
    MediaSourceId?: string;
    PositionTicks?: number;
    PlaySessionId?: string;
  }): Promise<void> {
    await this.request(`${this.baseUrl}/Sessions/Playing`, {
      method: "POST",
      body: JSON.stringify(info),
    });
  }

  async reportPlaybackProgress(info: {
    ItemId: string;
    PositionTicks: number;
    IsPaused?: boolean;
    PlaySessionId?: string;
  }): Promise<void> {
    await this.request(`${this.baseUrl}/Sessions/Playing/Progress`, {
      method: "POST",
      body: JSON.stringify(info),
    });
  }

  async reportPlaybackStopped(info: {
    ItemId: string;
    PositionTicks: number;
    PlaySessionId?: string;
  }): Promise<void> {
    await this.request(`${this.baseUrl}/Sessions/Playing/Stopped`, {
      method: "POST",
      body: JSON.stringify(info),
    });
  }

  async markPlayed(itemId: string): Promise<void> {
    await this.request(
      `${this.baseUrl}/Users/${this.userId}/PlayedItems/${itemId}`,
      { method: "POST" }
    );
  }

  async markUnplayed(itemId: string): Promise<void> {
    await this.request(
      `${this.baseUrl}/Users/${this.userId}/PlayedItems/${itemId}`,
      { method: "DELETE" }
    );
  }

  async addFavorite(itemId: string): Promise<void> {
    await this.request(
      `${this.baseUrl}/Users/${this.userId}/FavoriteItems/${itemId}`,
      { method: "POST" }
    );
  }

  async removeFavorite(itemId: string): Promise<void> {
    await this.request(
      `${this.baseUrl}/Users/${this.userId}/FavoriteItems/${itemId}`,
      { method: "DELETE" }
    );
  }

  imageUrl(
    itemId: string,
    type: "Primary" | "Backdrop" | "Thumb",
    opts?: { maxWidth?: number; maxHeight?: number; tag?: string; index?: number }
  ): string {
    const params: Record<string, string> = {};
    if (opts?.maxWidth) params.maxWidth = String(opts.maxWidth);
    if (opts?.maxHeight) params.maxHeight = String(opts.maxHeight);
    if (opts?.tag) params.tag = opts.tag;
    const q = new URLSearchParams(params).toString();
    const indexSuffix =
      type === "Backdrop" && opts?.index != null ? `/${opts.index}` : "";
    return `${this.baseUrl}/Items/${itemId}/Images/${type}${indexSuffix}?${q}`;
  }
}

export const api = new JellyfinApi();
