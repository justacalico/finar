import { api } from "../api/jellyfin";
import type { MediaItem } from "../types/jellyfin";

export function getPrimaryImageUrl(
  item: MediaItem,
  opts?: { maxWidth?: number; maxHeight?: number }
): string {
  const tag = item.ImageTags?.Primary;
  if (!tag) return "";
  const base = api.serverUrl;
  const params = new URLSearchParams({ tag });
  if (opts?.maxWidth) params.set("maxWidth", String(opts.maxWidth));
  if (opts?.maxHeight) params.set("maxHeight", String(opts.maxHeight));
  return `${base}/Items/${item.Id}/Images/Primary?${params.toString()}`;
}

export function getBackdropUrl(
  item: MediaItem,
  index = 0,
  opts?: { maxWidth?: number }
): string {
  const tags = item.BackdropImageTags ?? item.ParentBackdropImageTags;
  const itemId = item.ParentBackdropItemId ?? item.Id;
  const tag = tags?.[index];
  if (!tag) return "";
  const base = api.serverUrl;
  const params = new URLSearchParams({ tag });
  if (opts?.maxWidth) params.set("maxWidth", String(opts.maxWidth));
  return `${base}/Items/${itemId}/Images/Backdrop/${index}?${params.toString()}`;
}

export function getDisplayImageUrl(
  item: MediaItem,
  opts?: { maxWidth?: number; maxHeight?: number }
): string {
  if (item.Type === "Episode" && item.SeriesId) {
    const base = api.serverUrl;
    const params = new URLSearchParams();
    if (opts?.maxWidth) params.set("maxWidth", String(opts.maxWidth));
    if (opts?.maxHeight) params.set("maxHeight", String(opts.maxHeight));
    return `${base}/Items/${item.SeriesId}/Images/Primary?${params.toString()}`;
  }
  return getPrimaryImageUrl(item, opts);
}

export function getUserAvatarUrl(user: { Id: string; PrimaryImageTag?: string }): string {
  if (!user.PrimaryImageTag) return "";
  return `${api.serverUrl}/Users/${user.Id}/Images/Primary?tag=${user.PrimaryImageTag}`;
}

export function getProfileAvatarUrl(profile: {
  serverUrl: string;
  userId: string;
  primaryImageTag?: string;
}): string {
  if (!profile.primaryImageTag) return "";
  const base = profile.serverUrl.replace(/\/$/, "");
  return `${base}/Users/${profile.userId}/Images/Primary?tag=${profile.primaryImageTag}`;
}
