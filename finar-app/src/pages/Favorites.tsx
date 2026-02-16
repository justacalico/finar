import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Heart } from "lucide-react";
import { api } from "../api/jellyfin";
import { MediaCard } from "../components/MediaCard";
import { useTranslation } from "../translations";
import type { MediaItem } from "../types/jellyfin";

export function Favorites() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [items, setItems] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    api
      .getFavorites(50)
      .then((data) => {
        if (!cancelled) setItems(data);
      })
      .catch((e) => {
        if (!cancelled) setError(e instanceof Error ? e.message : t("library.failedToLoad"));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [t]);

  if (loading) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex min-h-[40vh] flex-col items-center justify-center gap-4 px-4">
        <p className="text-text-secondary">{error}</p>
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="flex min-h-[40vh] flex-col items-center justify-center gap-4 px-4">
        <Heart className="h-20 w-20 text-text-tertiary/50" />
        <p className="text-lg font-medium text-text-secondary">{t("favorites.noFavoritesYet")}</p>
        <p className="text-sm text-text-tertiary">{t("favorites.markFavorites")}</p>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-6 md:px-8">
      <div className="mb-6 flex items-center gap-3">
        <Heart className="h-8 w-8 text-primary" />
        <h1 className="text-2xl font-bold text-text-primary">{t("favorites.title")}</h1>
      </div>
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
        {items.map((item, i) => (
          <MediaCard
            key={item.Id}
            item={item}
            index={i}
            onClick={() => navigate(`/item/${item.Id}`)}
          />
        ))}
      </div>
    </div>
  );
}
