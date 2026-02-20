import { create } from "zustand";
import { persist } from "zustand/middleware";
import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import type { MediaItem } from "../types/jellyfin";
import { api } from "../api/jellyfin";

export type DownloadStatus =
  | "pending"
  | "downloading"
  | "paused"
  | "completed"
  | "failed"
  | "cancelled";

export interface DownloadTask {
  id: string;
  itemId: string;
  itemName: string;
  itemType?: string;
  primaryImageTag?: string;
  /** TV: series id for grouping */
  seriesId?: string | null;
  seriesName?: string | null;
  seasonId?: string | null;
  seasonName?: string | null;
  parentIndexNumber?: number | null;
  indexNumber?: number | null;
  status: DownloadStatus;
  progress: number;
  totalBytes: number;
  downloadedBytes: number;
  localPath?: string | null;
  errorMessage?: string | null;
  createdAt: number;
  completedAt?: number | null;
  serverUrl?: string | null;
}

const STORAGE_KEY = "finar-downloads";
const PROGRESS_THROTTLE_MS = 120;
const progressLastEmit = new Map<string, number>();

/** Sanitize for use in file and folder names */
function sanitizePathSegment(name: string): string {
  return name.replace(/[<>:"/\\|?*\x00-\x1f]/g, "_").replace(/\s+/g, " ").trim() || "Unknown";
}

function isTauri(): boolean {
  return typeof window !== "undefined" && "__TAURI_INTERNALS__" in window;
}

interface DownloadsState {
  tasks: DownloadTask[];
  isTauriEnv: boolean;
  addTask: (task: DownloadTask) => void;
  updateTask: (id: string, patch: Partial<DownloadTask>) => void;
  removeTask: (id: string) => void;
  getTask: (id: string) => DownloadTask | undefined;
  getTaskForItem: (itemId: string) => DownloadTask | undefined;
  getCompletedTasks: () => DownloadTask[];
  getActiveTasks: () => DownloadTask[];
  getFailedTasks: () => DownloadTask[];
  getPausedTasks: () => DownloadTask[];
  isItemDownloaded: (itemId: string) => boolean;
  getLocalPath: (itemId: string) => string | null;
  startDownload: (item: MediaItem) => Promise<void>;
  cancelDownload: (taskId: string) => Promise<void>;
  deleteDownload: (taskId: string) => Promise<void>;
  retryDownload: (taskId: string) => Promise<void>;
  initListeners: () => () => void;
}

export const useDownloadsStore = create<DownloadsState>()(
  persist(
    (set, get) => ({
      tasks: [],
      isTauriEnv: isTauri(),

      addTask(task) {
        set((s) => ({ tasks: [task, ...s.tasks.filter((t) => t.id !== task.id)] }));
      },

      updateTask(id, patch) {
        set((s) => ({
          tasks: s.tasks.map((t) => (t.id === id ? { ...t, ...patch } : t)),
        }));
      },

      removeTask(id) {
        set((s) => ({ tasks: s.tasks.filter((t) => t.id !== id) }));
      },

      getTask(id) {
        return get().tasks.find((t) => t.id === id);
      },

      getTaskForItem(itemId) {
        return get().tasks.find((t) => t.itemId === itemId);
      },

      getCompletedTasks() {
        return get().tasks.filter((t) => t.status === "completed");
      },

      getActiveTasks() {
        return get().tasks.filter(
          (t) => t.status === "downloading" || t.status === "pending"
        );
      },

      getFailedTasks() {
        return get().tasks.filter((t) => t.status === "failed");
      },

      getPausedTasks() {
        return get().tasks.filter((t) => t.status === "paused");
      },

      isItemDownloaded(itemId) {
        return get().tasks.some(
          (t) => t.itemId === itemId && t.status === "completed" && t.localPath
        );
      },

      getLocalPath(itemId) {
        const t = get().tasks.find(
          (x) => x.itemId === itemId && x.status === "completed" && x.localPath
        );
        return t?.localPath ?? null;
      },

      async startDownload(item: MediaItem) {
        if (!get().isTauriEnv) {
          console.warn("Downloads require Tauri environment");
          return;
        }
        const existing = get().getTaskForItem(item.Id);
        if (existing && (existing.status === "downloading" || existing.status === "pending")) {
          return;
        }
        if (existing && existing.status === "completed") {
          return;
        }
        const taskId = `${item.Id}_${Date.now()}`;
        const isEpisode = item.Type === "Episode";
        const task: DownloadTask = {
          id: taskId,
          itemId: item.Id,
          itemName: item.Name,
          itemType: item.Type,
          primaryImageTag: item.ImageTags?.Primary,
          seriesId: item.SeriesId ?? null,
          seriesName: item.SeriesName ?? null,
          seasonId: item.SeasonId ?? null,
          seasonName: item.SeasonName ?? null,
          parentIndexNumber: item.ParentIndexNumber ?? null,
          indexNumber: item.IndexNumber ?? null,
          status: "pending",
          progress: 0,
          totalBytes: 0,
          downloadedBytes: 0,
          createdAt: Date.now(),
          serverUrl: api.serverUrl,
        };
        get().addTask(task);

        try {
          const info = await api.getPlaybackInfo(item.Id);
          const source = api.getBestPlaybackSource(info);
          if (!source) {
            get().updateTask(taskId, {
              status: "failed",
              errorMessage: "No playable source",
            });
            return;
          }
          const isDirect =
            source.SupportsDirectPlay === true || source.SupportsDirectStream === true;
          let url: string;
          if (isDirect && (source.DirectStreamUrl || !source.TranscodingUrl)) {
            if (source.DirectStreamUrl) {
              const u = new URL(source.DirectStreamUrl, api.serverUrl);
              if (!u.searchParams.has("api_key") && api.apiKey) {
                u.searchParams.set("api_key", api.apiKey);
              }
              url = u.toString();
            } else {
              url = api.getStreamUrl(item.Id, {
                mediaSourceId: source.Id,
                container: source.Container,
                static: true,
              });
            }
          } else {
            url = api.getHlsStreamUrl(item.Id, {
              mediaSourceId: source.Id,
              playSessionId: info.PlaySessionId ?? undefined,
            });
          }
          const downloadsDir = await invoke<string>("get_downloads_dir");
          const ext = source.Container ?? "mp4";
          const safeName = sanitizePathSegment(item.Name);
          let path: string;
          if (isEpisode && (item.SeriesName ?? item.SeriesId)) {
            const seriesFolder = sanitizePathSegment(item.SeriesName ?? `Series_${item.SeriesId}`);
            const seasonNum = item.ParentIndexNumber != null ? String(item.ParentIndexNumber).padStart(2, "0") : "00";
            const seasonFolder = `Season ${seasonNum}`;
            path = `${downloadsDir}/${seriesFolder}/${seasonFolder}/${safeName}.${ext}`;
          } else {
            const folder = item.Type === "Movie" ? "Movies" : "Other";
            path = `${downloadsDir}/${folder}/${safeName}.${ext}`;
          }

          get().updateTask(taskId, { status: "downloading" });

          await invoke("download_media_file", {
            payload: {
              url,
              path,
              auth_header: api.getAuthHeader(),
              task_id: taskId,
            },
          });
        } catch (e) {
          const msg = e instanceof Error ? e.message : String(e);
          if (msg !== "cancelled") {
            get().updateTask(taskId, {
              status: "failed",
              errorMessage: msg,
            });
          }
        }
      },

      async cancelDownload(taskId: string) {
        if (!get().isTauriEnv) return;
        try {
          await invoke("cancel_download", { taskId });
          get().removeTask(taskId);
        } catch (_) {}
      },

      async deleteDownload(taskId: string) {
        const task = get().getTask(taskId);
        if (!task) return;
        if (get().isTauriEnv && task.localPath) {
          try {
            await invoke("delete_download_file", { path: task.localPath });
          } catch (_) {}
        }
        get().removeTask(taskId);
      },

      async retryDownload(taskId: string) {
        const task = get().getTask(taskId);
        if (!task) return;
        await get().deleteDownload(taskId);
        const item: MediaItem = {
          Id: task.itemId,
          Name: task.itemName,
          Type: (task.itemType as MediaItem["Type"]) ?? "Movie",
          ImageTags: task.primaryImageTag ? { Primary: task.primaryImageTag } : undefined,
          SeriesId: task.seriesId ?? undefined,
          SeriesName: task.seriesName ?? undefined,
          SeasonId: task.seasonId ?? undefined,
          SeasonName: task.seasonName ?? undefined,
          ParentIndexNumber: task.parentIndexNumber ?? undefined,
          IndexNumber: task.indexNumber ?? undefined,
        };
        await get().startDownload(item);
      },

      initListeners() {
        if (!get().isTauriEnv) return () => {};
        const unlistenProgress = listen<{ taskId: string; downloaded: number; total: number }>(
          "download://progress",
          (ev) => {
            const { taskId, downloaded, total } = ev.payload;
            const now = Date.now();
            const last = progressLastEmit.get(taskId) ?? 0;
            const isComplete = total > 0 && downloaded >= total;
            if (isComplete || now - last >= PROGRESS_THROTTLE_MS) {
              if (!isComplete) progressLastEmit.set(taskId, now);
              const progress = total > 0 ? downloaded / total : 0;
              get().updateTask(taskId, {
                downloadedBytes: downloaded,
                totalBytes: total,
                progress,
              });
            }
          }
        );
        const unlistenComplete = listen<{ taskId: string; path: string }>(
          "download://complete",
          (ev) => {
            get().updateTask(ev.payload.taskId, {
              status: "completed",
              progress: 1,
              localPath: ev.payload.path,
              completedAt: Date.now(),
              errorMessage: null,
            });
          }
        );
        const unlistenError = listen<{ taskId: string; error: string }>(
          "download://error",
          (ev) => {
            get().updateTask(ev.payload.taskId, {
              status: "failed",
              errorMessage: ev.payload.error,
            });
          }
        );
        return () => {
          unlistenProgress.then((fn) => fn());
          unlistenComplete.then((fn) => fn());
          unlistenError.then((fn) => fn());
        };
      },
    }),
    { name: STORAGE_KEY, partialize: (s) => ({ tasks: s.tasks }) }
  )
);
