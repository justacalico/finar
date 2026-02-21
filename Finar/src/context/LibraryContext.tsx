import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { useJellyfinApi } from './AuthContext';
import { createMediaService } from '../api/mediaService';
import type { HomeData, Library, MediaItem } from '../api/models';
import type { SearchHint } from '../api/models';

type LibraryContextValue = {
  homeData: HomeData | null;
  libraries: Library[];
  searchResults: MediaItem[];
  isLoading: boolean;
  error: string | null;
  loadHomeData: () => Promise<void>;
  loadLibraries: () => Promise<void>;
  search: (query: string) => Promise<void>;
  clearSearch: () => void;
  featuredItem: MediaItem | null;
};

const LibraryContext = createContext<LibraryContextValue | null>(null);

function searchHintsToMediaItems(hints: SearchHint[], apiBaseUrl: string | null): MediaItem[] {
  if (!apiBaseUrl) return [];
  return hints.map((h) => ({
    id: h.itemId,
    name: h.name,
    type: (h.type?.toLowerCase() as MediaItem['type']) ?? 'unknown',
    typeString: h.type,
    productionYear: h.productionYear,
    imageTags: h.primaryImageTag ? { primary: h.primaryImageTag } : undefined,
    seriesName: h.series,
    album: h.album,
    albumArtist: h.albumArtist,
    indexNumber: h.indexNumber,
    parentIndexNumber: h.parentIndexNumber,
  }));
}

export function LibraryProvider({ children }: { children: React.ReactNode }) {
  const api = useJellyfinApi();
  const [homeData, setHomeData] = useState<HomeData | null>(null);
  const [libraries, setLibraries] = useState<Library[]>([]);
  const [searchResults, setSearchResults] = useState<MediaItem[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const mediaService = useMemo(() => createMediaService(api), [api]);

  const loadHomeData = useCallback(async () => {
    if (!api.isAuthenticated) return;
    setIsLoading(true);
    setError(null);
    try {
      const data = await mediaService.getHomeData();
      setHomeData(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load home data');
    } finally {
      setIsLoading(false);
    }
  }, [api.isAuthenticated, mediaService]);

  const loadLibraries = useCallback(async () => {
    if (!api.isAuthenticated) return;
    try {
      const list = await api.getLibraries();
      setLibraries(list);
    } catch {
      setLibraries([]);
    }
  }, [api.isAuthenticated, api]);

  const search = useCallback(
    async (query: string) => {
      setSearchQuery(query);
      if (!query.trim()) {
        setSearchResults([]);
        return;
      }
      setIsLoading(true);
      try {
        const hints = await api.search(query);
        setSearchResults(searchHintsToMediaItems(hints, api.serverUrl));
      } catch {
        setSearchResults([]);
      } finally {
        setIsLoading(false);
      }
    },
    [api]
  );

  const clearSearch = useCallback(() => {
    setSearchQuery('');
    setSearchResults([]);
  }, []);

  useEffect(() => {
    if (api.isAuthenticated) {
      loadLibraries();
      loadHomeData();
    } else {
      setHomeData(null);
      setLibraries([]);
      setSearchResults([]);
    }
  }, [api.isAuthenticated, loadHomeData, loadLibraries]);

  const featuredItem =
    homeData?.continueWatching?.[0] ?? homeData?.recentlyAdded?.[0] ?? null;

  const value = useMemo(
    () => ({
      homeData,
      libraries,
      searchResults,
      isLoading,
      error,
      loadHomeData,
      loadLibraries,
      search,
      clearSearch,
      featuredItem: featuredItem ?? null,
    }),
    [
      homeData,
      libraries,
      searchResults,
      isLoading,
      error,
      loadHomeData,
      loadLibraries,
      search,
      clearSearch,
      featuredItem,
    ]
  );

  return (
    <LibraryContext.Provider value={value}>{children}</LibraryContext.Provider>
  );
}

export function useLibrary(): LibraryContextValue {
  const ctx = useContext(LibraryContext);
  if (!ctx) throw new Error('useLibrary must be used within LibraryProvider');
  return ctx;
}
