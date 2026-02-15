import { useNavigate } from "react-router-dom";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { LogOut, User, Palette, Sun, Globe, Info, ChevronDown } from "lucide-react";
import { useAuthStore } from "../stores/auth";
import {
  useSettingsStore,
  ACCENT_COLORS,
  type Theme,
  type AccentColor,
} from "../stores/settings";
import { Button } from "../components/Button";

const THEMES: { id: Theme; label: string }[] = [
  { id: "light", label: "Light" },
  { id: "dark", label: "Dark" },
  { id: "oled", label: "OLED" },
];

const LANGUAGES = [
  { code: "en", label: "English" },
  { code: "de", label: "Deutsch" },
  { code: "fr", label: "Français" },
  { code: "es", label: "Español" },
];

export function Settings() {
  const navigate = useNavigate();
  const { user, serverUrl, logout } = useAuthStore();
  const theme = useSettingsStore((s) => s.theme);
  const setTheme = useSettingsStore((s) => s.setTheme);
  const accentColor = useSettingsStore((s) => s.accentColor);
  const setAccentColor = useSettingsStore((s) => s.setAccentColor);
  const language = useSettingsStore((s) => s.language);
  const setLanguage = useSettingsStore((s) => s.setLanguage);

  const handleSignOut = async () => {
    await logout();
    navigate("/login");
  };

  return (
    <div className="mx-auto max-w-2xl px-4 py-8 md:px-8">
      <h1 className="mb-8 text-2xl font-bold text-text-primary">Settings</h1>

      <div className="space-y-8">
        {/* Account */}
        <section className="rounded-2xl border border-white/10 bg-surface/50 p-6">
          <h2 className="mb-3 flex items-center gap-2 text-sm font-semibold uppercase tracking-wider text-text-tertiary">
            <User className="h-4 w-4" />
            Account
          </h2>
          <p className="text-text-primary">
            Signed in as <strong>{user?.Name ?? "Guest"}</strong>
          </p>
          {serverUrl && (
            <p className="mt-1 truncate text-sm text-text-tertiary">
              Server: {serverUrl}
            </p>
          )}
          <Button
            variant="outline"
            className="mt-4"
            leftIcon={<LogOut className="h-4 w-4" />}
            onClick={handleSignOut}
          >
            Sign out
          </Button>
        </section>

        {/* Customization */}
        <section className="rounded-2xl border border-white/10 bg-surface/50 p-6">
          <h2 className="mb-4 flex items-center gap-2 text-sm font-semibold uppercase tracking-wider text-text-tertiary">
            <Palette className="h-4 w-4" />
            Customization
          </h2>

          <div className="space-y-6">
            {/* Accent colour */}
            <div>
              <label className="mb-2 block text-sm font-medium text-text-secondary">
                Accent colour
              </label>
              <div className="flex flex-wrap gap-2">
                {ACCENT_COLORS.map((c) => (
                  <button
                    key={c.id}
                    type="button"
                    title={c.name}
                    onClick={() => setAccentColor(c.id as AccentColor)}
                    className={`h-9 w-9 rounded-full border-2 transition-transform hover:scale-110 ${
                      accentColor === c.id
                        ? "border-text-primary ring-2 ring-primary ring-offset-2 ring-offset-background"
                        : "border-transparent hover:border-white/30"
                    }`}
                    style={{
                      background: `linear-gradient(135deg, ${c.primary}, ${c.accent})`,
                    }}
                  />
                ))}
              </div>
            </div>

            {/* Theme */}
            <div>
              <label className="mb-2 flex items-center gap-2 text-sm font-medium text-text-secondary">
                <Sun className="h-4 w-4" />
                Theme
              </label>
              <div className="flex flex-wrap gap-2">
                {THEMES.map((t) => (
                  <button
                    key={t.id}
                    type="button"
                    onClick={() => setTheme(t.id)}
                    className={`rounded-xl px-4 py-2 text-sm font-medium transition-colors ${
                      theme === t.id
                        ? "bg-primary text-background"
                        : "bg-surface-elevated text-text-secondary hover:bg-white/10 hover:text-text-primary"
                    }`}
                  >
                    {t.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Language */}
            <div>
              <label className="mb-2 flex items-center gap-2 text-sm font-medium text-text-secondary">
                <Globe className="h-4 w-4" />
                Language
              </label>
              <DropdownMenu.Root>
                <DropdownMenu.Trigger asChild>
                  <button
                    type="button"
                    className="flex w-full items-center justify-between gap-2 rounded-xl border border-divider bg-surface-elevated px-4 py-3 text-left text-text-primary transition-colors hover:bg-text-primary/5 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                  >
                    <span>{LANGUAGES.find((l) => l.code === language)?.label ?? "English"}</span>
                    <ChevronDown className="h-4 w-4 shrink-0 text-text-tertiary" />
                  </button>
                </DropdownMenu.Trigger>
                <DropdownMenu.Portal>
                  <DropdownMenu.Content
                    className="min-w-[var(--radix-dropdown-menu-trigger-width)] rounded-xl border border-divider bg-surface shadow-lg"
                    sideOffset={4}
                    align="start"
                  >
                    {LANGUAGES.map((l) => (
                      <DropdownMenu.Item
                        key={l.code}
                        onSelect={() => setLanguage(l.code)}
                        className="cursor-pointer select-none px-4 py-2.5 text-text-primary outline-none hover:bg-text-primary/5 focus:outline-none data-[highlighted]:bg-text-primary/5"
                      >
                        {l.label}
                      </DropdownMenu.Item>
                    ))}
                  </DropdownMenu.Content>
                </DropdownMenu.Portal>
              </DropdownMenu.Root>
            </div>
          </div>
        </section>

        {/* About */}
        <section className="rounded-2xl border border-white/10 bg-surface/50 p-6">
          <h2 className="mb-3 flex items-center gap-2 text-sm font-semibold uppercase tracking-wider text-text-tertiary">
            <Info className="h-4 w-4" />
            About
          </h2>
          <p className="text-text-secondary">
            Finar — A beautiful Jellyfin client. Built with Tauri, React, and
            TypeScript.
          </p>
        </section>
      </div>
    </div>
  );
}
