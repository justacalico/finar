import { Link } from "react-router-dom";
import {
  Film,
  Music,
  Video,
  ListMusic,
  Tv,
  FolderOpen,
} from "lucide-react";
import { useLibraryStore } from "../stores/library";

function getLibraryIcon(collectionType?: string) {
  switch (collectionType?.toLowerCase()) {
    case "movies":
      return Film;
    case "tvshows":
      return Tv;
    case "music":
      return Music;
    case "musicvideos":
      return Video;
    case "playlists":
      return ListMusic;
    default:
      return FolderOpen;
  }
}

export function LibraryList() {
  const { libraries } = useLibraryStore();

  return (
    <div className="mx-auto max-w-4xl px-4 py-6">
      <h1 className="mb-4 text-xl font-bold text-text-primary">Library</h1>
      {libraries.length === 0 ? (
        <p className="text-text-tertiary">No libraries available.</p>
      ) : (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
          {libraries.map((lib) => {
            const Icon = getLibraryIcon(lib.CollectionType);
            const count = lib.ChildCount ?? 0;
            return (
              <Link
                key={lib.Id}
                to={`/library/${lib.Id}`}
                className="flex flex-col gap-3 rounded-2xl bg-surface p-4 transition-colors hover:bg-surface-elevated active:scale-[0.98]"
              >
                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-white/10 text-primary">
                  <Icon className="h-6 w-6" />
                </div>
                <div className="min-w-0">
                  <p className="truncate font-semibold text-text-primary">
                    {lib.Name}
                  </p>
                  <p className="text-xs text-text-tertiary">{count} items</p>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
