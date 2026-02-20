import { create } from "zustand";
import { persist } from "zustand/middleware";
import { api } from "../api/jellyfin";
import type { User, AuthenticationResult } from "../types/jellyfin";

const AUTH_KEY = "finar_auth";

interface AuthState {
  user: User | null;
  serverUrl: string | null;
  accessToken: string | null;
  isLoading: boolean;
  error: string | null;
  isAuthenticated: boolean;
  restoreSession: () => Promise<boolean>;
  login: (serverUrl: string, username: string, password: string) => Promise<boolean>;
  initiateQuickConnect: (serverUrl: string) => Promise<string | null>;
  checkQuickConnect: (code: string) => Promise<boolean>;
  logout: () => Promise<void>;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      serverUrl: null,
      accessToken: null,
      isLoading: false,
      error: null,
      isAuthenticated: false,

      async restoreSession() {
        const stored = localStorage.getItem(AUTH_KEY);
        if (!stored) return false;
        try {
          const { serverUrl, accessToken, userId } = JSON.parse(stored);
          if (!serverUrl || !accessToken || !userId) return false;
          api.setServerUrl(serverUrl);
          api.setCredentials(accessToken, userId);
          const user = await api.getCurrentUser();
          set({
            user,
            serverUrl,
            accessToken,
            isAuthenticated: true,
            error: null,
          });
          return true;
        } catch {
          localStorage.removeItem(AUTH_KEY);
          api.clearCredentials();
          set({
            user: null,
            serverUrl: null,
            accessToken: null,
            isAuthenticated: false,
          });
          return false;
        }
      },

      async login(serverUrl: string, username: string, password: string) {
        set({ isLoading: true, error: null });
        try {
          const base = serverUrl.replace(/\/$/, "");
          const connected = await api.testConnection(base);
          if (!connected) {
            set({
              isLoading: false,
              error: "Could not connect to server. Check the URL.",
            });
            return false;
          }
          api.setServerUrl(base);
          const result: AuthenticationResult = await api.authenticate(
            username,
            password
          );
          localStorage.setItem(
            AUTH_KEY,
            JSON.stringify({
              serverUrl: result.serverUrl,
              accessToken: result.accessToken,
              userId: result.user.Id,
            })
          );
          set({
            user: result.user,
            serverUrl: result.serverUrl,
            accessToken: result.accessToken,
            isAuthenticated: true,
            isLoading: false,
            error: null,
          });
          return true;
        } catch (e: unknown) {
          const message =
            e instanceof Error ? e.message : "Login failed. Check credentials.";
          set({
            isLoading: false,
            error: message,
          });
          return false;
        }
      },

      async initiateQuickConnect(serverUrl: string) {
        set({ isLoading: true, error: null });
        try {
          const base = serverUrl.replace(/\/$/, "");
          const connected = await api.testConnection(base);
          if (!connected) {
            set({ isLoading: false, error: "Could not connect to server." });
            return null;
          }
          api.setServerUrl(base);
          const code = await api.initiateQuickConnect();
          set({ isLoading: false });
          return code;
        } catch {
          set({ isLoading: false, error: "Quick Connect not available." });
          return null;
        }
      },

      async checkQuickConnect(code: string) {
        try {
          const result = await api.checkQuickConnect(code);
          if (result) {
            localStorage.setItem(
              AUTH_KEY,
              JSON.stringify({
                serverUrl: result.serverUrl,
                accessToken: result.accessToken,
                userId: result.user.Id,
              })
            );
            set({
              user: result.user,
              serverUrl: result.serverUrl,
              accessToken: result.accessToken,
              isAuthenticated: true,
              error: null,
            });
            return true;
          }
          return false;
        } catch {
          return false;
        }
      },

      async logout() {
        set({ isLoading: true });
        try {
          const url = get().serverUrl;
          const token = get().accessToken;
          if (url && token) {
            await fetch(`${url}/Sessions/Logout`, {
              method: "POST",
              headers: { "X-Emby-Authorization": `MediaBrowser Token="${token}"` },
            });
          }
        } catch {
          /* ignore */
        }
        localStorage.removeItem(AUTH_KEY);
        api.clearCredentials();
        set({
          user: null,
          serverUrl: null,
          accessToken: null,
          isAuthenticated: false,
          isLoading: false,
          error: null,
        });
      },

      clearError() {
        set({ error: null });
      },
    }),
    { name: "finar-auth", partialize: () => ({}) }
  )
);
