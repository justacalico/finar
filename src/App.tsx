import { useEffect, useState } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { useAuthStore } from "./stores/auth";
import { useUpdateStore } from "./stores/update";
import { Layout } from "./components/Layout";
import { Splash } from "./pages/Splash";
import { Login } from "./pages/Login";
import { Home } from "./pages/Home";
import {
  LazySearch,
  LazyFavorites,
  LazyLibrary,
  LazyLibraryList,
  LazyItemDetail,
  LazySettings,
  LazyDownloads,
  LazyPlayer,
  withSuspense,
} from "./routes";
import { ThemeApplicator } from "./components/ThemeApplicator";
import "./index.css";

function AuthGuard({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/"
        element={
          <AuthGuard>
            <Layout />
          </AuthGuard>
        }
      >
        <Route index element={<Home />} />
        <Route path="search" element={withSuspense(LazySearch)} />
        <Route path="favorites" element={withSuspense(LazyFavorites)} />
        <Route path="downloads" element={withSuspense(LazyDownloads)} />
        <Route path="library">
          <Route index element={withSuspense(LazyLibraryList)} />
          <Route path=":id" element={withSuspense(LazyLibrary)} />
        </Route>
        <Route path="item/:id" element={withSuspense(LazyItemDetail)} />
        <Route path="settings" element={withSuspense(LazySettings)} />
      </Route>
      <Route
        path="/player"
        element={
          <AuthGuard>
            {withSuspense(LazyPlayer)}
          </AuthGuard>
        }
      />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export default function App() {
  const [hydrated, setHydrated] = useState(false);
  const restoreSession = useAuthStore((s) => s.restoreSession);
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const isLoading = useAuthStore((s) => s.isLoading);

  useEffect(() => {
    restoreSession().then(() => setHydrated(true));
  }, [restoreSession]);

  // Background update check: run once when app is ready and when window gains focus
  useEffect(() => {
    if (!hydrated || !isAuthenticated) return;
    const check = () => useUpdateStore.getState().check();
    check();
    const onFocus = () => check();
    window.addEventListener("focus", onFocus);
    return () => window.removeEventListener("focus", onFocus);
  }, [hydrated, isAuthenticated]);

  if (!hydrated || (!isAuthenticated && isLoading)) {
    return <Splash />;
  }

  return (
    <>
      <ThemeApplicator />
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </>
  );
}
