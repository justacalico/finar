import { create } from "zustand";
import { persist } from "zustand/middleware";
import { api } from "../api/jellyfin";
import type { User, AuthenticationResult } from "../types/jellyfin";

const AUTH_KEY = "finar_auth";
const PROFILES_KEY = "finar_profiles";

export interface Profile {
  id: string;
  serverUrl: string;
  accessToken: string;
  userId: string;
  userName: string;
  primaryImageTag?: string;
}

interface StoredProfiles {
  profiles: Profile[];
  lastProfileId: string | null;
}

function loadStoredProfiles(): StoredProfiles {
  try {
    const raw = localStorage.getItem(PROFILES_KEY);
    if (!raw) return { profiles: [], lastProfileId: null };
    const data = JSON.parse(raw) as StoredProfiles;
    if (!Array.isArray(data.profiles)) return { profiles: [], lastProfileId: null };
    return {
      profiles: data.profiles,
      lastProfileId: data.lastProfileId ?? null,
    };
  } catch {
    return { profiles: [], lastProfileId: null };
  }
}

function saveProfiles(profiles: Profile[], lastProfileId: string | null) {
  localStorage.setItem(PROFILES_KEY, JSON.stringify({ profiles, lastProfileId }));
}

function updateProfileUserInfo(profileId: string, userName: string, primaryImageTag?: string) {
  const { profiles, lastProfileId } = loadStoredProfiles();
  const next = profiles.map((p) =>
    p.id === profileId ? { ...p, userName, primaryImageTag } : p
  );
  saveProfiles(next, lastProfileId);
}

/** Migrate single-session auth to first profile. */
function migrateLegacyAuth(): Profile | null {
  const stored = localStorage.getItem(AUTH_KEY);
  if (!stored) return null;
  try {
    const { serverUrl, accessToken, userId } = JSON.parse(stored);
    if (!serverUrl || !accessToken || !userId) return null;
    const profile: Profile = {
      id: crypto.randomUUID(),
      serverUrl,
      accessToken,
      userId,
      userName: "", // will be filled on first restore
      primaryImageTag: undefined,
    };
    const { profiles } = loadStoredProfiles();
    if (profiles.some((p) => p.serverUrl === serverUrl && p.userId === userId))
      return null;
    const next = { profiles: [profile, ...profiles], lastProfileId: profile.id };
    localStorage.setItem(PROFILES_KEY, JSON.stringify(next));
    localStorage.removeItem(AUTH_KEY);
    return profile;
  } catch {
    return null;
  }
}

interface AuthState {
  profiles: Profile[];
  currentProfileId: string | null;
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
  switchProfile: (profileId: string) => Promise<boolean>;
  logout: () => Promise<void>;
  removeProfile: (profileId: string) => void;
  clearError: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      profiles: [],
      currentProfileId: null,
      user: null,
      serverUrl: null,
      accessToken: null,
      isLoading: false,
      error: null,
      isAuthenticated: false,

      async restoreSession() {
        let { profiles, lastProfileId } = loadStoredProfiles();
        const migrated = migrateLegacyAuth();
        if (migrated) {
          const stored = loadStoredProfiles();
          profiles = stored.profiles;
          lastProfileId = stored.lastProfileId;
        }
        set({ profiles });
        if (profiles.length === 0) return false;
        const toRestore = lastProfileId ? profiles.find((p) => p.id === lastProfileId) : null;
        if (!toRestore) return false;
        try {
          api.setServerUrl(toRestore.serverUrl);
          api.setCredentials(toRestore.accessToken, toRestore.userId);
          const user = await api.getCurrentUser();
          updateProfileUserInfo(toRestore.id, user.Name, user.PrimaryImageTag);
          set({
            profiles: loadStoredProfiles().profiles,
            currentProfileId: toRestore.id,
            user,
            serverUrl: toRestore.serverUrl,
            accessToken: toRestore.accessToken,
            isAuthenticated: true,
            error: null,
          });
          return true;
        } catch {
          api.clearCredentials();
          saveProfiles(profiles, null);
          set({
            currentProfileId: null,
            user: null,
            serverUrl: null,
            accessToken: null,
            isAuthenticated: false,
            profiles,
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
          const { profiles } = loadStoredProfiles();
          const existing = profiles.find(
            (p) =>
              p.serverUrl === result.serverUrl && p.userId === result.user.Id
          );
          if (existing) {
            const updated: Profile = {
              ...existing,
              accessToken: result.accessToken,
              userName: result.user.Name,
              primaryImageTag: result.user.PrimaryImageTag,
            };
            const nextProfiles = profiles.map((p) =>
              p.id === existing.id ? updated : p
            );
            saveProfiles(nextProfiles, existing.id);
            set({
              profiles: nextProfiles,
              currentProfileId: existing.id,
              user: result.user,
              serverUrl: result.serverUrl,
              accessToken: result.accessToken,
              isAuthenticated: true,
              isLoading: false,
              error: null,
            });
            return true;
          }
          const profile: Profile = {
            id: crypto.randomUUID(),
            serverUrl: result.serverUrl,
            accessToken: result.accessToken,
            userId: result.user.Id,
            userName: result.user.Name,
            primaryImageTag: result.user.PrimaryImageTag,
          };
          const nextProfiles = [profile, ...profiles];
          saveProfiles(nextProfiles, profile.id);
          set({
            profiles: nextProfiles,
            currentProfileId: profile.id,
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
          if (!result) return false;
          const profile: Profile = {
            id: crypto.randomUUID(),
            serverUrl: result.serverUrl,
            accessToken: result.accessToken,
            userId: result.user.Id,
            userName: result.user.Name,
            primaryImageTag: result.user.PrimaryImageTag,
          };
          const { profiles } = loadStoredProfiles();
          const nextProfiles = [profile, ...profiles];
          saveProfiles(nextProfiles, profile.id);
          set({
            profiles: nextProfiles,
            currentProfileId: profile.id,
            user: result.user,
            serverUrl: result.serverUrl,
            accessToken: result.accessToken,
            isAuthenticated: true,
            error: null,
          });
          return true;
        } catch {
          return false;
        }
      },

      async switchProfile(profileId: string) {
        const profile = get().profiles.find((p) => p.id === profileId);
        if (!profile) return false;
        try {
          api.setServerUrl(profile.serverUrl);
          api.setCredentials(profile.accessToken, profile.userId);
          const user = await api.getCurrentUser();
          updateProfileUserInfo(profileId, user.Name, user.PrimaryImageTag);
          saveProfiles(get().profiles, profileId);
          set({
            profiles: loadStoredProfiles().profiles,
            currentProfileId: profileId,
            user,
            serverUrl: profile.serverUrl,
            accessToken: profile.accessToken,
            isAuthenticated: true,
            error: null,
          });
          return true;
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
        api.clearCredentials();
        const { profiles } = loadStoredProfiles();
        saveProfiles(profiles, null);
        set({
          currentProfileId: null,
          user: null,
          serverUrl: null,
          accessToken: null,
          isAuthenticated: false,
          isLoading: false,
          error: null,
        });
      },

      removeProfile(profileId: string) {
        const { profiles, lastProfileId } = loadStoredProfiles();
        const next = profiles.filter((p) => p.id !== profileId);
        const wasCurrent = get().currentProfileId === profileId;
        const newLast =
          next.length === 0 ? null : wasCurrent ? null : lastProfileId === profileId ? next[0]?.id ?? null : lastProfileId;
        saveProfiles(next, newLast);
        if (wasCurrent) {
          api.clearCredentials();
          set({
            profiles: next,
            currentProfileId: null,
            user: null,
            serverUrl: null,
            accessToken: null,
            isAuthenticated: false,
          });
        } else {
          set({ profiles: next });
        }
      },

      clearError() {
        set({ error: null });
      },
    }),
    { name: "finar-auth", partialize: () => ({}) }
  )
);
