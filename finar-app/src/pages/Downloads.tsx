import { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Download,
  Trash2,
  Play,
  Pause,
  RotateCw,
  Loader2,
  CheckCircle2,
  AlertCircle,
  FolderDown,
} from "lucide-react";
import { useDownloadsStore, type DownloadTask, type DownloadStatus } from "../stores/downloads";
import { useTranslation } from "../translations";
import { usePlayerStore } from "../stores/player";
import { api } from "../api/jellyfin";
import { GlassCard } from "../components/GlassCard";

type Filter = "all" | "completed" | "downloading" | "paused" | "failed";

const filterKeys: Record<Filter, string> = {
  all: "filterAll",
  completed: "filterCompleted",
  downloading: "filterDownloading",
  paused: "filterPaused",
  failed: "filterFailed",
};

function getTaskImageUrl(task: DownloadTask, apiKey: string | null): string {
  if (!task.primaryImageTag || !task.serverUrl) return "";
  const url = `${task.serverUrl}/Items/${task.itemId}/Images/Primary?maxWidth=400&tag=${task.primaryImageTag}`;
  if (apiKey) return `${url}&api_key=${encodeURIComponent(apiKey)}`;
  return url;
}

function formatBytes(n: number): string {
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  if (n < 1024 * 1024 * 1024) return `${(n / (1024 * 1024)).toFixed(1)} MB`;
  return `${(n / (1024 * 1024 * 1024)).toFixed(2)} GB`;
}

function statusIcon(status: DownloadStatus) {
  switch (status) {
    case "downloading":
    case "pending":
      return <Loader2 className="h-5 w-5 animate-spin" />;
    case "completed":
      return <CheckCircle2 className="h-5 w-5 text-green-500" />;
    case "failed":
      return <AlertCircle className="h-5 w-5 text-red-500" />;
    case "paused":
      return <Pause className="h-5 w-5" />;
    case "cancelled":
      return <Download className="h-5 w-5 opacity-50" />;
    default:
      return <Download className="h-5 w-5" />;
  }
}

/** Group tasks into movies (and other non-TV) vs series → seasons → episodes */
function groupDownloadTasks(tasks: DownloadTask[]) {
  const movies: DownloadTask[] = [];
  const seriesMap = new Map<
    string,
    { name: string; seasons: Map<number | string, DownloadTask[]> }
  >();
  for (const task of tasks) {
    const hasSeries = task.seriesId ?? task.seriesName;
    if (!hasSeries || (task.itemType !== "Episode" && !task.seriesName)) {
      movies.push(task);
      continue;
    }
    const key = task.seriesId ?? task.seriesName ?? "unknown";
    const name = task.seriesName ?? `Series ${task.seriesId ?? "?"}`;
    if (!seriesMap.has(key)) {
      seriesMap.set(key, { name, seasons: new Map() });
    }
    const entry = seriesMap.get(key)!;
    const seasonKey = task.parentIndexNumber ?? task.seasonName ?? "?";
    if (!entry.seasons.has(seasonKey)) {
      entry.seasons.set(seasonKey, []);
    }
    entry.seasons.get(seasonKey)!.push(task);
  }
  for (const entry of seriesMap.values()) {
    entry.seasons.forEach((eps) => eps.sort((a, b) => (a.indexNumber ?? 0) - (b.indexNumber ?? 0)));
  }
  return { movies, series: Array.from(seriesMap.entries()) };
}

export function Downloads() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [filter, setFilter] = useState<Filter>("all");
  const {
    tasks,
    isTauriEnv,
    getCompletedTasks,
    getActiveTasks,
    getFailedTasks,
    getPausedTasks,
    cancelDownload,
    deleteDownload,
    retryDownload,
  } = useDownloadsStore();
  const { playLocalFile } = usePlayerStore();

  const filtered =
    filter === "all"
      ? tasks.filter((t) => t.status !== "cancelled")
      : filter === "completed"
        ? getCompletedTasks()
        : filter === "downloading"
          ? getActiveTasks()
          : filter === "paused"
            ? getPausedTasks()
            : getFailedTasks();

  const handlePlay = (task: DownloadTask) => {
    if (task.status !== "completed" || !task.localPath) return;
    const item = {
      Id: task.itemId,
      Name: task.itemName,
      Type: (task.itemType as "Movie" | "Episode") ?? "Movie",
    };
    playLocalFile(item, task.localPath);
    navigate("/player");
  };

  const handleDelete = async (task: DownloadTask) => {
    if (window.confirm(t("downloads.removeConfirm", { name: task.itemName }))) {
      await deleteDownload(task.id);
    }
  };

  if (!isTauriEnv) {
    return (
      <div className="flex min-h-[50vh] flex-col items-center justify-center gap-4 px-4">
        <FolderDown className="h-16 w-16 text-text-tertiary/50" />
        <h2 className="text-xl font-semibold text-text-primary">{t("downloads.title")}</h2>
        <p className="max-w-sm text-center text-sm text-text-tertiary">
          {t("downloads.tauriOnlyMessage")}
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6 p-4 md:p-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-semibold text-text-primary">{t("downloads.title")}</h1>
        <div className="flex flex-wrap gap-2">
          {(Object.keys(filterKeys) as Filter[]).map((key) => (
            <button
              key={key}
              type="button"
              onClick={() => setFilter(key)}
              className={`rounded-lg px-3 py-1.5 text-sm font-medium transition ${
                filter === key
                  ? "bg-primary text-background"
                  : "bg-surface-elevated text-text-secondary hover:bg-surface hover:text-text-primary"
              }`}
            >
              {t(`downloads.${filterKeys[key]}`)}
            </button>
          ))}
        </div>
      </div>

      {filtered.length === 0 ? (
        <div className="flex min-h-[40vh] flex-col items-center justify-center gap-4 rounded-2xl bg-surface-elevated/50 p-8">
          <Download className="h-14 w-14 text-text-tertiary/50" />
          <h2 className="text-lg font-medium text-text-primary">
            {filter === "all" ? t("downloads.noDownloadsYet") : `No ${t(`downloads.${filterKeys[filter]}`).toLowerCase()}`}
          </h2>
          <p className="max-w-md text-center text-sm text-text-tertiary">
            {filter === "all" ? t("downloads.downloadHint") : t("downloads.changeFilterHint")}
          </p>
        </div>
      ) : (
        <div className="flex flex-col gap-8">
          {(() => {
            const { movies, series } = groupDownloadTasks(filtered);
            return (
              <>
                {movies.length > 0 && (
                  <section>
                    <h2 className="mb-3 text-lg font-semibold text-text-primary">
                      {t("downloads.moviesAndOther")}
                    </h2>
                    <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
                      {movies.map((task) => (
                        <DownloadCard
                          key={task.id}
                          task={task}
                          imageUrl={getTaskImageUrl(task, api.apiKey)}
                          onPlay={() => handlePlay(task)}
                          onPause={() => cancelDownload(task.id)}
                          onRetry={() => retryDownload(task.id)}
                          onDelete={() => handleDelete(task)}
                        />
                      ))}
                    </div>
                  </section>
                )}
                {series.map(([seriesKey, { name: seriesName, seasons }]) => (
                  <section key={seriesKey}>
                    <h2 className="mb-3 text-lg font-semibold text-text-primary">{seriesName}</h2>
                    <div className="flex flex-col gap-6">
                      {Array.from(seasons.entries())
                        .sort(([a], [b]) => {
                          const na = typeof a === "number" ? a : NaN;
                          const nb = typeof b === "number" ? b : NaN;
                          if (!Number.isNaN(na) && !Number.isNaN(nb)) return na - nb;
                          return String(a).localeCompare(String(b));
                        })
                        .map(([seasonKey, episodeTasks]) => (
                          <div key={String(seasonKey)}>
                            <h3 className="mb-2 text-sm font-medium text-text-secondary">
                              {typeof seasonKey === "number"
                                ? `${t("downloads.season")} ${seasonKey}`
                                : seasonKey}
                            </h3>
                            <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
                              {episodeTasks.map((task) => (
                                <DownloadCard
                                  key={task.id}
                                  task={task}
                                  imageUrl={getTaskImageUrl(task, api.apiKey)}
                                  onPlay={() => handlePlay(task)}
                                  onPause={() => cancelDownload(task.id)}
                                  onRetry={() => retryDownload(task.id)}
                                  onDelete={() => handleDelete(task)}
                                  subtitle={
                                    task.indexNumber != null
                                      ? `S${task.parentIndexNumber ?? "?"} E${task.indexNumber}`
                                      : undefined
                                  }
                                />
                              ))}
                            </div>
                          </div>
                        ))}
                    </div>
                  </section>
                ))}
              </>
            );
          })()}
        </div>
      )}
    </div>
  );
}

function DownloadCard({
  task,
  imageUrl,
  onPlay,
  onPause,
  onRetry,
  onDelete,
  subtitle,
}: {
  task: DownloadTask;
  imageUrl: string;
  onPlay: () => void;
  onPause: () => void;
  onRetry: () => void;
  onDelete: () => void;
  subtitle?: string;
}) {
  const { t } = useTranslation();
  const isActive = task.status === "downloading" || task.status === "pending";
  const isCompleted = task.status === "completed";
  const isFailed = task.status === "failed";

  return (
    <GlassCard className="overflow-hidden">
      <div className="relative aspect-[2/3] bg-surface">
        {imageUrl ? (
          <img
            src={imageUrl}
            alt=""
            className="h-full w-full object-cover"
          />
        ) : (
          <div className="flex h-full w-full items-center justify-center text-text-tertiary">
            <Download className="h-12 w-12" />
          </div>
        )}
        {isActive && (
          <div className="absolute inset-0 flex items-center justify-center bg-black/60">
            <div className="text-center text-white">
              <Loader2 className="mx-auto h-8 w-8 animate-spin" />
              <p className="mt-1 text-sm">
                {task.totalBytes > 0
                  ? `${Math.round(task.progress * 100)}%`
                  : t("downloads.starting")}
              </p>
              {task.totalBytes > 0 && (
                <p className="text-xs opacity-90">
                  {formatBytes(task.downloadedBytes)} / {formatBytes(task.totalBytes)}
                </p>
              )}
            </div>
          </div>
        )}
        {isCompleted && (
          <div className="absolute bottom-2 left-2 right-2 flex gap-2">
            <button
              type="button"
              onClick={onPlay}
              className="flex flex-1 items-center justify-center gap-1.5 rounded-lg bg-primary py-2 text-sm font-medium text-background hover:opacity-90"
            >
              <Play className="h-4 w-4" fill="currentColor" />
              {t("home.play")}
            </button>
            <button
              type="button"
              onClick={onDelete}
              className="rounded-lg bg-white/20 p-2 text-white hover:bg-white/30"
              title={t("downloads.removeDownload")}
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        )}
      </div>
      <div className="flex items-center gap-2 p-3">
        <span className="text-text-tertiary">{statusIcon(task.status)}</span>
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-medium text-text-primary">{task.itemName}</p>
          <p className="text-xs text-text-tertiary">
            {subtitle ?? (task.status === "downloading" && task.totalBytes > 0
              ? `${formatBytes(task.downloadedBytes)} / ${formatBytes(task.totalBytes)}`
              : task.status === "failed" && task.errorMessage
                ? task.errorMessage
                : task.status)}
          </p>
        </div>
        {isActive && (
          <button
            type="button"
            onClick={onPause}
            className="rounded-lg p-1.5 text-text-secondary hover:bg-surface hover:text-text-primary"
            title={t("downloads.cancel")}
          >
            <Pause className="h-4 w-4" />
          </button>
        )}
        {isFailed && (
          <button
            type="button"
            onClick={onRetry}
            className="rounded-lg p-1.5 text-text-secondary hover:bg-surface hover:text-primary"
            title={t("downloads.retry")}
          >
            <RotateCw className="h-4 w-4" />
          </button>
        )}
        {isCompleted && (
          <button
            type="button"
            onClick={onDelete}
            className="rounded-lg p-1.5 text-text-tertiary hover:bg-surface hover:text-red-400"
            title={t("downloads.removeDownload")}
          >
            <Trash2 className="h-4 w-4" />
          </button>
        )}
      </div>
    </GlassCard>
  );
}
