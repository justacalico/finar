import { lazy, Suspense } from "react";

/** Lazy-loaded page components for code splitting. */
export const LazySearch = lazy(() => import("./pages/Search").then((m) => ({ default: m.Search })));
export const LazyFavorites = lazy(() =>
  import("./pages/Favorites").then((m) => ({ default: m.Favorites })),
);
export const LazyLibrary = lazy(() =>
  import("./pages/Library").then((m) => ({ default: m.Library })),
);
export const LazyLibraryList = lazy(() =>
  import("./pages/LibraryList").then((m) => ({ default: m.LibraryList })),
);
export const LazyItemDetail = lazy(() =>
  import("./pages/ItemDetail").then((m) => ({ default: m.ItemDetail })),
);
export const LazySettings = lazy(() =>
  import("./pages/Settings").then((m) => ({ default: m.Settings })),
);
export const LazyDownloads = lazy(() =>
  import("./pages/Downloads").then((m) => ({ default: m.Downloads })),
);
export const LazyPlayer = lazy(() =>
  import("./pages/Player").then((m) => ({ default: m.Player })),
);

/** Preload route chunks on hover / before navigation. */
const routePreloads: Record<string, () => Promise<unknown>> = {
  "/search": () => import("./pages/Search"),
  "/favorites": () => import("./pages/Favorites"),
  "/library": () => import("./pages/LibraryList"),
  "/downloads": () => import("./pages/Downloads"),
  "/settings": () => import("./pages/Settings"),
  "/player": () => import("./pages/Player"),
};

export function preloadRoute(path: string): void {
  const preload = routePreloads[path];
  if (preload) preload();
}

/** Preload library detail (used when navigating to /library/:id). */
export function preloadLibrary(): void {
  import("./pages/Library");
}

/** Preload item detail (used when hovering a card linking to /item/:id). */
export function preloadItemDetail(): void {
  import("./pages/ItemDetail");
}

export function RouteFallback() {
  return (
    <div className="flex min-h-[40vh] items-center justify-center">
      <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
    </div>
  );
}

export function withSuspense(Component: React.LazyExoticComponent<React.ComponentType>) {
  return (
    <Suspense fallback={<RouteFallback />}>
      <Component />
    </Suspense>
  );
}
