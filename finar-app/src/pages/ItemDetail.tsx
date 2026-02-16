import { useEffect, useRef, useState } from "react";
import { useParams, useNavigate, useSearchParams } from "react-router-dom";
import {
  Play,
  Plus,
  Star,
  ArrowLeft,
  Download,
  Loader2,
  CheckCircle2,
  DownloadCloud,
  FolderDown,
} from "lucide-react";
import { api } from "../api/jellyfin";
import { usePlayerStore } from "../stores/player";
import { useTranslation } from "../translations";
import { useDownloadsStore } from "../stores/downloads";
import { getBackdropUrl, getDisplayImageUrl, getPrimaryImageUrl } from "../utils/image";
import { AlbumCard } from "../components/AlbumCard";
import { MediaCard } from "../components/MediaCard";
import { Button } from "../components/Button";
import type { MediaItem } from "../types/jellyfin";

export function ItemDetail() {
  const { t } = useTranslation();
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [item, setItem] = useState<MediaItem | null>(null);
  const [seasons, setSeasons] = useState<MediaItem[]>([]);
  const [episodes, setEpisodes] = useState<MediaItem[]>([]);
  const [tracks, setTracks] = useState<MediaItem[]>([]);
  const [similar, setSimilar] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedSeasonId, setSelectedSeasonId] = useState<string | null>(null);
  const [highlightEpisodeId, setHighlightEpisodeId] = useState<string | null>(null);
  const [highlightTrackId, setHighlightTrackId] = useState<string | null>(null);
  const [downloadingAll, setDownloadingAll] = useState(false);
  const highlightedEpisodeRef = useRef<HTMLDivElement | null>(null);
  const highlightedTrackRef = useRef<HTMLDivElement | null>(null);
  const { play, playLocalFile, setQueue } = usePlayerStore();
  const { isTauriEnv, getTaskForItem, startDownload, cancelDownload, isItemDownloaded } =
    useDownloadsStore();

  useEffect(() => {
    if (!id) return;
    let cancelled = false;
    setLoading(true);
    setHighlightEpisodeId(null);
    setHighlightTrackId(searchParams.get("highlight"));
    setTracks([]);
    api
      .getItem(id)
      .then((data) => {
        if (cancelled) return;
        if (data.Type === "Episode" && data.SeriesId) {
          const seasonId = data.ParentId ?? data.SeasonId ?? "";
          navigate(`/item/${data.SeriesId}?season=${seasonId}&highlight=${data.Id}`, {
            replace: true,
          });
          return;
        }
        if (data.Type === "Audio" && (data.AlbumId || data.ParentId)) {
          const albumId = data.AlbumId ?? data.ParentId!;
          navigate(`/item/${albumId}?highlight=${data.Id}`, { replace: true });
          return;
        }
        setItem(data);
        if (data.Type === "Series") {
          const seasonParam = searchParams.get("season");
          const highlightParam = searchParams.get("highlight");
          return api.getSeasons(data.Id).then((s) => {
            if (!cancelled) {
              setSeasons(s);
              const first = s[0];
              const initialSeason =
                seasonParam && s.some((se) => se.Id === seasonParam)
                  ? seasonParam
                  : first?.Id ?? null;
              setSelectedSeasonId(initialSeason);
              if (highlightParam) setHighlightEpisodeId(highlightParam);
              if (initialSeason) {
                return api.getEpisodes(data.Id, initialSeason).then((e) => {
                  if (!cancelled) setEpisodes(e);
                });
              }
            }
          });
        }
        if (data.Type === "MusicAlbum") {
          return api
            .getItems({
              parentId: data.Id,
              includeItemTypes: ["Audio"],
              sortBy: "IndexNumber",
              sortOrder: "Ascending",
              limit: 500,
              fields: ["Overview", "MediaSources"],
            })
            .then((res) => {
              if (!cancelled) setTracks(res.Items ?? []);
              return api.getSimilarItems(data.Id, 12);
            })
            .then((s) => {
              if (!cancelled) setSimilar(s);
            });
        }
        return api.getSimilarItems(data.Id, 12).then((s) => {
          if (!cancelled) setSimilar(s);
        });
      })
      .catch((e) => {
        if (!cancelled) setError(e instanceof Error ? e.message : t("library.failedToLoad"));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
  }, [id, navigate, searchParams, t]);

  useEffect(() => {
    if (!item || item.Type !== "Series" || !selectedSeasonId) return;
    let cancelled = false;
    api
      .getEpisodes(item.Id, selectedSeasonId)
      .then((ep) => {
        if (!cancelled) setEpisodes(ep);
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [item, selectedSeasonId]);

  // Scroll highlighted episode into view when episodes load
  useEffect(() => {
    if (!highlightEpisodeId || episodes.length === 0) return;
    highlightedEpisodeRef.current?.scrollIntoView({
      behavior: "smooth",
      block: "nearest",
    });
  }, [highlightEpisodeId, episodes]);

  // Clear highlight after 2 seconds
  useEffect(() => {
    if (!highlightEpisodeId) return;
    const t = setTimeout(() => setHighlightEpisodeId(null), 2000);
    return () => clearTimeout(t);
  }, [highlightEpisodeId]);

  // Scroll highlighted track into view when tracks load
  useEffect(() => {
    if (!highlightTrackId || tracks.length === 0) return;
    highlightedTrackRef.current?.scrollIntoView({
      behavior: "smooth",
      block: "nearest",
    });
  }, [highlightTrackId, tracks]);

  useEffect(() => {
    if (!highlightTrackId) return;
    const t = setTimeout(() => setHighlightTrackId(null), 2000);
    return () => clearTimeout(t);
  }, [highlightTrackId]);

  if (loading || !item) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 px-4">
        <p className="text-text-secondary">{error}</p>
      </div>
    );
  }

  const isSeries = item.Type === "Series";
  const isAlbum = item.Type === "MusicAlbum";
  const isArtist = item.Type === "MusicArtist";
  const isMusicDetail = isAlbum || isArtist;
  const heroImageUrl = isMusicDetail
    ? getPrimaryImageUrl(item, { maxWidth: 800 })
    : getBackdropUrl(item, 0, { maxWidth: 1280 });
  const isPlayable = ["Movie", "Episode", "Audio", "MusicVideo"].includes(item.Type);

  const formatTicks = (ticks?: number) => {
    if (ticks == null || !Number.isFinite(ticks)) return "";
    const sec = Math.floor(ticks / 10_000_000);
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m}:${s.toString().padStart(2, "0")}`;
  };

  const handlePlay = () => {
    if (isSeries) {
      if (episodes.length > 0) {
        play(episodes[0]);
        navigate("/player");
      }
      return;
    }
    if (isAlbum && tracks.length > 0) {
      setQueue(tracks);
      play(tracks[0]);
      navigate("/player");
      return;
    }
    play(item);
    if (isPlayable && item.Type !== "Audio") navigate("/player");
  };

  const handleDownloadSeason = () => {
    if (!isTauriEnv || episodes.length === 0) return;
    episodes.forEach((ep) => {
      if (!isItemDownloaded(ep.Id)) {
        const task = getTaskForItem(ep.Id);
        if (!task || (task.status !== "downloading" && task.status !== "pending")) {
          startDownload(ep);
        }
      }
    });
  };

  const handleDownloadAll = async () => {
    if (!isTauriEnv || item?.Type !== "Series" || seasons.length === 0) return;
    setDownloadingAll(true);
    try {
      const allEpisodes: MediaItem[] = [];
      for (const season of seasons) {
        const list = await api.getEpisodes(item.Id, season.Id);
        allEpisodes.push(...list);
      }
      allEpisodes.forEach((ep) => {
        if (!isItemDownloaded(ep.Id)) {
          const task = getTaskForItem(ep.Id);
          if (!task || (task.status !== "downloading" && task.status !== "pending")) {
            startDownload(ep);
          }
        }
      });
    } finally {
      setDownloadingAll(false);
    }
  };

  return (
    <div className="pb-20">
      {isMusicDetail ? (
        <div className="relative w-full overflow-hidden bg-surface">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="absolute left-5 top-5 z-20 hidden items-center gap-2 rounded-lg bg-black/60 px-3 py-2.5 text-sm text-white shadow-lg hover:bg-black/75 md:inline-flex"
            aria-label={t("itemDetail.goBack")}
          >
            <ArrowLeft className="h-4 w-4 shrink-0" />
            {t("itemDetail.back")}
          </button>
          <div className="flex min-h-[280px] flex-col gap-6 p-6 md:flex-row md:items-end md:gap-8 md:p-10">
            <div className="flex shrink-0 justify-center md:justify-start">
              <div className="aspect-square w-full max-w-[240px] overflow-hidden rounded-xl bg-surface-elevated shadow-xl md:max-w-[280px]">
                {heroImageUrl ? (
                  <img
                    src={heroImageUrl}
                    alt=""
                    className="h-full w-full object-cover"
                  />
                ) : (
                  <div className="flex h-full w-full items-center justify-center text-text-tertiary">
                    <span className="text-4xl font-bold opacity-40">
                      {item.Name.charAt(0)}
                    </span>
                  </div>
                )}
              </div>
            </div>
            <div className="min-w-0 flex-1 pb-1">
              <span className="rounded bg-primary/90 px-2 py-0.5 text-xs font-bold uppercase text-background">
                {t(`contentType.${item.Type}`) || item.Type}
              </span>
              <h1 className="mt-2 text-2xl font-bold text-text-primary md:text-4xl">
                {item.Name}
              </h1>
              <div className="mt-2 flex flex-wrap gap-3 text-sm text-text-secondary">
                {item.ProductionYear && <span>{item.ProductionYear}</span>}
                {item.CommunityRating != null && (
                  <span className="flex items-center gap-1">
                    <Star className="h-4 w-4 fill-amber-400 text-amber-400" />
                    {item.CommunityRating.toFixed(1)}
                  </span>
                )}
                {item.OfficialRating && <span>{item.OfficialRating}</span>}
              </div>
              <div className="mt-4 flex flex-wrap gap-3">
                {(isPlayable || (isAlbum && tracks.length > 0)) && (
                  <Button
                    leftIcon={<Play className="h-5 w-5" fill="currentColor" />}
                    onClick={handlePlay}
                  >
                    {t("home.play")}
                  </Button>
                )}
                <Button variant="outline" leftIcon={<Plus className="h-4 w-4" />}>
                  {t("itemDetail.addToList")}
                </Button>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className="relative h-[45vw] max-h-[500px] min-h-[240px] w-full overflow-hidden">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="absolute left-5 top-5 z-20 hidden items-center gap-2 rounded-lg bg-black/60 px-3 py-2.5 text-sm text-white shadow-lg hover:bg-black/75 md:inline-flex"
            aria-label={t("itemDetail.goBack")}
          >
            <ArrowLeft className="h-4 w-4 shrink-0" />
            {t("itemDetail.back")}
          </button>
          <img
            src={heroImageUrl}
            alt=""
            className="absolute inset-0 h-full w-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-background via-background/70 to-transparent" />
          <div className="absolute bottom-0 left-0 right-0 p-6 md:p-10">
            <div className="min-w-0 max-w-3xl">
              <span className="rounded bg-primary/90 px-2 py-0.5 text-xs font-bold uppercase text-background">
                {t(`contentType.${item.Type}`) || item.Type}
              </span>
              <h1 className="mt-2 text-2xl font-bold text-white md:text-4xl">
                {item.Type === "Episode" ? item.SeriesName : item.Name}
                {item.Type === "Episode" && (
                  <span className="text-white/90">
                    {" "}
                    — S{item.ParentIndexNumber} E{item.IndexNumber}
                  </span>
                )}
              </h1>
              <div className="mt-2 flex flex-wrap gap-3 text-sm text-white/80">
                {item.ProductionYear && <span>{item.ProductionYear}</span>}
                {item.CommunityRating != null && (
                  <span className="flex items-center gap-1">
                    <Star className="h-4 w-4 fill-amber-400 text-amber-400" />
                    {item.CommunityRating.toFixed(1)}
                  </span>
                )}
                {item.OfficialRating && <span>{item.OfficialRating}</span>}
              </div>
              <div className="mt-4 flex flex-wrap gap-3">
                {(isPlayable || (isAlbum && tracks.length > 0)) && (
                  <Button
                    leftIcon={<Play className="h-5 w-5" fill="currentColor" />}
                    onClick={handlePlay}
                  >
                    {t("home.play")}
                  </Button>
                )}
                {isTauriEnv && isPlayable && (() => {
                  const task = getTaskForItem(item.Id);
                  if (task?.status === "completed" && task.localPath) {
                    return (
                      <Button
                        variant="outline"
                        leftIcon={<CheckCircle2 className="h-4 w-4" />}
                        onClick={() => {
                          playLocalFile(item, task.localPath!);
                          navigate("/player");
                        }}
                      >
                        {t("itemDetail.playOffline")}
                      </Button>
                    );
                  }
                  if (task?.status === "downloading" || task?.status === "pending") {
                    return (
                      <Button
                        variant="outline"
                        leftIcon={<Loader2 className="h-4 w-4 animate-spin" />}
                        onClick={() => cancelDownload(task.id)}
                      >
                        {Math.round((task.progress ?? 0) * 100)}% — {t("downloads.cancel")}
                      </Button>
                    );
                  }
                  if (task?.status === "failed") {
                    return (
                      <Button
                        variant="outline"
                        leftIcon={<Download className="h-4 w-4" />}
                        onClick={() => startDownload(item)}
                      >
                        {t("itemDetail.retryDownload")}
                      </Button>
                    );
                  }
                  return (
                    <Button
                      variant="outline"
                      leftIcon={<Download className="h-4 w-4" />}
                      onClick={() => startDownload(item)}
                    >
                      {t("itemDetail.download")}
                    </Button>
                  );
                })()}
                {isTauriEnv && isSeries && (
                  <Button
                    variant="outline"
                    leftIcon={
                      downloadingAll ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <DownloadCloud className="h-4 w-4" />
                      )
                    }
                    onClick={handleDownloadAll}
                    disabled={downloadingAll || seasons.length === 0}
                  >
                    {downloadingAll ? t("itemDetail.preparing") : t("itemDetail.downloadAll")}
                  </Button>
                )}
                <Button variant="outline" leftIcon={<Plus className="h-4 w-4" />}>
                  {t("itemDetail.addToList")}
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
      <div className="mx-auto max-w-6xl px-4 py-6 md:px-8">
        {item.Overview && (
          <section className="mb-8">
            <h2 className="mb-2 text-lg font-semibold text-text-primary">
              {t("itemDetail.overview")}
            </h2>
            <p className="text-text-secondary">{item.Overview}</p>
          </section>
        )}

        {isSeries && seasons.length > 0 && (
          <section className="mb-8">
            <h2 className="mb-4 text-lg font-semibold text-text-primary">
              {t("itemDetail.seasons")}
            </h2>
            <div className="flex flex-wrap gap-2">
              {seasons.map((s) => (
                <button
                  key={s.Id}
                  type="button"
                  onClick={() => setSelectedSeasonId(s.Id)}
                  className={`rounded-xl px-4 py-2 text-sm font-medium transition-colors ${
                    selectedSeasonId === s.Id
                      ? "bg-primary text-background"
                      : "bg-surface text-text-secondary hover:bg-white/10"
                  }`}
                >
                  {s.Name}
                </button>
              ))}
            </div>
          </section>
        )}

        {isSeries && episodes.length > 0 && (
          <section className="mb-8">
            <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
              <h2 className="text-lg font-semibold text-text-primary">
                {t("itemDetail.episodes")}
              </h2>
              {isTauriEnv && (
                <Button
                  variant="outline"
                  size="sm"
                  leftIcon={<FolderDown className="h-4 w-4" />}
                  onClick={handleDownloadSeason}
                >
                  {t("itemDetail.downloadSeason")}
                </Button>
              )}
            </div>
            <div className="space-y-2">
              {episodes.map((ep) => (
                <div
                  key={ep.Id}
                  ref={ep.Id === highlightEpisodeId ? highlightedEpisodeRef : undefined}
                  role="button"
                  tabIndex={0}
                  onClick={() => {
                    play(ep);
                    navigate("/player");
                  }}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") {
                      e.preventDefault();
                      play(ep);
                      navigate("/player");
                    }
                  }}
                  className={`flex w-full cursor-pointer items-center gap-4 rounded-xl p-3 text-left transition-colors hover:bg-white/10 ${
                    ep.Id === highlightEpisodeId
                      ? "bg-primary/20 ring-2 ring-primary"
                      : "bg-surface"
                  }`}
                >
                  <span className="flex h-12 w-20 shrink-0 overflow-hidden rounded-lg bg-surface-elevated">
                    <img
                      src={getDisplayImageUrl(ep, { maxWidth: 160 })}
                      alt=""
                      className="h-full w-full object-cover"
                    />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="font-medium text-text-primary">
                      {ep.IndexNumber}. {ep.Name}
                    </p>
                    {ep.Overview && (
                      <p className="truncate text-sm text-text-tertiary">
                        {ep.Overview}
                      </p>
                    )}
                  </div>
                  {isTauriEnv && (() => {
                    const task = getTaskForItem(ep.Id);
                    if (task?.status === "completed" && task.localPath) {
                      return (
                        <span
                          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-primary"
                          title={t("itemDetail.downloaded")}
                        >
                          <CheckCircle2 className="h-5 w-5" />
                        </span>
                      );
                    }
                    if (task?.status === "downloading" || task?.status === "pending") {
                      return (
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            cancelDownload(task.id);
                          }}
                          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-primary hover:bg-white/10"
                          title={t("itemDetail.cancelDownload")}
                        >
                          <Loader2 className="h-5 w-5 animate-spin" />
                        </button>
                      );
                    }
                    if (task?.status === "failed") {
                      return (
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            startDownload(ep);
                          }}
                          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-text-secondary hover:bg-white/10 hover:text-primary"
                          title={t("itemDetail.retryDownload")}
                        >
                          <Download className="h-5 w-5" />
                        </button>
                      );
                    }
                    return (
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          startDownload(ep);
                        }}
                        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-text-secondary hover:bg-white/10 hover:text-primary"
                        title={t("itemDetail.downloadEpisode")}
                      >
                        <Download className="h-5 w-5" />
                      </button>
                    );
                  })()}
                  <Play className="h-5 w-5 shrink-0 text-primary" fill="currentColor" />
                </div>
              ))}
            </div>
          </section>
        )}

        {isAlbum && tracks.length > 0 && (
          <section className="mb-8">
            <h2 className="mb-4 text-lg font-semibold text-text-primary">
              {t("library.tracks")}
            </h2>
            <div className="space-y-1">
              {tracks.map((track) => (
                <div
                  key={track.Id}
                  ref={track.Id === highlightTrackId ? highlightedTrackRef : undefined}
                  role="button"
                  tabIndex={0}
                  onClick={() => {
                    setQueue(tracks);
                    play(track);
                    navigate("/player");
                  }}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") {
                      e.preventDefault();
                      setQueue(tracks);
                      play(track);
                      navigate("/player");
                    }
                  }}
                  className={`flex cursor-pointer items-center gap-4 rounded-lg px-3 py-2.5 text-left transition-colors hover:bg-white/10 ${
                    track.Id === highlightTrackId
                      ? "bg-primary/20 ring-2 ring-primary"
                      : "bg-surface"
                  }`}
                >
                  <span className="w-8 shrink-0 text-sm text-text-tertiary">
                    {track.IndexNumber ?? "—"}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="font-medium text-text-primary">{track.Name}</p>
                    {track.Artists?.length ? (
                      <p className="truncate text-sm text-text-tertiary">
                        {track.Artists.join(", ")}
                      </p>
                    ) : null}
                  </div>
                  <span className="shrink-0 text-sm text-text-tertiary">
                    {formatTicks(track.RunTimeTicks)}
                  </span>
                  <Play className="h-5 w-5 shrink-0 text-primary" fill="currentColor" />
                </div>
              ))}
            </div>
          </section>
        )}

        {similar.length > 0 && (
          <section>
            <h2 className="mb-4 text-lg font-semibold text-text-primary">
              {t("itemDetail.moreLikeThis")}
            </h2>
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4">
              {similar.map((s, i) =>
                s.Type === "MusicAlbum" ? (
                  <AlbumCard
                    key={s.Id}
                    item={s}
                    index={i}
                    onClick={() => navigate(`/item/${s.Id}`)}
                  />
                ) : (
                  <MediaCard
                    key={s.Id}
                    item={s}
                    index={i}
                    onClick={() => navigate(`/item/${s.Id}`)}
                  />
                ),
              )}
            </div>
          </section>
        )}
      </div>
    </div>
  );
}
