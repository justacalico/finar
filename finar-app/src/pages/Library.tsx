import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { api } from "../api/jellyfin";
import { MediaCard } from "../components/MediaCard";
import type { MediaItem, Library as LibraryType } from "../types/jellyfin";

export function Library() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [library, setLibrary] = useState<LibraryType | null>(null);
  const [items, setItems] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    let cancelled = false;
    setLoading(true);
    Promise.all([
      api.getLibraries().then((libs) => libs.find((l) => l.Id === id)),
      api.getItems({
        parentId: id,
        limit: 100,
        recursive: true,
        sortBy: "SortName",
        sortOrder: "Ascending",
        fields: ["Overview"],
        excludeItemTypes: [
          "Season",
          "Episode",
          "Audio",
          "Folder",
          "CollectionFolder",
          "UserView",
        ],
      }),
    ])
      .then(([lib, result]) => {
        if (cancelled) return;
        setLibrary(lib ?? null);
        setItems(result?.Items ?? []);
      })
      .catch((e) => {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [id]);

  if (loading) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  if (error || !library) {
    return (
      <div className="flex min-h-[40vh] flex-col items-center justify-center gap-4 px-4">
        <p className="text-text-secondary">{error ?? "Library not found"}</p>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-6 md:px-8">
      <h1 className="mb-6 text-2xl font-bold text-text-primary">{library.Name}</h1>
      {items.length === 0 ? (
        <p className="text-text-tertiary">No items in this library.</p>
      ) : (
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
      )}
    </div>
  );
}
