import { create } from "zustand";
import type { MediaItem } from "../types/jellyfin";

/** When set, Player uses this local file path (convertFileSrc) instead of streaming. */
export type LocalPlaybackPath = string | null;

interface PlayerState {
  currentItem: MediaItem | null;
  /** Local file path for playback (Tauri convertFileSrc URL or path). Cleared when playing from stream. */
  localPlaybackPath: LocalPlaybackPath;
  queue: MediaItem[];
  isPlaying: boolean;
  position: number;
  duration: number;
  setCurrentItem: (item: MediaItem | null) => void;
  setQueue: (items: MediaItem[]) => void;
  play: (item: MediaItem) => void;
  /** Play from a downloaded local file (path is filesystem path; caller converts to asset URL for video src). */
  playLocalFile: (item: MediaItem, localPath: string) => void;
  playNext: () => void;
  playPrevious: () => void;
  /** Switch to a specific item in the queue (e.g. user tapped a queue entry). */
  playFromQueue: (item: MediaItem) => void;
  playOrPause: () => void;
  seek: (position: number) => void;
  setDuration: (d: number) => void;
  setPosition: (p: number) => void;
  stop: () => void;
}

export const usePlayerStore = create<PlayerState>((set, get) => ({
  currentItem: null,
  localPlaybackPath: null,
  queue: [],
  isPlaying: false,
  position: 0,
  duration: 0,

  setCurrentItem(item) {
    set({ currentItem: item });
  },

  setQueue(items) {
    set({ queue: items });
  },

  play(item) {
    set({ currentItem: item, localPlaybackPath: null, isPlaying: true, position: 0, duration: 0 });
  },

  playLocalFile(item, localPath) {
    set({
      currentItem: item,
      localPlaybackPath: localPath,
      isPlaying: true,
      position: 0,
      duration: 0,
    });
  },

  playNext() {
    const { queue, currentItem } = get();
    const idx = currentItem ? queue.findIndex((i) => i.Id === currentItem.Id) : -1;
    const next = idx >= 0 && idx < queue.length - 1 ? queue[idx + 1] : null;
    if (next) set({ currentItem: next, isPlaying: true, position: 0, duration: 0 });
  },

  playPrevious() {
    const { queue, currentItem } = get();
    const idx = currentItem ? queue.findIndex((i) => i.Id === currentItem.Id) : -1;
    const prev = idx > 0 ? queue[idx - 1] : null;
    if (prev) set({ currentItem: prev, isPlaying: true, position: 0, duration: 0 });
  },

  playFromQueue(item) {
    set({ currentItem: item, isPlaying: true, position: 0, duration: 0 });
  },

  playOrPause() {
    set((s) => ({ isPlaying: !s.isPlaying }));
  },

  seek(position) {
    set({ position });
  },

  setDuration(d) {
    set({ duration: d });
  },

  setPosition(p) {
    set({ position: p });
  },

  stop() {
    set({
      currentItem: null,
      localPlaybackPath: null,
      queue: [],
      isPlaying: false,
      position: 0,
      duration: 0,
    });
  },
}));
