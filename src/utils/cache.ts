/**
 * In-memory cache with TTL. Used to avoid refetching Jellyfin data on every navigation.
 */

interface Entry<T> {
  data: T;
  expires: number;
}

const store = new Map<string, Entry<unknown>>();

export function cacheGet<T>(key: string): T | undefined {
  const entry = store.get(key) as Entry<T> | undefined;
  if (!entry) return undefined;
  if (Date.now() > entry.expires) {
    store.delete(key);
    return undefined;
  }
  return entry.data;
}

export function cacheSet<T>(key: string, data: T, ttlMs: number): void {
  store.set(key, {
    data,
    expires: Date.now() + ttlMs,
  });
}

export function cacheClear(): void {
  store.clear();
}

/** TTLs in ms */
export const CACHE_TTL = {
  SHORT: 60 * 1000,       // 1 min - search, resume
  MEDIUM: 2 * 60 * 1000,  // 2 min - home sections
  LONG: 5 * 60 * 1000,    // 5 min - libraries, item detail, seasons
} as const;
