import { create } from "zustand";
import pkg from "../../package.json";
import { checkForUpdate } from "../api/openlyst";
import { useSettingsStore } from "./settings";

export interface UpdateState {
  latestVersion: string;
  isUpdateAvailable: boolean;
  downloadUrl?: string;
  lastChecked: number | null;
  checking: boolean;
  check: () => Promise<void>;
}

export const useUpdateStore = create<UpdateState>((set, get) => ({
  latestVersion: pkg.version,
  isUpdateAvailable: false,
  downloadUrl: undefined,
  lastChecked: null,
  checking: false,

  check: async () => {
    if (get().checking) return;
    set({ checking: true });
    try {
      const language = useSettingsStore.getState().language;
      const r = await checkForUpdate(pkg.version, language);
      set({
        latestVersion: r.latestVersion,
        isUpdateAvailable: r.isUpdateAvailable,
        downloadUrl: r.downloadUrl,
        lastChecked: Date.now(),
      });
    } finally {
      set({ checking: false });
    }
  },
}));
