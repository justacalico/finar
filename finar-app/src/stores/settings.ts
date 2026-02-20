import { create } from "zustand";
import { persist } from "zustand/middleware";

export type Theme = "light" | "dark" | "oled";
export type AccentColor =
  | "teal"
  | "blue"
  | "purple"
  | "green"
  | "orange"
  | "red"
  | "pink";

export const ACCENT_COLORS: { id: AccentColor; name: string; primary: string; accent: string }[] = [
  { id: "teal", name: "Teal", primary: "#00e5b8", accent: "#00b8d9" },
  { id: "blue", name: "Blue", primary: "#3b82f6", accent: "#60a5fa" },
  { id: "purple", name: "Purple", primary: "#a855f7", accent: "#c084fc" },
  { id: "green", name: "Green", primary: "#22c55e", accent: "#4ade80" },
  { id: "orange", name: "Orange", primary: "#f97316", accent: "#fb923c" },
  { id: "red", name: "Red", primary: "#ef4444", accent: "#f87171" },
  { id: "pink", name: "Pink", primary: "#ec4899", accent: "#f472b6" },
];

interface SettingsState {
  theme: Theme;
  accentColor: AccentColor;
  language: string;
  setTheme: (theme: Theme) => void;
  setAccentColor: (accent: AccentColor) => void;
  setLanguage: (lang: string) => void;
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      theme: "dark",
      accentColor: "teal",
      language: "en",
      setTheme: (theme) => set({ theme }),
      setAccentColor: (accentColor) => set({ accentColor }),
      setLanguage: (language) => set({ language }),
    }),
    { name: "finar_settings" },
  ),
);
