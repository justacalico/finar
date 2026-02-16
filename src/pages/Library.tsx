import { useEffect, useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import { ArrowLeft, Play } from "lucide-react";
import { api } from "../api/jellyfin";
import { useTranslation } from "../translations";
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
  const { t } = useTranslation();
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
  const [tracksLoaded, setTracksLoaded] = useState(false);
  const [tracksLoading, setTracksLoading] = useState(false);

  useEffect(() => {
    if (!id) return;
    let cancelled = false;
    setLoading(true);
    setAlbums([]);
    setArtists([]);
    setTracks([]);

    const load = async () => {
      const [libs, genericRes, albumsRes, artistsRes, directChildrenRes] = await Promise.all([
        api.getLibraries(),
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
        api.getItems({
          parentId: id,
          includeItemTypes: ["MusicAlbum"],
          recursive: true,
          limit: 200,
          sortBy: "SortName",
          sortOrder: "Ascending",
          fields: ["Overview"],
        }),
        api.getItems({
          parentId: id,
          includeItemTypes: ["MusicArtist", "Folder"],
          recursive: true,
          limit: 200,
          sortBy: "SortName",
          sortOrder: "Ascending",
          fields: ["Overview"],
        }),
        api.getItems({
          parentId: id,
          recursive: false,
          limit: 100,
          sortBy: "SortName",
          sortOrder: "Ascending",
          fields: ["Overview"],
          excludeItemTypes: ["Playlist", "UserView", "CollectionFolder"],
        }),
      ]);

      if (cancelled) return;
      const lib = libs.find((l) => l.Id === id) ?? null;
      setLibrary(lib);

      if (isMusicLibrary(lib)) {
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
        setItems([]);
      } else if (lib?.CollectionType?.toLowerCase() === "playlists") {
        const list = genericRes?.Items ?? [];
        const allPlaylists = await api.getItems({
          includeItemTypes: ["Playlist"],
          recursive: true,
          limit: 100,
          sortBy: "SortName",
          sortOrder: "Ascending",
          fields: ["Overview"],
        });
        if (cancelled) return;
        const playlists = allPlaylists?.Items ?? [];
        if (playlists.length > 0) {
          const byId = new Map(list.map((i) => [i.Id, i]));
          for (const p of playlists) {
            if (!byId.has(p.Id)) byId.set(p.Id, p);
          }
          setItems(
            [...byId.values()].sort((a, b) =>
              (a.Name ?? "").localeCompare(b.Name ?? "")
            )
          );
        } else {
          setItems(list);
        }
      } else {
        setItems(genericRes?.Items ?? []);
      }
    };

    load()
      .catch((e) => {
        if (!cancelled) setError(e instanceof Error ? e.message : t("library.failedToLoad"));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [id, t]);

  const musicLibrary = isMusicLibrary(library);
  useEffect(() => {
    if (!id || !musicLibrary || !tracksLoaded) return;
    let cancelled = false;
    setTracksLoading(true);
    api
      .getItems({
        parentId: id,
        includeItemTypes: ["Audio"],
        recursive: true,
        limit: 500,
        sortBy: "SortName",
        sortOrder: "Ascending",
        fields: ["Overview"],
      })
      .then((res) => {
        if (!cancelled) setTracks(res?.Items ?? []);
      })
      .catch(() => {})
      .finally(() => {
        if (!cancelled) setTracksLoading(false);
      });
    return () => {
      cancelled = true;
      setTracksLoading(false);
    };
  }, [id, musicLibrary, tracksLoaded]);

  const play = usePlayerStore((s) => s.play);

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
        <p className="text-text-secondary">{error ?? t("library.libraryNotFound")}</p>
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
        {t("library.backLink")}
      </Link>
      <h1 className="mb-6 text-2xl font-bold text-text-primary">{library.Name}</h1>

      {musicLibrary ? (
        <div className="flex flex-col gap-6">
          <div
            className="flex gap-2 border-b border-white/10 pb-2"
            role="tablist"
            aria-label={t("library.musicLibrarySections")}
          >
            {(
              [
                ["albums", t("library.albums")] as const,
                ["artists", t("library.artists")] as const,
                ["tracks", t("library.tracks")] as const,
              ] as const
            ).map(([tab, label]) => (
              <button
                key={tab}
                type="button"
                role="tab"
                aria-selected={musicTab === tab}
                onClick={() => {
                  setMusicTab(tab);
                  if (tab === "tracks") setTracksLoaded(true);
                }}
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
                <p className="text-sm text-text-tertiary">{t("library.noAlbums")}</p>
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
                <p className="text-sm text-text-tertiary">{t("library.noArtists")}</p>
              )}
            </section>
          )}

          {musicTab === "tracks" && (
            <section role="tabpanel" aria-labelledby="tab-tracks">
              {tracksLoading ? (
                <div className="flex min-h-[20vh] items-center justify-center py-8">
                  <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
                </div>
              ) : tracks.length > 0 ? (
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
                <p className="text-sm text-text-tertiary">{t("library.noTracks")}</p>
              )}
            </section>
          )}
        </div>
      ) : items.length === 0 ? (
        <p className="text-text-tertiary">{t("library.noItems")}</p>
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
