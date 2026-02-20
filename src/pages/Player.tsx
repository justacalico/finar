import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import videojs from "video.js";
import "video.js/dist/video-js.css";
import { convertFileSrc } from "@tauri-apps/api/core";
import { Play, Pause, Volume2, VolumeX, SkipBack, SkipForward } from "lucide-react";
import { usePlayerStore } from "../stores/player";
import { useTranslation } from "../translations";
import { api } from "../api/jellyfin";
import { getDisplayImageUrl } from "../utils/image";

/** Ref used by the xhr wrapper to append auth to HLS segment requests. */
const hlsAuthQueryRef = { current: "" };

/** Wrap videojs.xhr so every request gets HLS auth query string (for Jellyfin segment auth). */
function installVideoJsXhrAuthWrapper() {
  const xhr = videojs.xhr as typeof videojs.xhr & {
    requestInterceptorsStorage?: { enable(): void };
    requestType?: string;
  };
  if (typeof xhr !== "function" || (xhr as unknown as { __authWrapped?: boolean }).__authWrapped) {
    return;
  }
  const original = xhr;
  const wrapped = function (
    this: unknown,
    uri: string | Record<string, unknown>,
    options?: Record<string, unknown> | ((err: unknown, a?: unknown, b?: unknown) => void),
    callback?: (err: unknown, a?: unknown, b?: unknown) => void
  ) {
    let opts: Record<string, unknown>;
    let cb: (err: unknown, a?: unknown, b?: unknown) => void;
    if (typeof options === "function") {
      cb = options;
      opts = typeof uri === "string" ? { uri } : { ...uri } as Record<string, unknown>;
    } else if (options && typeof callback === "function") {
      cb = callback;
      opts = { ...options, uri: typeof uri === "string" ? uri : (options as Record<string, unknown>).uri };
    } else {
      cb = options as unknown as (err: unknown, a?: unknown, b?: unknown) => void;
      opts = typeof uri === "string" ? { uri } : { ...uri } as Record<string, unknown>;
    }
    const auth = hlsAuthQueryRef.current;
    const u = (opts.uri as string) || (opts.url as string);
    if (auth && u) {
      const withAuth = u + (u.includes("?") ? "&" : "?") + auth;
      opts.uri = withAuth;
      opts.url = withAuth;
    }
    return (original as (...args: unknown[]) => unknown).call(this, opts, cb);
  };
  (wrapped as unknown as { __authWrapped?: boolean }).__authWrapped = true;
  Object.keys(original).forEach((k) => {
    const key = k as keyof typeof original;
    const orig = original as unknown as Record<string, unknown>;
    if (typeof orig[key] === "function" || orig[key] != null) {
      (wrapped as unknown as Record<string, unknown>)[key] = orig[key];
    }
  });
  (videojs as unknown as { xhr: typeof videojs.xhr }).xhr = wrapped as typeof videojs.xhr;
}

export function Player() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const containerRef = useRef<HTMLDivElement>(null);
  const playerRef = useRef<ReturnType<typeof videojs> | null>(null);
  const sessionRef = useRef<{ sid?: string; mediaSourceId?: string }>({});
  const {
    currentItem,
    localPlaybackPath,
    queue,
    isPlaying,
    position,
    duration,
    setPosition,
    setDuration,
    playNext,
    playPrevious,
    playFromQueue,
    stop,
  } = usePlayerStore();
  const [showControls, setShowControls] = useState(true);
  const [muted, setMuted] = useState(false);
  const [playbackError, setPlaybackError] = useState<string | null>(null);
  const [streamConfig, setStreamConfig] = useState<{
    streamUrl: string;
    isHls: boolean;
    startTimeTicks: number;
  } | null>(null);
  const controlsTimeout = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const progressIntervalRef = useRef<ReturnType<typeof setInterval> | undefined>(undefined);

  useEffect(() => {
    installVideoJsXhrAuthWrapper();
  }, []);

  useEffect(() => {
    return () => {
      if (controlsTimeout.current) clearTimeout(controlsTimeout.current);
    };
  }, []);

  // Local file playback: use convertFileSrc and set streamConfig (no server calls)
  useEffect(() => {
    if (!currentItem || !localPlaybackPath) return;
    setPlaybackError(null);
    try {
      const streamUrl = convertFileSrc(localPlaybackPath);
      setStreamConfig({
        streamUrl,
        isHls: false,
        startTimeTicks: 0,
      });
    } catch (e) {
      setPlaybackError(e instanceof Error ? e.message : t("player.invalidLocalFile"));
    }
    return () => setStreamConfig(null);
  }, [currentItem?.Id, localPlaybackPath]);

  // Load playback info and derive stream URL (direct or HLS) when not local
  useEffect(() => {
    if (!currentItem || localPlaybackPath) {
      if (!currentItem) navigate("/", { replace: true });
      return;
    }
    let cancelled = false;
    setStreamConfig(null);
    setPlaybackError(null);
    api
      .getPlaybackInfo(currentItem.Id, {
        startTimeTicks: currentItem.UserData?.PlaybackPositionTicks,
      })
      .then((info) => {
        if (cancelled) return;
        const source = api.getBestPlaybackSource(info);
        if (!source) {
          setPlaybackError(t("player.noPlayableSource"));
          return;
        }
        const sid = info.PlaySessionId ?? undefined;
        sessionRef.current = { sid, mediaSourceId: source.Id };
        const startTimeTicks = currentItem.UserData?.PlaybackPositionTicks;
        const { streamUrl, isHls } = api.getStreamUrlFromPlaybackInfo(
          currentItem.Id,
          info,
          { startTimeTicks }
        );
        setStreamConfig({
          streamUrl,
          isHls,
          startTimeTicks: startTimeTicks ?? 0,
        });
        api.reportPlaybackStart({
          ItemId: currentItem.Id,
          MediaSourceId: source.Id,
          PositionTicks: startTimeTicks,
          PlaySessionId: sid,
        });
      })
      .catch((err) => {
        if (!cancelled) {
          setPlaybackError(err instanceof Error ? err.message : t("player.couldNotLoadPlaybackInfo"));
        }
      });

    return () => {
      cancelled = true;
      setStreamConfig(null);
      if (progressIntervalRef.current) {
        clearInterval(progressIntervalRef.current);
        progressIntervalRef.current = undefined;
      }
      hlsAuthQueryRef.current = "";
      const player = playerRef.current;
      const pos = player && !player.isDisposed() ? (player.currentTime() ?? 0) : 0;
      const { sid } = sessionRef.current;
      if (sid && currentItem) {
        api.reportPlaybackStopped({
          ItemId: currentItem.Id,
          PositionTicks: Math.floor(pos * 10_000_000),
          PlaySessionId: sid,
        });
      }
      sessionRef.current = {};
    };
  }, [currentItem?.Id, localPlaybackPath, navigate]);

  // Create Video.js player and set source when streamConfig is ready
  useEffect(() => {
    if (!streamConfig || !containerRef.current) return;
    setPlaybackError(null);
    const { streamUrl, isHls, startTimeTicks } = streamConfig;
    const startSec = startTimeTicks / 10_000_000;

    if (isHls && streamUrl.includes(".m3u8")) {
      try {
        const u = new URL(streamUrl);
        hlsAuthQueryRef.current = u.searchParams.toString();
      } catch {
        hlsAuthQueryRef.current = "";
      }
    } else {
      hlsAuthQueryRef.current = "";
    }

    const videoEl = document.createElement("video-js");
    videoEl.classList.add("vjs-big-play-centered");
    videoEl.setAttribute("playsinline", "");
    videoEl.setAttribute("disablepictureinpicture", "");
    videoEl.setAttribute("disableremoteplayback", "");
    containerRef.current.innerHTML = "";
    containerRef.current.appendChild(videoEl);

    const player = videojs(videoEl, {
      controls: false,
      autoplay: false,
      preload: "auto",
      fluid: true,
      html5: { vhs: { overrideNative: true } },
    });
    playerRef.current = player;

    const sourceType = isHls ? "application/x-mpegURL" : "video/mp4";
    player.src({ src: streamUrl, type: sourceType });

    player.ready(() => {
      player.muted(muted);
      progressIntervalRef.current = setInterval(() => {
        const p = playerRef.current;
        if (p && !p.isDisposed() && sessionRef.current.sid && currentItem) {
          const t = p.currentTime() ?? 0;
          const d = p.duration() ?? 0;
          if (Number.isFinite(t)) setPosition(t);
          if (Number.isFinite(d)) setDuration(d);
          api.reportPlaybackProgress({
            ItemId: currentItem.Id,
            PositionTicks: Math.floor(t * 10_000_000),
            IsPaused: p.paused(),
            PlaySessionId: sessionRef.current.sid,
          });
        }
      }, 5000);
    });

    player.on("loadedmetadata", () => {
      player.currentTime(startSec);
      const p = player.play();
      if (p != null && typeof p.catch === "function") {
        p.catch((err: unknown) => {
          const msg =
            err instanceof Error ? err.message : err != null ? String(err) : "Playback failed to start.";
          setPlaybackError(msg);
        });
      }
    });

    player.on("timeupdate", () => {
      const t = player.currentTime() ?? 0;
      const d = player.duration() ?? 0;
      if (Number.isFinite(t)) setPosition(t);
      if (Number.isFinite(d)) setDuration(d);
    });

    player.on("play", () => {
      usePlayerStore?.setState({ isPlaying: true });
    });
    player.on("pause", () => {
      usePlayerStore?.setState({ isPlaying: false });
    });
    player.on("ended", () => playNext());

    player.on("error", () => {
      const err = player.error();
      let msg = err != null ? (err.message || getVideoErrorMessage(err)) : "Playback failed.";
      if (localPlaybackPath && err && typeof (err as { code?: number }).code === "number" && (err as { code: number }).code === MediaError.MEDIA_ERR_SRC_NOT_SUPPORTED) {
        msg = "The downloaded file format may not be supported in this app (e.g. MKV). Try playing from the server instead, or re-download in a supported format.";
      }
      setPlaybackError(msg);
    });

    const toDispose = player;
    return () => {
      if (progressIntervalRef.current) {
        clearInterval(progressIntervalRef.current);
        progressIntervalRef.current = undefined;
      }
      try {
        if (toDispose != null && !toDispose.isDisposed()) {
          toDispose.dispose();
        }
      } finally {
        playerRef.current = null;
      }
      hlsAuthQueryRef.current = "";
    };
  }, [streamConfig, currentItem?.Id, setPosition, setDuration, playNext, setPlaybackError]);

  const handlePlayPause = () => {
    const p = playerRef.current;
    if (p == null || p.isDisposed()) return;
    if (p.paused()) {
      const playPromise = p.play();
      if (playPromise != null && typeof playPromise.catch === "function") {
        playPromise.catch(() => {});
      }
      usePlayerStore.setState({ isPlaying: true });
    } else {
      p.pause();
      usePlayerStore.setState({ isPlaying: false });
    }
  };

  const HIDE_CONTROLS_AFTER_MS = 3500;
  const showControlsAndScheduleHide = () => {
    setShowControls(true);
    if (controlsTimeout.current) clearTimeout(controlsTimeout.current);
    controlsTimeout.current = setTimeout(() => setShowControls(false), HIDE_CONTROLS_AFTER_MS);
  };
  const scheduleHideControls = () => {
    if (controlsTimeout.current) clearTimeout(controlsTimeout.current);
    controlsTimeout.current = setTimeout(() => setShowControls(false), 400);
  };

  const formatTime = (s: number) => {
    if (s !== s || s < 0 || !Number.isFinite(s)) return "0:00";
    const m = Math.floor(s / 60);
    const sec = Math.floor(s % 60);
    return `${m}:${sec.toString().padStart(2, "0")}`;
  };

  function getVideoErrorMessage(e: MediaError | { code?: number; message?: string } | null): string {
    if (!e) return "Playback failed.";
    const code = "code" in e ? e.code : undefined;
    switch (code) {
      case MediaError.MEDIA_ERR_ABORTED:
        return "Playback was aborted.";
      case MediaError.MEDIA_ERR_NETWORK:
        return "A network error occurred. Check your connection.";
      case MediaError.MEDIA_ERR_DECODE:
        return "The video could not be decoded.";
      case MediaError.MEDIA_ERR_SRC_NOT_SUPPORTED:
        return "This format is not supported or the stream is unavailable.";
      default:
        return (e as { message?: string }).message || "Playback failed.";
    }
  }

  if (!currentItem) return null;

  const isMusic = currentItem.Type === "Audio";
  const musicArtUrl = isMusic ? getDisplayImageUrl(currentItem, { maxWidth: 600 }) : "";

  if (playbackError) {
    return (
      <div className="fixed inset-0 z-50 flex flex-col items-center justify-center gap-6 bg-black p-6">
        <p className="text-center text-lg font-medium text-white">
          Sorry, we had an issue playing this.
        </p>
        <p className="max-w-md text-center text-sm text-text-tertiary">{playbackError}</p>
        <button
          type="button"
          onClick={() => {
            stop();
            navigate(-1);
          }}
          className="rounded-xl bg-primary px-6 py-3 font-semibold text-background hover:opacity-90"
        >
          Go back
        </button>
      </div>
    );
  }

  if (isMusic) {
    return (
      <div className="fixed inset-0 z-50 flex flex-col bg-background">
        {/* Audio still plays via video.js; container hidden */}
        <div
          ref={containerRef}
          className="video-js-wrapper absolute left-0 top-0 h-1 w-1 overflow-hidden opacity-0"
          data-vjs-player
          aria-hidden
        />
        <div className="flex min-h-0 flex-1 flex-col md:flex-row">
          <div className="flex flex-1 flex-col p-4 md:justify-center md:p-8">
            <div className="flex items-center justify-between gap-4">
              <button
                type="button"
                onClick={() => navigate(-1)}
                className="rounded-lg p-2 text-text-primary hover:bg-white/10"
              >
                ← Back
              </button>
              <button
                type="button"
                onClick={() => { stop(); navigate("/"); }}
                className="rounded-lg p-2 text-text-primary hover:bg-white/10"
              >
                ✕
              </button>
            </div>
            <div className="flex flex-1 flex-col items-center justify-center gap-6 py-8">
              <div className="aspect-square w-full max-w-[280px] overflow-hidden rounded-2xl bg-surface shadow-xl">
                {musicArtUrl ? (
                  <img
                    src={musicArtUrl}
                    alt=""
                    className="h-full w-full object-cover"
                  />
                ) : (
                  <div className="flex h-full w-full items-center justify-center text-6xl font-bold text-text-tertiary">
                    {currentItem.Name.charAt(0)}
                  </div>
                )}
              </div>
              <div className="w-full max-w-md text-center">
                <h1 className="text-xl font-bold text-text-primary md:text-2xl">
                  {currentItem.Name}
                </h1>
                <p className="mt-1 truncate text-sm text-text-secondary">
                  {[currentItem.AlbumArtist, ...(currentItem.Artists ?? [])]
                    .filter(Boolean)
                    .join(" · ") || currentItem.Album}
                </p>
                {currentItem.Album && currentItem.AlbumArtist && (
                  <p className="mt-0.5 text-xs text-text-tertiary">{currentItem.Album}</p>
                )}
              </div>
              <div className="flex w-full max-w-md flex-col items-center space-y-3">
                <input
                  type="range"
                  min={0}
                  max={duration || 100}
                  value={position}
                  onChange={(e) => {
                    const v = Number(e.target.value);
                    const p = playerRef.current;
                    if (p && !p.isDisposed()) {
                      p.currentTime(v);
                      setPosition(v);
                    }
                  }}
                  className="h-2 w-full accent-primary"
                />
                <div className="flex w-full items-center justify-between text-xs text-text-tertiary">
                  <span>{formatTime(position)}</span>
                  <span>{formatTime(duration)}</span>
                </div>
                <div className="flex w-full justify-center">
                  <div className="inline-flex items-center gap-4">
                    <button
                      type="button"
                      onClick={() => playPrevious()}
                      className="rounded-full p-2 text-text-primary hover:bg-white/10"
                    >
                      <SkipBack className="h-8 w-8" />
                    </button>
                    <button
                      type="button"
                      onClick={handlePlayPause}
                      className="rounded-full bg-primary p-4 text-background hover:opacity-90"
                    >
                      {isPlaying ? (
                        <Pause className="h-8 w-8" fill="currentColor" />
                      ) : (
                        <Play className="h-8 w-8" fill="currentColor" />
                      )}
                    </button>
                    <button
                      type="button"
                      onClick={() => playNext()}
                      className="rounded-full p-2 text-text-primary hover:bg-white/10"
                    >
                      <SkipForward className="h-8 w-8" />
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setMuted((m) => !m);
                        const p = playerRef.current;
                        if (p && !p.isDisposed()) p.muted(!muted);
                      }}
                      className="rounded-full p-2 text-text-primary hover:bg-white/10"
                    >
                      {muted ? (
                        <VolumeX className="h-6 w-6" />
                      ) : (
                        <Volume2 className="h-6 w-6" />
                      )}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div className="flex w-full flex-col border-t border-white/10 md:w-80 md:border-l md:border-t-0">
            <div className="p-3 font-semibold text-text-primary">Queue</div>
            <div className="min-h-0 flex-1 overflow-y-auto p-2">
              {queue.length === 0 ? (
                <p className="py-4 text-center text-sm text-text-tertiary">No upcoming tracks</p>
              ) : (
                <ul className="space-y-1">
                  {queue.map((q) => (
                    <li key={q.Id}>
                      <button
                        type="button"
                        onClick={() => playFromQueue(q)}
                        className={`flex w-full cursor-pointer flex-col gap-0.5 rounded-lg px-3 py-2.5 text-left transition-colors hover:bg-white/10 ${
                          q.Id === currentItem.Id ? "bg-primary/20 text-primary" : "text-text-primary"
                        }`}
                      >
                        <span className="truncate text-sm font-medium">{q.Name}</span>
                        <span className="truncate text-xs text-text-tertiary">
                          {[q.AlbumArtist, ...(q.Artists ?? [])].filter(Boolean).join(" · ") || q.Album}
                        </span>
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      className="fixed inset-0 z-50 flex flex-col bg-black"
      onMouseMove={showControlsAndScheduleHide}
      onTouchStart={showControlsAndScheduleHide}
      onMouseLeave={scheduleHideControls}
    >
      <div
        className="flex min-h-0 flex-1 cursor-pointer"
        onClick={handlePlayPause}
        onKeyDown={(e) => e.key === " " && handlePlayPause()}
        role="button"
        tabIndex={0}
        aria-label={t("player.playOrPause")}
      >
        <div
          ref={containerRef}
          className="video-js-wrapper h-full w-full"
          data-vjs-player
        />
      </div>

      {showControls && (
        <>
          <div className="absolute left-0 right-0 top-0 flex items-center justify-between bg-gradient-to-b from-black/80 to-transparent p-4">
            <button
              type="button"
              onClick={() => navigate(-1)}
              className="rounded-lg p-2 text-white hover:bg-white/20 touch-manipulation"
            >
              ← Back
            </button>
            <h2 className="truncate text-lg font-medium text-white max-w-[60%]">
              {currentItem.Name}
            </h2>
            <button
              type="button"
              onClick={() => {
                stop();
                navigate("/");
              }}
              className="rounded-lg p-2 text-white hover:bg-white/20 touch-manipulation"
            >
              ✕
            </button>
          </div>

          <div className="absolute bottom-0 left-0 right-0 flex flex-col gap-4 bg-gradient-to-t from-black/80 to-transparent p-4">
            <input
              type="range"
              min={0}
              max={duration || 100}
              value={position}
              onChange={(e) => {
                const v = Number(e.target.value);
                const p = playerRef.current;
                if (p && !p.isDisposed()) {
                  p.currentTime(v);
                  setPosition(v);
                }
              }}
              className="h-2 w-full accent-primary touch-manipulation"
            />
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => playPrevious()}
                  className="rounded-full p-2 text-white hover:bg-white/20 touch-manipulation"
                >
                  <SkipBack className="h-6 w-6" />
                </button>
                <button
                  type="button"
                  onClick={handlePlayPause}
                  className="rounded-full bg-primary p-3 text-background hover:opacity-90 touch-manipulation"
                >
                  {isPlaying ? (
                    <Pause className="h-6 w-6" fill="currentColor" />
                  ) : (
                    <Play className="h-6 w-6" fill="currentColor" />
                  )}
                </button>
                <button
                  type="button"
                  onClick={() => playNext()}
                  className="rounded-full p-2 text-white hover:bg-white/20 touch-manipulation"
                >
                  <SkipForward className="h-6 w-6" />
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setMuted((m) => !m);
                    const p = playerRef.current;
                    if (p && !p.isDisposed()) p.muted(!muted);
                  }}
                  className="rounded-full p-2 text-white hover:bg-white/20 touch-manipulation"
                >
                  {muted ? (
                    <VolumeX className="h-5 w-5" />
                  ) : (
                    <Volume2 className="h-5 w-5" />
                  )}
                </button>
              </div>
              <span className="text-sm text-white/80">
                {formatTime(position)} / {formatTime(duration)}
              </span>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
