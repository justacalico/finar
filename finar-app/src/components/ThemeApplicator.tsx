import { useEffect } from "react";
import { useSettingsStore, ACCENT_COLORS } from "../stores/settings";

export function ThemeApplicator() {
  const theme = useSettingsStore((s) => s.theme);
  const accentColor = useSettingsStore((s) => s.accentColor);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    const entry = ACCENT_COLORS.find((c) => c.id === accentColor);
    if (entry) {
      document.documentElement.style.setProperty("--color-primary", entry.primary);
      document.documentElement.style.setProperty("--color-accent", entry.accent);
    }
  }, [theme, accentColor]);

  return null;
}
