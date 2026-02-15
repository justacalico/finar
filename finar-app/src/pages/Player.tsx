import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Play, Pause, Volume2, VolumeX, SkipBack, SkipForward } from "lucide-react";
import { usePlayerStore } from "../stores/player";
import { api } from "../api/jellyfin";

export function Player() {
  const navigate = useNavigate();
  const videoRef = useRef<HTMLVideoElement>(null);
  const {
    currentItem,
    isPlaying,
    position,
    duration,
    setPosition,
    setDuration,
    playOrPause,
    playNext,
    playPrevious,
    stop,
  } = usePlayerStore();
  const [showControls, setShowControls] = useState(true);
  const [muted, setMuted] = useState(false);
  const [, setPlaySessionId] = useState<string | null>(null);
  const controlsTimeout = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);

  useEffect(() => {
    if (!currentItem) {
      navigate("/", { replace: true });
      return;
    }
    let progressInterval: ReturnType<typeof setInterval>;
    let sid: string | undefined;
    api
      .getPlaybackInfo(currentItem.Id, {
        startTimeTicks: currentItem.UserData?.PlaybackPositionTicks,
      })
      .then((info) => {
        const source = info.MediaSources?.[0];
        sid = info.PlaySessionId ?? undefined;
        setPlaySessionId(sid ?? null);
        const streamUrl = source?.SupportsDirectPlay
          ? api.getStreamUrl(currentItem.Id, {
              mediaSourceId: source.Id,
              startTimeTicks: currentItem.UserData?.PlaybackPositionTicks,
            })
          : api.getHlsStreamUrl(currentItem.Id, {
              mediaSourceId: source?.Id,
              playSessionId: sid,
              startTimeTicks: currentItem.UserData?.PlaybackPositionTicks,
            });
        if (videoRef.current) {
          videoRef.current.src = streamUrl;
          videoRef.current.currentTime =
            (currentItem.UserData?.PlaybackPositionTicks ?? 0) / 10_000_000;
          videoRef.current.play().catch(() => {});
        }
        api.reportPlaybackStart({
          ItemId: currentItem.Id,
          MediaSourceId: source?.Id,
          PositionTicks: currentItem.UserData?.PlaybackPositionTicks,
          PlaySessionId: sid,
        });
        progressInterval = setInterval(() => {
          if (videoRef.current && sid) {
            const pos = Math.floor(videoRef.current.currentTime * 10_000_000);
            setPosition(videoRef.current.currentTime);
            setDuration(videoRef.current.duration);
            api.reportPlaybackProgress({
              ItemId: currentItem.Id,
              PositionTicks: pos,
              IsPaused: videoRef.current.paused,
              PlaySessionId: sid,
            });
          }
        }, 5000);
      })
      .catch(() => {});
    return () => {
      clearInterval(progressInterval!);
      if (sid && videoRef.current) {
        api.reportPlaybackStopped({
          ItemId: currentItem.Id,
          PositionTicks: Math.floor(videoRef.current.currentTime * 10_000_000),
          PlaySessionId: sid,
        });
      }
    };
  }, [currentItem?.Id]);

  const toggleControls = () => {
    setShowControls((c) => !c);
    if (controlsTimeout.current) clearTimeout(controlsTimeout.current);
    if (showControls) return;
    controlsTimeout.current = setTimeout(() => setShowControls(false), 4000);
  };

  const formatTime = (s: number) => {
    const m = Math.floor(s / 60);
    const sec = Math.floor(s % 60);
    return `${m}:${sec.toString().padStart(2, "0")}`;
  };

  if (!currentItem) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex flex-col bg-black"
      onMouseMove={toggleControls}
      onMouseLeave={() => setShowControls(false)}
    >
      <video
        ref={videoRef}
        className="h-full w-full object-contain"
        playsInline
        muted={muted}
        onTimeUpdate={() => {
          if (videoRef.current) {
            setPosition(videoRef.current.currentTime);
            setDuration(videoRef.current.duration);
          }
        }}
        onEnded={() => playNext()}
        onPlay={() => usePlayerStore.setState({ isPlaying: true })}
        onPause={() => usePlayerStore.setState({ isPlaying: false })}
        onClick={playOrPause}
      />

      {showControls && (
        <div className="absolute inset-0 flex flex-col justify-between bg-gradient-to-t from-black/80 via-transparent to-black/50 p-4">
          <div className="flex items-center justify-between">
            <button
              type="button"
              onClick={() => navigate(-1)}
              className="rounded-lg p-2 text-white hover:bg-white/20"
            >
              ← Back
            </button>
            <h2 className="truncate text-lg font-medium text-white">
              {currentItem.Name}
            </h2>
            <button
              type="button"
              onClick={() => {
                stop();
                navigate("/");
              }}
              className="rounded-lg p-2 text-white hover:bg-white/20"
            >
              ✕
            </button>
          </div>

          <div className="flex flex-col gap-4">
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
              className="h-2 w-full accent-primary"
            />
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => playPrevious()}
                  className="rounded-full p-2 text-white hover:bg-white/20"
                >
                  <SkipBack className="h-6 w-6" />
                </button>
                <button
                  type="button"
                  onClick={playOrPause}
                  className="rounded-full bg-primary p-3 text-background hover:opacity-90"
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
                  className="rounded-full p-2 text-white hover:bg-white/20"
                >
                  <SkipForward className="h-6 w-6" />
                </button>
                <button
                  type="button"
                  onClick={() => setMuted((m) => !m)}
                  className="rounded-full p-2 text-white hover:bg-white/20"
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
