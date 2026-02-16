import { api } from "./jellyfin";
import type { HomeData, MediaItem } from "../types/jellyfin";

export async function fetchHomeData(): Promise<HomeData> {
  const [
    continueWatching,
    nextUp,
    recentlyAdded,
    recentlyReleased,
    topRated,
    recommended,
    favorites,
    recentlyAddedMovies,
    recentlyAddedShows,
    libraries,
  ] = await Promise.all([
    api.getContinueWatching(12),
    api.getNextUp(12),
    api.getRecentlyAdded(20),
    api.getRecentlyReleased(16),
    api.getTopRated(16),
    api.getRecommended(16),
    api.getFavorites(16),
    api.getRecentlyAdded(12, ["Movie"]),
    api.getRecentlyAdded(12, ["Series"]),
    api.getLibraries(),
  ]);

  return {
    continueWatching,
    nextUp,
    recentlyAdded,
    recentlyReleased,
    topRated,
    recommended,
    favorites,
    recentlyAddedMovies,
    recentlyAddedShows,
    libraries,
  };
}

export async function searchHintsToItems(
  hints: Awaited<ReturnType<typeof api.search>>
): Promise<MediaItem[]> {
  if (hints.length === 0) return [];
  const ids = [...new Set(hints.map((h) => h.ItemId).slice(0, 30))];
  const result = await api.getItems({
    ids,
    limit: ids.length,
    fields: ["Overview"],
  });
  const byId = new Map(result.Items.map((i) => [i.Id, i]));
  return ids.map((id) => byId.get(id)).filter(Boolean) as MediaItem[];
}
