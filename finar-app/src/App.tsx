import { useEffect, useState } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { useAuthStore } from "./stores/auth";
import { Layout } from "./components/Layout";
import { Splash } from "./pages/Splash";
import { Login } from "./pages/Login";
import { Home } from "./pages/Home";
import { Search } from "./pages/Search";
import { Favorites } from "./pages/Favorites";
import { Library } from "./pages/Library";
import { ItemDetail } from "./pages/ItemDetail";
import { Player } from "./pages/Player";
import { Settings } from "./pages/Settings";
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
        <Route path="search" element={<Search />} />
        <Route path="favorites" element={<Favorites />} />
        <Route path="library/:id" element={<Library />} />
        <Route path="item/:id" element={<ItemDetail />} />
        <Route path="settings" element={<Settings />} />
      </Route>
      <Route
        path="/player"
        element={
          <AuthGuard>
            <Player />
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

  if (!hydrated || (!isAuthenticated && isLoading)) {
    return <Splash />;
  }

  return (
    <BrowserRouter>
      <AppRoutes />
    </BrowserRouter>
  );
}
