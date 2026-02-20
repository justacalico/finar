import { create } from "zustand";
import { api } from "../api/jellyfin";
import { fetchHomeData, searchHintsToItems } from "../api/home";
import type { HomeData, MediaItem, Library as LibraryType } from "../types/jellyfin";

interface LibraryState {
  homeData: HomeData | null;
  libraries: LibraryType[];
  searchResults: MediaItem[];
  searchQuery: string;
  isLoading: boolean;
  error: string | null;
  loadHomeData: () => Promise<void>;
  loadLibraries: () => Promise<void>;
  search: (query: string) => Promise<void>;
  clearSearch: () => void;
  clearErrorAndData: () => void;
}

export const useLibraryStore = create<LibraryState>((set) => ({
  homeData: null,
  libraries: [],
  searchResults: [],
  searchQuery: "",
  isLoading: false,
  error: null,

  async loadHomeData() {
    set({ isLoading: true, error: null });
    try {
      const homeData = await fetchHomeData();
      set({ homeData, isLoading: false });
    } catch (e) {
      set({
        isLoading: false,
        error: e instanceof Error ? e.message : "Failed to load",
      });
    }
  },

  async loadLibraries() {
    try {
      const libraries = await api.getLibraries();
      set({ libraries });
    } catch (e) {
      set({
        error: e instanceof Error ? e.message : "Failed to load libraries",
      });
    }
  },

  async search(query: string) {
    if (query.length < 2) {
      set({ searchResults: [], searchQuery: query });
      return;
    }
    set({ searchQuery: query, isLoading: true });
    try {
      const hints = await api.search(query, 30);
      const items = await searchHintsToItems(hints);
      set({ searchResults: items, isLoading: false });
    } catch (e) {
      set({
        searchResults: [],
        isLoading: false,
        error: e instanceof Error ? e.message : "Search failed",
      });
    }
  },

  clearSearch() {
    set({ searchResults: [], searchQuery: "" });
  },

  clearErrorAndData() {
    set({
      homeData: null,
      libraries: [],
      searchResults: [],
      error: null,
    });
  },
}));
