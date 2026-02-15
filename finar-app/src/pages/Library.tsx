import { useEffect, useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import { ArrowLeft, Play } from "lucide-react";
import { api } from "../api/jellyfin";
import { AlbumCard } from "../components/AlbumCard";
import { MediaCard } from "../components/MediaCard";
import { usePlayerStore } from "../stores/player";
import type { MediaItem, Library as LibraryType } from "../types/jellyfin";

const isMusicLibrary = (lib: LibraryType | null) =>
  lib?.CollectionType?.toLowerCase() === "music";

type MusicTab = "albums" | "artists" | "tracks";

function formatTrackDuration(ticks?: number): string {
  if (ticks == null || !Number.isFinite(ticks)) return "";
  const sec = Math.floor(ticks / 10_000_000);
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${m}:${s.toString().padStart(2, "0")}`;
}

export function Library() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [library, setLibrary] = useState<LibraryType | null>(null);
  const [items, setItems] = useState<MediaItem[]>([]);
  const [albums, setAlbums] = useState<MediaItem[]>([]);
  const [artists, setArtists] = useState<MediaItem[]>([]);
  const [tracks, setTracks] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [musicTab, setMusicTab] = useState<MusicTab>("albums");

  useEffect(() => {
    if (!id) return;
    let cancelled = false;
    setLoading(true);
    setAlbums([]);
    setArtists([]);
    setTracks([]);
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
      .then(async ([lib, result]) => {
        if (cancelled) return;
        setLibrary(lib ?? null);
        let list = result?.Items ?? [];
        if (isMusicLibrary(lib ?? null)) {
          const [albumsRes, artistsRes, tracksRes, directChildrenRes] = await Promise.all([
            api.getItems({
              parentId: id!,
              includeItemTypes: ["MusicAlbum"],
              recursive: true,
              limit: 200,
              sortBy: "SortName",
              sortOrder: "Ascending",
              fields: ["Overview"],
            }),
            api.getItems({
              parentId: id!,
              includeItemTypes: ["MusicArtist", "Folder"],
              recursive: true,
              limit: 200,
              sortBy: "SortName",
              sortOrder: "Ascending",
              fields: ["Overview"],
            }),
            api.getItems({
              parentId: id!,
              includeItemTypes: ["Audio"],
              recursive: true,
              limit: 500,
              sortBy: "SortName",
              sortOrder: "Ascending",
              fields: ["Overview", "MediaSources"],
            }),
            api.getItems({
              parentId: id!,
              recursive: false,
              limit: 100,
              sortBy: "SortName",
              sortOrder: "Ascending",
              fields: ["Overview"],
              excludeItemTypes: ["Playlist", "UserView", "CollectionFolder"],
            }),
          ]);
          if (!cancelled) {
            setAlbums(albumsRes?.Items ?? []);
            const artistItems = artistsRes?.Items ?? [];
            const directChildren = directChildrenRes?.Items ?? [];
            const hasRealArtists = artistItems.length > 0;
            const artistFolders =
              !hasRealArtists && directChildren.length > 0
                ? directChildren.filter(
                    (i) => i.Type === "Folder" || i.Type === "MusicArtist"
                  )
                : [];
            setArtists(hasRealArtists ? artistItems : artistFolders);
            setTracks(tracksRes?.Items ?? []);
          }
          list = [];
        } else if (lib?.CollectionType?.toLowerCase() === "playlists") {
          const allPlaylists = await api.getItems({
            includeItemTypes: ["Playlist"],
            recursive: true,
            limit: 100,
            sortBy: "SortName",
            sortOrder: "Ascending",
            fields: ["Overview"],
          });
          const playlists = allPlaylists?.Items ?? [];
          if (playlists.length > 0) {
            const byId = new Map(list.map((i) => [i.Id, i]));
            for (const p of playlists) {
              if (!byId.has(p.Id)) byId.set(p.Id, p);
            }
            list = [...byId.values()].sort((a, b) =>
              (a.Name ?? "").localeCompare(b.Name ?? "")
            );
          }
        }
        setItems(list);
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

  const play = usePlayerStore((s) => s.play);
  const musicLibrary = isMusicLibrary(library);

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
      <Link
        to="/library"
        className="mb-4 hidden items-center gap-2 text-sm text-text-secondary hover:text-text-primary md:inline-flex"
      >
        <ArrowLeft className="h-4 w-4" />
        Library
      </Link>
      <h1 className="mb-6 text-2xl font-bold text-text-primary">{library.Name}</h1>

      {musicLibrary ? (
        <div className="flex flex-col gap-6">
          <div
            className="flex gap-2 border-b border-white/10 pb-2"
            role="tablist"
            aria-label="Music library sections"
          >
            {(
              [
                ["albums", "Albums"] as const,
                ["artists", "Artists"] as const,
                ["tracks", "Tracks"] as const,
              ] as const
            ).map(([tab, label]) => (
              <button
                key={tab}
                type="button"
                role="tab"
                aria-selected={musicTab === tab}
                onClick={() => setMusicTab(tab)}
                className={`rounded-lg px-4 py-2 text-sm font-medium transition-colors ${
                  musicTab === tab
                    ? "bg-primary text-background"
                    : "text-text-secondary hover:bg-white/10 hover:text-text-primary"
                }`}
              >
                {label}
              </button>
            ))}
          </div>

          {musicTab === "albums" && (
            <section role="tabpanel" aria-labelledby="tab-albums">
              {albums.length > 0 ? (
                <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
                  {albums.map((album, i) => (
                    <AlbumCard
                      key={album.Id}
                      item={album}
                      index={i}
                      onClick={() => navigate(`/item/${album.Id}`)}
                    />
                  ))}
                </div>
              ) : (
                <p className="text-sm text-text-tertiary">No albums in this library.</p>
              )}
            </section>
          )}

          {musicTab === "artists" && (
            <section role="tabpanel" aria-labelledby="tab-artists">
              {artists.length > 0 ? (
                <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
                  {artists.map((artist, i) => (
                    <MediaCard
                      key={artist.Id}
                      item={artist}
                      index={i}
                      onClick={() => navigate(`/item/${artist.Id}`)}
                    />
                  ))}
                </div>
              ) : (
                <p className="text-sm text-text-tertiary">No artists in this library.</p>
              )}
            </section>
          )}

          {musicTab === "tracks" && (
            <section role="tabpanel" aria-labelledby="tab-tracks">
              {tracks.length > 0 ? (
                <div className="rounded-xl bg-surface">
                  <div className="divide-y divide-white/10">
                    {tracks.map((track) => {
                      const albumId = track.AlbumId ?? track.ParentId;
                      return (
                        <div
                          key={track.Id}
                          role="button"
                          tabIndex={0}
                          onClick={() => {
                            if (albumId) {
                              navigate(`/item/${albumId}?highlight=${track.Id}`);
                            } else {
                              play(track);
                              navigate("/player");
                            }
                          }}
                          onKeyDown={(e) => {
                            if (e.key === "Enter" || e.key === " ") {
                              e.preventDefault();
                              if (albumId) {
                                navigate(`/item/${albumId}?highlight=${track.Id}`);
                              } else {
                                play(track);
                                navigate("/player");
                              }
                            }
                          }}
                          className="flex cursor-pointer items-center gap-4 px-4 py-3 text-left transition-colors hover:bg-white/10"
                        >
                          <span className="w-6 shrink-0 text-sm text-text-tertiary">
                            {track.IndexNumber ?? "—"}
                          </span>
                          <div className="min-w-0 flex-1">
                            <p className="font-medium text-text-primary">{track.Name}</p>
                            <p className="truncate text-sm text-text-tertiary">
                              {[track.Album, track.AlbumArtist, ...(track.Artists ?? [])]
                                .filter(Boolean)
                                .join(" · ")}
                            </p>
                          </div>
                          <span className="shrink-0 text-sm text-text-tertiary">
                            {formatTrackDuration(track.RunTimeTicks)}
                          </span>
                          <Play className="h-5 w-5 shrink-0 text-primary" fill="currentColor" />
                        </div>
                      );
                    })}
                  </div>
                </div>
              ) : (
                <p className="text-sm text-text-tertiary">No tracks in this library.</p>
              )}
            </section>
          )}
        </div>
      ) : items.length === 0 ? (
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
