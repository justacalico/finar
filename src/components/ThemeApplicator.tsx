import { useEffect } from "react";
import { useSettingsStore, ACCENT_COLORS } from "../stores/settings";

export function ThemeApplicator() {
  const theme = useSettingsStore((s) => s.theme);
  const accentColor = useSettingsStore((s) => s.accentColor);
  const customAccentHex = useSettingsStore((s) => s.customAccentHex);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    if (accentColor === "custom") {
      const hex = /^#[0-9A-Fa-f]{6}$/.test(customAccentHex) ? customAccentHex : "#00e5b8";
      document.documentElement.style.setProperty("--color-primary", hex);
      document.documentElement.style.setProperty("--color-accent", hex);
    } else {
      const entry = ACCENT_COLORS.find((c) => c.id === accentColor);
      if (entry) {
        document.documentElement.style.setProperty("--color-primary", entry.primary);
        document.documentElement.style.setProperty("--color-accent", entry.accent);
      }
    }
  }, [theme, accentColor, customAccentHex]);

  return null;
}
