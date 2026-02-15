import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Play, Plus, Star, ArrowLeft } from "lucide-react";
import { api } from "../api/jellyfin";
import { usePlayerStore } from "../stores/player";
import { getBackdropUrl, getDisplayImageUrl } from "../utils/image";
import { MediaCard } from "../components/MediaCard";
import { Button } from "../components/Button";
import type { MediaItem } from "../types/jellyfin";

export function ItemDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [item, setItem] = useState<MediaItem | null>(null);
  const [seasons, setSeasons] = useState<MediaItem[]>([]);
  const [episodes, setEpisodes] = useState<MediaItem[]>([]);
  const [similar, setSimilar] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedSeasonId, setSelectedSeasonId] = useState<string | null>(null);
  const { play } = usePlayerStore();

  useEffect(() => {
    if (!id) return;
    let cancelled = false;
    setLoading(true);
    api
      .getItem(id)
      .then((data) => {
        if (cancelled) return;
        setItem(data);
        if (data.Type === "Series") {
          return api.getSeasons(data.Id).then((s) => {
            if (!cancelled) {
              setSeasons(s);
              const first = s[0];
              if (first) {
                setSelectedSeasonId(first.Id);
                return api.getEpisodes(data.Id, first.Id).then((e) => {
                  if (!cancelled) setEpisodes(e);
                });
              }
            }
          });
        }
        return api.getSimilarItems(data.Id, 12).then((s) => {
          if (!cancelled) setSimilar(s);
        });
      })
      .catch((e) => {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
  }, [id]);

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

  const backdrop = getBackdropUrl(item, 0, { maxWidth: 1280 });
  const isSeries = item.Type === "Series";
  const isPlayable = ["Movie", "Episode", "Audio", "MusicVideo"].includes(item.Type);

  const handlePlay = () => {
    if (isSeries) {
      if (episodes.length > 0) {
        play(episodes[0]);
        navigate("/player");
      }
      return;
    }
    play(item);
    if (isPlayable && item.Type !== "Audio") navigate("/player");
  };

  return (
    <div className="pb-20">
      <div className="relative h-[45vw] max-h-[500px] min-h-[240px] w-full overflow-hidden">
        <button
          type="button"
          onClick={() => navigate(-1)}
          className="absolute left-5 top-5 z-20 hidden items-center gap-2 rounded-lg bg-black/60 px-3 py-2.5 text-sm text-white shadow-lg hover:bg-black/75 md:inline-flex"
          aria-label="Go back"
        >
          <ArrowLeft className="h-4 w-4 shrink-0" />
          Back
        </button>
        <img
          src={backdrop}
          alt=""
          className="absolute inset-0 h-full w-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-background via-background/70 to-transparent" />
        <div className="absolute bottom-0 left-0 right-0 p-6 md:p-10">
          <div className="min-w-0 max-w-3xl">
              <span className="rounded bg-primary/90 px-2 py-0.5 text-xs font-bold uppercase text-background">
                {item.Type}
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
                {isPlayable && (
                  <Button
                    leftIcon={<Play className="h-5 w-5" fill="currentColor" />}
                    onClick={handlePlay}
                  >
                    Play
                  </Button>
                )}
                <Button variant="outline" leftIcon={<Plus className="h-4 w-4" />}>
                  Add to list
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-6xl px-4 py-6 md:px-8">
        {item.Overview && (
          <section className="mb-8">
            <h2 className="mb-2 text-lg font-semibold text-text-primary">
              Overview
            </h2>
            <p className="text-text-secondary">{item.Overview}</p>
          </section>
        )}

        {isSeries && seasons.length > 0 && (
          <section className="mb-8">
            <h2 className="mb-4 text-lg font-semibold text-text-primary">
              Seasons
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
            <h2 className="mb-4 text-lg font-semibold text-text-primary">
              Episodes
            </h2>
            <div className="space-y-2">
              {episodes.map((ep) => (
                <button
                  key={ep.Id}
                  type="button"
                  onClick={() => {
                    play(ep);
                    navigate("/player");
                  }}
                  className="flex w-full items-center gap-4 rounded-xl bg-surface p-3 text-left transition-colors hover:bg-white/10"
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
                  <Play className="h-5 w-5 shrink-0 text-primary" fill="currentColor" />
                </button>
              ))}
            </div>
          </section>
        )}

        {similar.length > 0 && (
          <section>
            <h2 className="mb-4 text-lg font-semibold text-text-primary">
              More Like This
            </h2>
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4">
              {similar.map((s, i) => (
                <MediaCard
                  key={s.Id}
                  item={s}
                  index={i}
                  onClick={() => navigate(`/item/${s.Id}`)}
                />
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
}
