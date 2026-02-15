import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { Play, ChevronRight } from "lucide-react";
import { useLibraryStore } from "../stores/library";
import { usePlayerStore } from "../stores/player";
import { MediaCard } from "../components/MediaCard";
import { getBackdropUrl } from "../utils/image";
import type { MediaItem } from "../types/jellyfin";

function MediaRow({
  title,
  items,
  showProgress = false,
  onSeeAll,
}: {
  title: string;
  items: MediaItem[];
  showProgress?: boolean;
  onSeeAll?: () => void;
}) {
  const navigate = useNavigate();

  if (items.length === 0) return null;

  return (
    <section className="mb-10">
      <div className="mb-4 flex items-center justify-between px-4 md:px-8">
        <h2 className="text-xl font-semibold text-text-primary">{title}</h2>
        {onSeeAll && (
          <button
            type="button"
            onClick={onSeeAll}
            className="flex items-center gap-1 text-sm font-medium text-primary hover:underline"
          >
            See All
            <ChevronRight className="h-4 w-4" />
          </button>
        )}
      </div>
      <div className="flex gap-4 overflow-x-auto px-4 pb-2 md:px-8">
        {items.map((item, i) => (
          <div key={item.Id} className="w-40 shrink-0 md:w-44">
            <MediaCard
              item={item}
              progress={
                showProgress && item.UserData?.PlaybackPositionTicks != null && item.RunTimeTicks
                  ? item.UserData.PlaybackPositionTicks / item.RunTimeTicks
                  : undefined
              }
              showProgress={showProgress}
              index={i}
              onClick={() => navigate(`/item/${item.Id}`)}
            />
          </div>
        ))}
      </div>
    </section>
  );
}

export function Home() {
  const { homeData, loadHomeData, isLoading, error } = useLibraryStore();
  const navigate = useNavigate();

  useEffect(() => {
    loadHomeData();
  }, [loadHomeData]);

  if (isLoading && !homeData) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  if (error && !homeData) {
    return (
      <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 px-4">
        <p className="text-center text-text-secondary">{error}</p>
        <button
          type="button"
          onClick={() => loadHomeData()}
          className="rounded-xl bg-primary px-6 py-2 font-medium text-background"
        >
          Retry
        </button>
      </div>
    );
  }

  const data = homeData!;
  const heroItem = data.recentlyAdded[0] ?? data.continueWatching[0];

  return (
    <div className="pb-20">
      {heroItem && (
        <motion.section
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="relative h-[50vw] max-h-[500px] min-h-[280px] w-full overflow-hidden"
        >
          <img
            src={getBackdropUrl(heroItem, 0, { maxWidth: 1920 })}
            alt=""
            className="absolute inset-0 h-full w-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-background via-background/60 to-transparent" />
          <div className="absolute bottom-0 left-0 right-0 p-6 md:p-10">
            <div className="max-w-2xl">
              <span className="rounded bg-primary/90 px-2 py-0.5 text-xs font-bold uppercase text-background">
                {heroItem.Type}
              </span>
              <h1 className="mt-2 text-3xl font-bold text-white drop-shadow md:text-4xl">
                {heroItem.Type === "Episode"
                  ? `${heroItem.SeriesName} - ${heroItem.Name}`
                  : heroItem.Name}
              </h1>
              {heroItem.Overview && (
                <p className="mt-2 line-clamp-2 text-sm text-white/90 md:line-clamp-3 md:text-base">
                  {heroItem.Overview}
                </p>
              )}
              <div className="mt-4 flex gap-3">
                <button
                  type="button"
                  onClick={() => {
                    usePlayerStore.getState().play(heroItem);
                    if (["Movie", "Episode"].includes(heroItem.Type)) {
                      navigate("/player");
                    }
                  }}
                  className="flex items-center gap-2 rounded-xl bg-primary px-5 py-2.5 font-semibold text-background hover:opacity-90"
                >
                  <Play className="h-5 w-5" fill="currentColor" />
                  Play
                </button>
                <button
                  type="button"
                  onClick={() => navigate(`/item/${heroItem.Id}`)}
                  className="rounded-xl border border-white/30 bg-white/10 px-5 py-2.5 font-semibold text-white backdrop-blur hover:bg-white/20"
                >
                  More Info
                </button>
              </div>
            </div>
          </div>
        </motion.section>
      )}

      <div className="mt-6">
        <MediaRow
          title="Continue Watching"
          items={data.continueWatching}
          showProgress
        />
        <MediaRow title="Next Up" items={data.nextUp} />
        <MediaRow title="Recently Added" items={data.recentlyAdded.slice(1)} />
        <MediaRow title="New Releases" items={data.recentlyReleased} />
        <MediaRow title="Recommended For You" items={data.recommended} />
        <MediaRow title="Top Rated" items={data.topRated} />
        <MediaRow title="My Favorites" items={data.favorites} />
      </div>
    </div>
  );
}
