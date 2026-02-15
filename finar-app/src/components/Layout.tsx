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
  LogOut,
  Play,
  LayoutGrid,
  ArrowLeft,
} from "lucide-react";
import { useAuthStore } from "../stores/auth";
import { useLibraryStore } from "../stores/library";
import { getUserAvatarUrl } from "../utils/image";

const NAV = [
  { path: "/", label: "Home", icon: Home },
  { path: "/search", label: "Search", icon: Search },
  { path: "/favorites", label: "Favorites", icon: Heart },
  { path: "/downloads", label: "Downloads", icon: Download },
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

const MOBILE_NAV = [
  { path: "/", label: "Home", icon: Home },
  { path: "/search", label: "Search", icon: Search },
  { path: "/library", label: "Library", icon: LayoutGrid },
  { path: "/downloads", label: "Downloads", icon: Download },
];

export function Layout() {
  const [sidebarOpen] = useState(true);
  const location = useLocation();
  const navigate = useNavigate();
  const { user, serverUrl, logout } = useAuthStore();
  const { libraries, loadLibraries } = useLibraryStore();

  useEffect(() => {
    loadLibraries();
  }, [loadLibraries]);

  const handleLogout = async () => {
    await logout();
    navigate("/login");
  };

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
              Finar
            </span>
          )}
        </div>
        <nav className="flex-1 space-y-1 overflow-y-auto p-2">
          {NAV.map(({ path, label, icon: Icon }) => {
            const isActive = location.pathname === path;
            return (
              <Link
                key={path}
                to={path}
                className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors ${
                  isActive
                    ? "bg-gradient-to-r from-primary to-primary/80 text-white"
                    : "text-text-secondary hover:bg-white/10 hover:text-text-primary"
                }`}
              >
                <Icon className="h-5 w-5 shrink-0" />
                {sidebarOpen && <span>{label}</span>}
              </Link>
            );
          })}
          {sidebarOpen && libraries.length > 0 && (
            <>
              <div className="px-3 py-2 text-xs font-semibold uppercase tracking-wider text-text-tertiary">
                LIBRARIES
              </div>
              {libraries.slice(0, 8).map((lib) => {
                const LibIcon = getLibraryIcon(lib.CollectionType);
                const count = lib.ChildCount ?? 0;
                return (
                  <Link
                    key={lib.Id}
                    to={`/library/${lib.Id}`}
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
          <Link
            to="/settings"
            className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition-colors ${
              location.pathname === "/settings"
                ? "bg-primary/20 text-primary"
                : "text-text-secondary hover:bg-white/10 hover:text-text-primary"
            }`}
          >
            <Settings className="h-5 w-5 shrink-0" />
            {sidebarOpen && <span>Settings</span>}
          </Link>
        </nav>
        <div className="border-t border-white/10 p-3">
          <div
            className={`flex items-center gap-3 rounded-xl bg-surface p-3 ${
              !sidebarOpen && "justify-center"
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
                  {user?.Name ?? "Guest"}
                </p>
                <p className="truncate text-xs text-text-tertiary">
                  {serverUrl ? truncateUrl(serverUrl) : "Signed in"}
                </p>
              </div>
            )}
            {sidebarOpen && (
              <button
                type="button"
                onClick={handleLogout}
                className="rounded-lg p-1.5 text-text-secondary hover:bg-white/10 hover:text-text-primary"
                title="Sign out"
              >
                <LogOut className="h-4 w-4" />
              </button>
            )}
          </div>
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
              aria-label="Go back"
            >
              <ArrowLeft className="h-6 w-6 shrink-0" />
            </button>
          ) : (
            <>
              <Play className="h-6 w-6 shrink-0 text-primary" fill="currentColor" />
              <span className="font-bold tracking-tight text-text-primary">Finar</span>
            </>
          )}
        </div>
        <Link
          to="/settings"
          className="rounded-lg p-2 text-text-secondary hover:bg-white/10 hover:text-text-primary"
          aria-label="Settings"
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
          {MOBILE_NAV.map(({ path, label, icon: Icon }) => {
            const isLibrary = path === "/library";
            const isActive = isLibrary
              ? location.pathname === "/library" || location.pathname.startsWith("/library/")
              : location.pathname === path;
            return (
              <Link
                key={path}
                to={path}
                className={`flex flex-1 flex-col items-center justify-center gap-1 py-2 transition-colors ${
                  isActive ? "text-primary" : "text-text-secondary"
                }`}
              >
                <Icon className={`h-6 w-6 ${isActive ? "scale-105" : ""}`} />
                <span className={`text-[10px] font-medium ${isActive ? "font-semibold" : ""}`}>
                  {label}
                </span>
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
