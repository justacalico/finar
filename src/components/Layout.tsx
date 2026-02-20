import { useState, useEffect } from "react";
import { Link, useLocation, Outlet, useNavigate } from "react-router-dom";
import {
  Home,
  Search,
  Heart,
  Download,
  FolderOpen,
  Film,
  Music,
  Video,
  ListMusic,
  Tv,
  Settings,
  Play,
  LayoutGrid,
  ArrowLeft,
  UserCircle,
} from "lucide-react";
import { preloadRoute, preloadLibrary } from "../routes";
import { useAuthStore } from "../stores/auth";
import { useDownloadsStore } from "../stores/downloads";
import { useLibraryStore } from "../stores/library";
import { useTranslation } from "../translations";
import { getUserAvatarUrl } from "../utils/image";

const NAV_PATHS = [
  { path: "/", labelKey: "common.home" as const, icon: Home },
  { path: "/search", labelKey: "common.search" as const, icon: Search },
  { path: "/favorites", labelKey: "common.favorites" as const, icon: Heart },
  { path: "/downloads", labelKey: "common.downloads" as const, icon: Download },
];

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
    case "photos":
    case "homevideos":
    case "books":
    default:
      return FolderOpen;
  }
}

function truncateUrl(url: string, maxLen = 24): string {
  if (url.length <= maxLen) return url;
  return url.slice(0, 12) + "..." + url.slice(-8);
}

const MOBILE_NAV_PATHS = [
  { path: "/", labelKey: "common.home" as const, icon: Home },
  { path: "/search", labelKey: "common.search" as const, icon: Search },
  { path: "/library", labelKey: "common.library" as const, icon: LayoutGrid },
  { path: "/downloads", labelKey: "common.downloads" as const, icon: Download },
];

export function Layout() {
  const { t } = useTranslation();
  const [sidebarOpen] = useState(true);
  const location = useLocation();
  const navigate = useNavigate();
  const { user, serverUrl, profiles, goToProfilePicker } = useAuthStore();
  const { libraries, loadLibraries, loadHomeData } = useLibraryStore();
  const initListeners = useDownloadsStore((s) => s.initListeners);

  useEffect(() => {
    loadLibraries();
  }, [loadLibraries]);

  useEffect(() => {
    loadHomeData();
  }, [loadHomeData]);

  useEffect(() => {
    const unlisten = initListeners();
    return unlisten;
  }, [initListeners]);

  const isLibraryDetail = /^\/library\/[^/]+$/.test(location.pathname);
  const isItemDetail = /^\/item\/[^/]+$/.test(location.pathname);
  const showBackOnMobile = isLibraryDetail || isItemDetail;

  const handleBack = () => {
    if (isLibraryDetail) {
      navigate("/library");
    } else if (isItemDetail) {
      if (window.history.state?.idx > 0) {
        navigate(-1);
      } else {
        navigate("/");
      }
    }
  };

  return (
    <div className="flex h-screen flex-col overflow-hidden bg-background md:flex-row">
      {/* Desktop sidebar */}
      <aside
        className={`hidden border-r border-white/10 bg-background-secondary md:flex md:flex-col ${
          sidebarOpen ? "w-64" : "w-20"
        } transition-all duration-200`}
      >
        <div className="flex h-16 items-center gap-3 border-b border-white/10 px-4">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-accent">
            <Play className="h-5 w-5 text-background" fill="currentColor" />
          </div>
          {sidebarOpen && (
            <span className="text-lg font-bold tracking-tight text-text-primary">
              {t("common.appName")}
            </span>
          )}
        </div>
        <nav className="flex-1 space-y-1 overflow-y-auto p-2">
          {NAV_PATHS.map(({ path, labelKey, icon: Icon }) => {
            const isActive = location.pathname === path;
            return (
              <Link
                key={path}
                to={path}
                onMouseEnter={() => path !== "/" && preloadRoute(path)}
                className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors ${
                  isActive
                    ? "bg-gradient-to-r from-primary to-primary/80 text-white"
                    : "text-text-secondary hover:bg-white/10 hover:text-text-primary"
                }`}
              >
                <Icon className="h-5 w-5 shrink-0" />
                {sidebarOpen && <span>{t(labelKey)}</span>}
              </Link>
            );
          })}
          {sidebarOpen && libraries.length > 0 && (
            <>
              <div className="px-3 py-2 text-xs font-semibold uppercase tracking-wider text-text-tertiary">
                {t("common.libraries").toUpperCase()}
              </div>
              {libraries.slice(0, 8).map((lib) => {
                const LibIcon = getLibraryIcon(lib.CollectionType);
                const count = lib.ChildCount ?? 0;
                return (
                  <Link
                    key={lib.Id}
                    to={`/library/${lib.Id}`}
                    onMouseEnter={preloadLibrary}
                    className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm transition-colors ${
                      location.pathname === `/library/${lib.Id}`
                        ? "bg-surface text-primary"
                        : "text-text-secondary hover:bg-white/10 hover:text-text-primary"
                    }`}
                  >
                    <LibIcon className="h-5 w-5 shrink-0" />
                    {sidebarOpen && (
                      <>
                        <span className="min-w-0 flex-1 truncate">{lib.Name}</span>
                        <span className="flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-white/10 px-1.5 text-xs font-medium text-text-primary">
                          {count}
                        </span>
                      </>
                    )}
                  </Link>
                );
              })}
            </>
          )}
        </nav>
        <div className="border-t border-white/10 p-3 space-y-2">
          <Link
            to="/settings"
            onMouseEnter={() => preloadRoute("/settings")}
            className={`flex items-center gap-3 rounded-xl bg-surface p-3 transition-colors ${
              !sidebarOpen ? "justify-center" : ""
            } ${
              location.pathname === "/settings"
                ? "ring-1 ring-primary/50"
                : "hover:bg-surface-elevated"
            }`}
          >
            <div className="relative h-10 w-10 shrink-0 overflow-hidden rounded-xl bg-gradient-to-br from-primary to-accent">
              {user && serverUrl && getUserAvatarUrl(user) ? (
                <img
                  src={getUserAvatarUrl(user)}
                  alt=""
                  className="h-full w-full object-cover"
                />
              ) : (
                <span className="flex h-full w-full items-center justify-center text-sm font-bold text-background">
                  {user?.Name?.charAt(0) ?? "?"}
                </span>
              )}
            </div>
            {sidebarOpen && (
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-text-primary">
                  {user?.Name ?? t("common.guest")}
                </p>
                <p className="truncate text-xs text-text-tertiary">
                  {serverUrl ? truncateUrl(serverUrl) : t("common.signedIn")}
                </p>
              </div>
            )}
            <span
              className={`rounded-lg p-1.5 text-text-secondary ${
                location.pathname === "/settings"
                  ? "text-primary"
                  : "hover:bg-white/10 hover:text-text-primary"
              }`}
              title={t("common.settings")}
            >
              <Settings className="h-4 w-4" />
            </span>
          </Link>
          {sidebarOpen && profiles.length > 0 && (
            <button
              type="button"
              onClick={() => {
                goToProfilePicker();
                navigate("/profile-picker");
              }}
              className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-text-secondary transition-colors hover:bg-white/10 hover:text-text-primary"
            >
              <UserCircle className="h-4 w-4 shrink-0" />
              <span>{t("settings.switchProfile")}</span>
            </button>
          )}
        </div>
      </aside>

      {/* Mobile header: back (when nested) or logo + Settings */}
      <header className="flex h-14 shrink-0 items-center justify-between border-b border-white/10 bg-background-secondary px-4 md:hidden">
        <div className="flex min-w-0 flex-1 items-center gap-2">
          {showBackOnMobile ? (
            <button
              type="button"
              onClick={handleBack}
              className="flex items-center gap-1 rounded-lg py-2 pr-2 text-text-primary hover:bg-white/10"
              aria-label={t("common.goBack")}
            >
              <ArrowLeft className="h-6 w-6 shrink-0" />
            </button>
          ) : (
            <>
              <Play className="h-6 w-6 shrink-0 text-primary" fill="currentColor" />
              <span className="font-bold tracking-tight text-text-primary">{t("common.appName")}</span>
            </>
          )}
        </div>
        <Link
          to="/settings"
          className="rounded-lg p-2 text-text-secondary hover:bg-white/10 hover:text-text-primary"
          aria-label={t("common.settings")}
        >
          <Settings className="h-6 w-6" />
        </Link>
      </header>

      {/* Main content - single scroll region; on mobile add padding above bottom nav */}
      <main className="app-main-scroll min-h-0 flex-1 overflow-auto pb-20 md:pb-0">
        <Outlet />
      </main>

      {/* Mobile bottom nav (Flutter-style: Home, Search, Library, Downloads) */}
      <nav className="fixed bottom-0 left-0 right-0 z-40 mx-4 mb-3 flex md:hidden">
        <div className="flex h-16 flex-1 items-center rounded-[28px] border border-white/10 bg-background-secondary/90 shadow-lg backdrop-blur-xl">
          {MOBILE_NAV_PATHS.map(({ path, labelKey, icon: Icon }) => {
            const isLibrary = path === "/library";
            const isActive = isLibrary
              ? location.pathname === "/library" || location.pathname.startsWith("/library/")
              : location.pathname === path;
            const onPreload = () => {
              if (path === "/library") preloadLibrary();
              else if (path !== "/") preloadRoute(path);
            };
            return (
              <Link
                key={path}
                to={path}
                onMouseEnter={onPreload}
                onTouchStart={onPreload}
                className={`flex flex-1 flex-col items-center justify-center gap-1 py-2 transition-colors ${
                  isActive ? "text-primary" : "text-text-secondary"
                }`}
              >
                <Icon className={`h-6 w-6 ${isActive ? "scale-105" : ""}`} />
                <span className={`text-[10px] font-medium ${isActive ? "font-semibold" : ""}`}>
                  {t(labelKey)}
                </span>
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
