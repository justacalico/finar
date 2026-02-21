import AsyncStorage from '@react-native-async-storage/async-storage';
import type { SavedServer } from './models';

const KEY_SERVER = 'finar_current_server';
const KEY_USER = 'finar_current_user';
const KEY_TOKEN = 'finar_access_token';
const KEY_SERVERS = 'finar_servers';

export async function getStoredSession(): Promise<{
  serverUrl: string | null;
  userId: string | null;
  accessToken: string | null;
}> {
  const [serverUrl, userId, accessToken] = await Promise.all([
    AsyncStorage.getItem(KEY_SERVER),
    AsyncStorage.getItem(KEY_USER),
    AsyncStorage.getItem(KEY_TOKEN),
  ]);
  return { serverUrl, userId, accessToken };
}

export async function setStoredSession(serverUrl: string, userId: string, accessToken: string): Promise<void> {
  await Promise.all([
    AsyncStorage.setItem(KEY_SERVER, serverUrl),
    AsyncStorage.setItem(KEY_USER, userId),
    AsyncStorage.setItem(KEY_TOKEN, accessToken),
  ]);
}

export async function clearStoredSession(): Promise<void> {
  await Promise.all([
    AsyncStorage.removeItem(KEY_SERVER),
    AsyncStorage.removeItem(KEY_USER),
    AsyncStorage.removeItem(KEY_TOKEN),
  ]);
}

export async function getSavedServers(): Promise<SavedServer[]> {
  const raw = await AsyncStorage.getItem(KEY_SERVERS);
  if (!raw) return [];
  try {
    const arr = JSON.parse(raw) as SavedServer[];
    return Array.isArray(arr) ? arr : [];
  } catch {
    return [];
  }
}

export async function setSavedServers(servers: SavedServer[]): Promise<void> {
  await AsyncStorage.setItem(KEY_SERVERS, JSON.stringify(servers));
}

export async function addSavedServer(server: SavedServer): Promise<void> {
  const list = await getSavedServers();
  const idx = list.findIndex((s) => s.url === server.url);
  if (idx >= 0) list[idx] = server;
  else list.push(server);
  await setSavedServers(list);
}
