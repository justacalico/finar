import type { MediaItem } from './models';

export function getPrimaryImageUrl(
  baseUrl: string,
  item: MediaItem,
  opts?: { width?: number; height?: number; quality?: number }
): string {
  const tag = item.imageTags?.primary;
  if (!tag) return '';
  const p: string[] = [`tag=${tag}`];
  if (opts?.width != null) p.push(`maxWidth=${opts.width}`);
  if (opts?.height != null) p.push(`maxHeight=${opts.height}`);
  if (opts?.quality != null) p.push(`quality=${opts.quality}`);
  return `${baseUrl}/Items/${item.id}/Images/Primary?${p.join('&')}`;
}

/** For episodes, use series poster; otherwise primary. */
export function getDisplayImageUrl(
  baseUrl: string,
  item: MediaItem,
  opts?: { width?: number; height?: number; quality?: number }
): string {
  if (
    (item.type === 'episode' || item.typeString?.toLowerCase() === 'episode') &&
    item.seriesId
  ) {
    const p: string[] = [`tag=${item.imageTags?.primary ?? ''}`];
    if (opts?.width != null) p.push(`maxWidth=${opts.width}`);
    if (opts?.height != null) p.push(`maxHeight=${opts.height}`);
    if (opts?.quality != null) p.push(`quality=${opts.quality}`);
    return `${baseUrl}/Items/${item.seriesId}/Images/Primary?${p.join('&')}`;
  }
  return getPrimaryImageUrl(baseUrl, item, opts);
}

export function getBackdropUrl(
  baseUrl: string,
  item: MediaItem,
  index = 0,
  opts?: { width?: number; quality?: number }
): string {
  let tag: string | undefined;
  let itemId = item.id;
  if (item.backdropImageTags?.length) {
    tag = item.backdropImageTags[Math.min(index, item.backdropImageTags.length - 1)];
  } else if (item.parentBackdropImageTags?.length) {
    tag =
      item.parentBackdropImageTags[
        Math.min(index, item.parentBackdropImageTags.length - 1)
      ];
    itemId = item.parentBackdropItemId ?? item.id;
  }
  if (!tag) return '';
  const p: string[] = [`tag=${tag}`];
  if (opts?.width != null) p.push(`maxWidth=${opts.width}`);
  if (opts?.quality != null) p.push(`quality=${opts.quality}`);
  return `${baseUrl}/Items/${itemId}/Images/Backdrop/${index}?${p.join('&')}`;
}

export function getBackdropImageUrl(
  baseUrl: string,
  item: MediaItem,
  opts?: { width?: number; quality?: number }
): string {
  return getBackdropUrl(baseUrl, item, 0, opts);
}

export function formatRuntime(runtimeTicks: number | undefined): string {
  if (runtimeTicks == null) return '';
  const minutes = Math.round(runtimeTicks / 600000000);
  if (minutes < 60) return `${minutes}m`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return `${h}h ${m}m`;
}

export function getPlaybackProgress(item: MediaItem): number {
  if (item.runtimeTicks == null || item.runtimeTicks === 0) return 0;
  const pos =
    item.userData?.playbackPositionTicks ??
    item.playbackPositionTicks ??
    0;
  return Math.min(1, Math.max(0, pos / item.runtimeTicks));
}

export function getHeroTitle(item: MediaItem): string {
  if (
    (item.type === 'episode' || item.typeString?.toLowerCase() === 'episode') &&
    item.seriesName?.trim() &&
    item.name?.trim()
  ) {
    return `${item.seriesName} - ${item.name}`;
  }
  return item.name;
}
