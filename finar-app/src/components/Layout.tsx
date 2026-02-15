import { useState, useEffect } from "react";
import { Link, useLocation, Outlet, useNavigate } from "react-router-dom";
import { motion, AnimatePresence } from "framer-motion";
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
  Menu,
  X,
  Play,
} from "lucide-react";
import { useAuthStore } from "../stores/auth";
import { useLibraryStore } from "../stores/library";
import { getUserAvatarUrl } from "../utils/image";
import { Button } from "./Button";

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

export function Layout() {
  const [sidebarOpen] = useState(true);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
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

      {/* Mobile header */}
      <header className="flex h-14 items-center justify-between border-b border-white/10 bg-background-secondary px-4 md:hidden">
        <button
          type="button"
          onClick={() => setMobileMenuOpen(true)}
          className="rounded-lg p-2 text-text-primary"
        >
          <Menu className="h-6 w-6" />
        </button>
        <div className="flex items-center gap-2">
          <Play className="h-6 w-6 text-primary" fill="currentColor" />
          <span className="font-bold text-text-primary">Finar</span>
        </div>
        <div className="w-10" />
      </header>

      {/* Mobile menu overlay */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 bg-black/60 md:hidden"
            onClick={() => setMobileMenuOpen(false)}
          >
            <motion.aside
              initial={{ x: -280 }}
              animate={{ x: 0 }}
              exit={{ x: -280 }}
              transition={{ type: "spring", damping: 25 }}
              className="flex h-full w-72 flex-col bg-background-secondary shadow-xl"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex h-14 items-center justify-between border-b border-white/10 px-4">
                <span className="font-bold text-text-primary">Finar</span>
                <button
                  type="button"
                  onClick={() => setMobileMenuOpen(false)}
                  className="rounded-lg p-2 text-text-primary"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
              <nav className="flex-1 space-y-1 overflow-y-auto p-2">
                {NAV.map(({ path, label, icon: Icon }) => {
                  const isActive = location.pathname === path;
                  return (
                    <Link
                      key={path}
                      to={path}
                      onClick={() => setMobileMenuOpen(false)}
                      className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium ${
                        isActive
                          ? "bg-gradient-to-r from-primary to-primary/80 text-white"
                          : "text-text-secondary"
                      }`}
                    >
                      <Icon className="h-5 w-5" />
                      {label}
                    </Link>
                  );
                })}
                {libraries.length > 0 && (
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
                          onClick={() => setMobileMenuOpen(false)}
                          className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm ${
                            location.pathname === `/library/${lib.Id}`
                              ? "bg-surface text-primary"
                              : "text-text-secondary"
                          }`}
                        >
                          <LibIcon className="h-5 w-5 shrink-0" />
                          <span className="min-w-0 flex-1 truncate">{lib.Name}</span>
                          <span className="flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-white/10 px-1.5 text-xs font-medium text-text-primary">
                            {count}
                          </span>
                        </Link>
                      );
                    })}
                  </>
                )}
                <Link
                  to="/settings"
                  onClick={() => setMobileMenuOpen(false)}
                  className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm ${
                    location.pathname === "/settings"
                      ? "bg-primary/20 text-primary"
                      : "text-text-secondary"
                  }`}
                >
                  <Settings className="h-5 w-5" />
                  Settings
                </Link>
              </nav>
              <div className="border-t border-white/10 p-3">
                <div className="flex items-center gap-3 rounded-xl bg-surface p-3">
                  <div className="h-10 w-10 shrink-0 overflow-hidden rounded-xl bg-gradient-to-br from-primary to-accent">
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
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-semibold text-text-primary">
                      {user?.Name ?? "Guest"}
                    </p>
                    <p className="truncate text-xs text-text-tertiary">
                      {serverUrl ? truncateUrl(serverUrl) : "Signed in"}
                    </p>
                  </div>
                  <Button variant="ghost" size="sm" onClick={handleLogout}>
                    <LogOut className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </motion.aside>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main content - single scroll region, no visible scrollbar */}
      <main className="app-main-scroll min-h-0 flex-1 overflow-auto">
        <Outlet />
      </main>
    </div>
  );
}
