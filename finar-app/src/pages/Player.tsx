import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import videojs from "video.js";
import "video.js/dist/video-js.css";
import { Play, Pause, Volume2, VolumeX, SkipBack, SkipForward } from "lucide-react";
import { usePlayerStore } from "../stores/player";
import { api } from "../api/jellyfin";

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
      cb = options as (err: unknown, a?: unknown, b?: unknown) => void;
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
    if (typeof (original as Record<string, unknown>)[key] === "function" || (original as Record<string, unknown>)[key] != null) {
      (wrapped as Record<string, unknown>)[key] = (original as Record<string, unknown>)[key];
    }
  });
  (videojs as unknown as { xhr: typeof videojs.xhr }).xhr = wrapped as typeof videojs.xhr;
}

export function Player() {
  const navigate = useNavigate();
  const containerRef = useRef<HTMLDivElement>(null);
  const playerRef = useRef<ReturnType<typeof videojs> | null>(null);
  const sessionRef = useRef<{ sid?: string; mediaSourceId?: string }>({});
  const {
    currentItem,
    isPlaying,
    position,
    duration,
    setPosition,
    setDuration,
    playNext,
    playPrevious,
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

  // Load playback info and derive stream URL (direct or HLS)
  useEffect(() => {
    if (!currentItem) {
      navigate("/", { replace: true });
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
          setPlaybackError("No playable media source found");
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
          setPlaybackError(err instanceof Error ? err.message : "Could not load playback info.");
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
      const pos = player && !player.isDisposed() ? player.currentTime() : 0;
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
  }, [currentItem?.Id, navigate]);

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
        if (p && !p.isDisposed() && sessionRef.current.sid) {
          const t = p.currentTime();
          const d = p.duration();
          if (Number.isFinite(t)) setPosition(t);
          if (Number.isFinite(d)) setDuration(d);
          api.reportPlaybackProgress({
            ItemId: currentItem!.Id,
            PositionTicks: Math.floor(t * 10_000_000),
            IsPaused: p.paused(),
            PlaySessionId: sessionRef.current.sid,
          });
        }
      }, 5000);
    });

    player.on("loadedmetadata", () => {
      player.currentTime(startSec);
      player.play().catch((err: unknown) => {
        setPlaybackError(err instanceof Error ? err.message : "Playback failed to start.");
      });
    });

    player.on("timeupdate", () => {
      const t = player.currentTime();
      const d = player.duration();
      if (Number.isFinite(t)) setPosition(t);
      if (Number.isFinite(d)) setDuration(d);
    });

    player.on("play", () => usePlayerStore.setState({ isPlaying: true }));
    player.on("pause", () => usePlayerStore.setState({ isPlaying: false }));
    player.on("ended", () => playNext());

    player.on("error", () => {
      const err = player.error();
      const msg = err ? (err.message || getVideoErrorMessage(err)) : "Playback failed.";
      setPlaybackError(msg);
    });

    return () => {
      if (progressIntervalRef.current) {
        clearInterval(progressIntervalRef.current);
        progressIntervalRef.current = undefined;
      }
      if (player && !player.isDisposed()) {
        player.dispose();
        playerRef.current = null;
      }
      hlsAuthQueryRef.current = "";
    };
  }, [streamConfig, currentItem?.Id, setPosition, setDuration, playNext, setPlaybackError]);

  const handlePlayPause = () => {
    const p = playerRef.current;
    if (!p || p.isDisposed()) return;
    if (p.paused()) {
      p.play().catch(() => {});
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
        aria-label="Play or pause"
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
