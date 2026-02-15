import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { JellyfinApi } from '../api/jellyfinApi';
import * as authStorage from '../api/authStorage';
import type { User, AuthenticationResult } from '../api/models';

type AuthState =
  | { status: 'initial' | 'loading' }
  | { status: 'unauthenticated' }
  | { status: 'authenticated'; user: User }
  | { status: 'error'; message: string };

type AuthContextValue = {
  state: AuthState;
  api: JellyfinApi;
  login: (serverUrl: string, username: string, password: string) => Promise<boolean>;
  connectToServer: (url: string) => Promise<boolean>;
  initiateQuickConnect: () => Promise<string | null>;
  checkQuickConnect: (secret: string) => Promise<boolean>;
  logout: () => Promise<void>;
  restoreSession: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

const api = new JellyfinApi();

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({ status: 'initial' });

  const restoreSession = useCallback(async () => {
    setState({ status: 'loading' });
    const { serverUrl, userId, accessToken } = await authStorage.getStoredSession();
    if (!serverUrl || !userId || !accessToken) {
      setState({ status: 'unauthenticated' });
      return;
    }
    try {
      api.setServerUrl(serverUrl);
      api.setCredentials(accessToken, userId);
      const user = await api.getCurrentUser();
      setState({ status: 'authenticated', user });
    } catch {
      await authStorage.clearStoredSession();
      api.clearCredentials();
      setState({ status: 'unauthenticated' });
    }
  }, []);

  useEffect(() => {
    restoreSession();
  }, [restoreSession]);

  const login = useCallback(
    async (serverUrl: string, username: string, password: string): Promise<boolean> => {
      setState({ status: 'loading' });
      try {
        const connected = await api.testConnection(serverUrl);
        if (!connected) {
          setState({
            status: 'error',
            message: 'Could not connect to server. Check the URL and try again.',
          });
          return false;
        }
        const result = await api.authenticate(username, password);
        await authStorage.setStoredSession(result.serverUrl, result.user.id, result.accessToken);
        await authStorage.addSavedServer({
          url: result.serverUrl,
          name: result.user.serverName ?? 'Jellyfin',
          serverId: result.serverId,
          lastUserId: result.user.id,
          lastUserName: result.user.name,
        });
        setState({ status: 'authenticated', user: result.user });
        return true;
      } catch (e: unknown) {
        const message =
          e && typeof e === 'object' && 'message' in e
            ? String((e as { message: string }).message)
            : 'Login failed. Check credentials and server URL.';
        setState({ status: 'error', message });
        return false;
      }
    },
    []
  );

  const connectToServer = useCallback(async (url: string): Promise<boolean> => {
    setState({ status: 'loading' });
    try {
      const ok = await api.testConnection(url);
      if (ok) setState({ status: 'unauthenticated' });
      else setState({ status: 'error', message: 'Could not connect to server.' });
      return ok;
    } catch {
      setState({ status: 'error', message: 'Could not connect to server.' });
      return false;
    }
  }, []);

  const initiateQuickConnect = useCallback(async (): Promise<string | null> => {
    try {
      return await api.initiateQuickConnect();
    } catch {
      return null;
    }
  }, []);

  const checkQuickConnect = useCallback(async (secret: string): Promise<boolean> => {
    try {
      const result = await api.checkQuickConnect(secret);
      if (result) {
        await authStorage.setStoredSession(
          result.serverUrl,
          result.user.id,
          result.accessToken
        );
        setState({ status: 'authenticated', user: result.user });
        return true;
      }
      return false;
    } catch {
      return false;
    }
  }, []);

  const logout = useCallback(async () => {
    setState({ status: 'loading' });
    try {
      await api.logout();
    } catch {
      /* ignore */
    }
    await authStorage.clearStoredSession();
    setState({ status: 'unauthenticated' });
  }, []);

  const value = useMemo(
    () => ({
      state,
      api,
      login,
      connectToServer,
      initiateQuickConnect,
      checkQuickConnect,
      logout,
      restoreSession,
    }),
    [
      state,
      login,
      connectToServer,
      initiateQuickConnect,
      checkQuickConnect,
      logout,
      restoreSession,
    ]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

export function useJellyfinApi(): JellyfinApi {
  return useAuth().api;
}
