import type { JellyfinApi } from './jellyfinApi';
import type {
  MediaItem,
  HomeData,
  LibraryContent,
  StreamInfo,
  SearchResults,
  Library,
} from './models';

export function createMediaService(api: JellyfinApi) {
  return {
    async getHomeData(): Promise<HomeData> {
      const [
        continueWatching,
        nextUp,
        recentlyAdded,
        recentlyReleased,
        topRated,
        recommended,
        favorites,
        recentlyAddedMovies,
        recentlyAddedShows,
        libraries,
      ] = await Promise.all([
        api.getContinueWatching(12),
        api.getNextUp(12),
        api.getRecentlyAdded(20),
        api.getRecentlyReleased(16),
        api.getTopRated(16),
        api.getRecommended(16),
        api.getFavorites(16),
        api.getRecentlyAdded(12, undefined, ['Movie']),
        api.getRecentlyAdded(12, undefined, ['Series']),
        api.getLibraries(),
      ]);
      return {
        continueWatching,
        nextUp,
        recentlyAdded,
        recentlyReleased,
        topRated,
        recommended,
        favorites,
        recentlyAddedMovies,
        recentlyAddedShows,
        libraries,
      };
    },

    async getLibraryContent(
      libraryId: string,
      opts?: {
        startIndex?: number;
        limit?: number;
        sortBy?: string;
        sortOrder?: string;
        searchTerm?: string;
      }
    ): Promise<LibraryContent> {
      const result = await api.getItems({
        parentId: libraryId,
        startIndex: opts?.startIndex ?? 0,
        limit: opts?.limit ?? 50,
        sortBy: opts?.sortBy ?? 'SortName',
        sortOrder: opts?.sortOrder ?? 'Ascending',
        recursive: true,
        fields: ['Overview', 'PrimaryImageAspectRatio'],
        searchTerm: opts?.searchTerm,
        excludeItemTypes: [
          'Folder',
          'CollectionFolder',
          'UserView',
          'Playlist',
          'Season',
          'Episode',
          'Audio',
          'MusicArtist',
        ],
      });
      return {
        items: result.items,
        totalCount: result.totalCount,
        hasMore: result.startIndex + result.items.length < result.totalCount,
      };
    },

    async getItem(itemId: string): Promise<MediaItem> {
      return api.getItem(itemId);
    },

    async getSeasons(seriesId: string): Promise<MediaItem[]> {
      return api.getSeasons(seriesId);
    },

    async getEpisodes(seriesId: string, seasonId?: string): Promise<MediaItem[]> {
      return api.getEpisodes(seriesId, seasonId);
    },

    async getNextUpForSeries(seriesId: string): Promise<MediaItem | null> {
      const items = await api.getNextUp(1, seriesId);
      return items.length > 0 ? items[0] : null;
    },

    async getSimilarItems(itemId: string, limit = 12): Promise<MediaItem[]> {
      return api.getSimilarItems(itemId, limit);
    },

    async getStreamInfo(
      itemId: string,
      opts?: {
        audioStreamIndex?: number;
        subtitleStreamIndex?: number;
        startTimeTicks?: number;
      }
    ): Promise<StreamInfo> {
      const playbackInfo = await api.getPlaybackInfo(itemId, {
        audioStreamIndex: opts?.audioStreamIndex,
        subtitleStreamIndex: opts?.subtitleStreamIndex,
        startTimeTicks: opts?.startTimeTicks,
      });
      const sources = playbackInfo.mediaSources;
      const source =
        sources.find((s) => s.supportsDirectPlay) ??
        sources.find((s) => s.supportsDirectStream) ??
        sources[0];
      if (!source) throw new Error('No playable media source found');

      let streamUrl: string;
      let isTranscoding = false;
      if (source.supportsDirectPlay || source.supportsDirectStream) {
        streamUrl = api.getStreamUrl(itemId, {
          mediaSourceId: source.id,
          container: source.container,
          audioStreamIndex: opts?.audioStreamIndex ?? source.defaultAudioStreamIndex,
          subtitleStreamIndex: opts?.subtitleStreamIndex,
          startTimeTicks: opts?.startTimeTicks,
          static: true,
        });
      } else {
        isTranscoding = true;
        streamUrl = api.getHlsStreamUrl(itemId, {
          mediaSourceId: source.id,
          playSessionId: playbackInfo.playSessionId,
          audioStreamIndex: opts?.audioStreamIndex ?? source.defaultAudioStreamIndex,
          subtitleStreamIndex: opts?.subtitleStreamIndex,
          startTimeTicks: opts?.startTimeTicks,
        });
      }

      return {
        url: streamUrl,
        mediaSource: source,
        playSessionId: playbackInfo.playSessionId,
        isTranscoding,
        audioStreams: source.mediaStreams?.filter((s) => s.type === 'Audio') ?? [],
        subtitleStreams: source.mediaStreams?.filter((s) => s.type === 'Subtitle') ?? [],
        defaultAudioIndex: source.defaultAudioStreamIndex,
        defaultSubtitleIndex: source.defaultSubtitleStreamIndex,
      };
    },

    async search(query: string): Promise<SearchResults> {
      const hints = await api.search(query);
      const all = hints;
      const movies = hints.filter((h) => h.type === 'Movie');
      const series = hints.filter((h) => h.type === 'Series');
      const episodes = hints.filter((h) => h.type === 'Episode');
      const music = hints.filter((h) =>
        ['Audio', 'MusicAlbum', 'MusicArtist'].includes(h.type ?? '')
      );
      return { movies, series, episodes, music, all };
    },

    getImageUrl: (
      itemId: string,
      imageType: string,
      opts?: { width?: number; height?: number; quality?: number; tag?: string; index?: number }
    ) => api.getImageUrl(itemId, imageType, opts),

    async toggleFavorite(itemId: string, currentState: boolean): Promise<boolean> {
      if (currentState) {
        await api.removeFavorite(itemId);
        return false;
      }
      await api.addFavorite(itemId);
      return true;
    },

    async markPlayed(itemId: string): Promise<void> {
      await api.markPlayed(itemId);
    },

    async markUnplayed(itemId: string): Promise<void> {
      await api.markUnplayed(itemId);
    },
  };
}

export type MediaService = ReturnType<typeof createMediaService>;
