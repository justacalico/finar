import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import Hls from "hls.js";
import { Play, Pause, Volume2, VolumeX, SkipBack, SkipForward } from "lucide-react";
import { usePlayerStore } from "../stores/player";
import { api } from "../api/jellyfin";

/** Native HLS support (Safari, iOS). Use native src for .m3u8 on these. */
function canPlayHlsNatively(): boolean {
  if (typeof document === "undefined" || !document.createElement("video").canPlayType) return false;
  const v = document.createElement("video");
  return v.canPlayType("application/vnd.apple.mpegurl") !== "";
}

export function Player() {
  const navigate = useNavigate();
  const videoRef = useRef<HTMLVideoElement>(null);
  const hlsRef = useRef<Hls | null>(null);
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
        const source = info.MediaSources?.[0];
        const sid = info.PlaySessionId ?? undefined;
        sessionRef.current = { sid, mediaSourceId: source?.Id };
        const isHls = !source?.SupportsDirectPlay;
        const streamUrl = isHls
          ? api.getHlsStreamUrl(currentItem.Id, {
              mediaSourceId: source?.Id,
              playSessionId: sid,
              startTimeTicks: currentItem.UserData?.PlaybackPositionTicks,
            })
          : api.getStreamUrl(currentItem.Id, {
              mediaSourceId: source?.Id,
              startTimeTicks: currentItem.UserData?.PlaybackPositionTicks,
            });
        setStreamConfig({
          streamUrl,
          isHls,
          startTimeTicks: currentItem.UserData?.PlaybackPositionTicks ?? 0,
        });
        api.reportPlaybackStart({
          ItemId: currentItem.Id,
          MediaSourceId: source?.Id,
          PositionTicks: currentItem.UserData?.PlaybackPositionTicks,
          PlaySessionId: sid,
        });
        progressIntervalRef.current = setInterval(() => {
          if (videoRef.current && sessionRef.current.sid) {
            setPosition(videoRef.current.currentTime);
            setDuration(videoRef.current.duration);
            api.reportPlaybackProgress({
              ItemId: currentItem.Id,
              PositionTicks: Math.floor(videoRef.current.currentTime * 10_000_000),
              IsPaused: videoRef.current.paused,
              PlaySessionId: sessionRef.current.sid,
            });
          }
        }, 5000);
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
      destroyHls();
      const { sid } = sessionRef.current;
      if (sid && videoRef.current) {
        api.reportPlaybackStopped({
          ItemId: currentItem.Id,
          PositionTicks: Math.floor(videoRef.current.currentTime * 10_000_000),
          PlaySessionId: sid,
        });
      }
      sessionRef.current = {};
    };
  }, [currentItem?.Id]);

  // Attach stream to video element (runs when streamConfig and ref are ready)
  useEffect(() => {
    if (!streamConfig || !videoRef.current) return;
    setPlaybackError(null);
    const { streamUrl, isHls, startTimeTicks } = streamConfig;
    const startSec = startTimeTicks / 10_000_000;
    setStreamUrlOnVideo(videoRef.current, streamUrl, isHls, () => {
      if (!videoRef.current) return;
      videoRef.current.currentTime = startSec;
      videoRef.current.play().catch((err) => {
        setPlaybackError(err instanceof Error ? err.message : "Playback failed to start.");
      });
    });
    return () => destroyHls();
  }, [streamConfig]);

  function destroyHls() {
    if (hlsRef.current) {
      hlsRef.current.destroy();
      hlsRef.current = null;
    }
  }

  function setStreamUrlOnVideo(
    video: HTMLVideoElement | null,
    streamUrl: string,
    isHls: boolean,
    onReady: () => void
  ) {
    if (!video) return;
    destroyHls();
    video.removeAttribute("src");
    if (isHls && streamUrl.includes(".m3u8")) {
      if (Hls.isSupported() && !canPlayHlsNatively()) {
        const manifestUrl = new URL(streamUrl);
        const authParams = manifestUrl.searchParams.toString();
        if (!authParams) {
          video.src = streamUrl;
          video.addEventListener("loadedmetadata", () => onReady(), { once: true });
          return;
        }
        const manifestBase = streamUrl.split("?")[0];
        const hls = new Hls({
          enableWorker: true,
          fetchSetup: (context, initParams) => {
            const resolved = new URL(context.url, manifestBase);
            const sep = resolved.search ? "&" : "?";
            const urlWithAuth = resolved.href + sep + authParams;
            return new Request(urlWithAuth, initParams);
          },
        });
        hlsRef.current = hls;
        hls.loadSource(streamUrl);
        hls.attachMedia(video);
        hls.on(Hls.Events.MANIFEST_PARSED, () => onReady());
        hls.on(Hls.Events.ERROR, (_, data) => {
          if (data.fatal) {
            destroyHls();
            const msg = data.details ?? data.type ?? "HLS error";
            setPlaybackError(`Stream error: ${msg}`);
          }
        });
      } else {
        video.src = streamUrl;
        video.addEventListener("loadedmetadata", () => onReady(), { once: true });
      }
    } else {
      video.src = streamUrl;
      video.addEventListener("loadedmetadata", () => onReady(), { once: true });
    }
  }

  const handlePlayPause = () => {
    const v = videoRef.current;
    if (!v) return;
    if (v.paused) {
      v.play().catch(() => {});
      usePlayerStore.setState({ isPlaying: true });
    } else {
      v.pause();
      usePlayerStore.setState({ isPlaying: false });
    }
  };

  const toggleControls = () => {
    setShowControls((c) => !c);
    if (controlsTimeout.current) clearTimeout(controlsTimeout.current);
    if (showControls) return;
    controlsTimeout.current = setTimeout(() => setShowControls(false), 4000);
  };

  const formatTime = (s: number) => {
    if (s !== s || s < 0 || !Number.isFinite(s)) return "0:00";
    const m = Math.floor(s / 60);
    const sec = Math.floor(s % 60);
    return `${m}:${sec.toString().padStart(2, "0")}`;
  };

  function getVideoErrorMessage(e: MediaError | null): string {
    if (!e) return "Playback failed.";
    switch (e.code) {
      case MediaError.MEDIA_ERR_ABORTED:
        return "Playback was aborted.";
      case MediaError.MEDIA_ERR_NETWORK:
        return "A network error occurred. Check your connection.";
      case MediaError.MEDIA_ERR_DECODE:
        return "The video could not be decoded.";
      case MediaError.MEDIA_ERR_SRC_NOT_SUPPORTED:
        return "This format is not supported or the stream is unavailable.";
      default:
        return e.message || "Playback failed.";
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
      onMouseMove={toggleControls}
      onMouseLeave={() => setShowControls(false)}
      onTouchStart={toggleControls}
    >
      <video
        ref={videoRef}
        className="h-full w-full object-contain"
        playsInline
        muted={muted}
        disablePictureInPicture
        disableRemotePlayback
        onError={() => {
          const v = videoRef.current;
          setPlaybackError(getVideoErrorMessage(v?.error ?? null));
        }}
        onTimeUpdate={() => {
          if (videoRef.current) {
            setPosition(videoRef.current.currentTime);
            setDuration(videoRef.current.duration);
          }
        }}
        onEnded={() => playNext()}
        onPlay={() => usePlayerStore.setState({ isPlaying: true })}
        onPause={() => usePlayerStore.setState({ isPlaying: false })}
        onClick={handlePlayPause}
      />

      {showControls && (
        <div className="absolute inset-0 flex flex-col justify-between bg-gradient-to-t from-black/80 via-transparent to-black/50 p-4 pointer-events-none">
          <div className="flex items-center justify-between pointer-events-auto">
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

          <div className="flex flex-col gap-4 pointer-events-auto">
            <input
              type="range"
              min={0}
              max={duration || 100}
              value={position}
              onChange={(e) => {
                const v = Number(e.target.value);
                if (videoRef.current) {
                  videoRef.current.currentTime = v;
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
                  onClick={() => setMuted((m) => !m)}
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
        </div>
      )}
    </div>
  );
}
