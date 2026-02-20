import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { LogOut, User, UserCircle, Palette, Sun, Globe, Info, ChevronDown, ChevronRight, ExternalLink, RefreshCw, Heart, Lock } from "lucide-react";
import { useAuthStore } from "../stores/auth";
import pkg from "../../package.json";
import {
  useSettingsStore,
  ACCENT_COLORS,
  type Theme,
  type AccentColor,
} from "../stores/settings";
import { useUpdateStore } from "../stores/update";
import { useTranslation, SUPPORTED_LANGUAGES } from "../translations";
import { censorUrl } from "../utils/url";
import { Button } from "../components/Button";

const THEME_IDS: Theme[] = ["light", "dark", "oled"];

export function Settings() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { user, serverUrl, logout, goToProfilePicker, profiles } = useAuthStore();
  const theme = useSettingsStore((s) => s.theme);
  const setTheme = useSettingsStore((s) => s.setTheme);
  const accentColor = useSettingsStore((s) => s.accentColor);
  const setAccentColor = useSettingsStore((s) => s.setAccentColor);
  const language = useSettingsStore((s) => s.language);
  const setLanguage = useSettingsStore((s) => s.setLanguage);

  const lastChecked = useUpdateStore((s) => s.lastChecked);
  const latestVersion = useUpdateStore((s) => s.latestVersion);
  const isUpdateAvailable = useUpdateStore((s) => s.isUpdateAvailable);
  const downloadUrl = useUpdateStore((s) => s.downloadUrl);
  const checkingUpdate = useUpdateStore((s) => s.checking);
  const checkForUpdates = useUpdateStore((s) => s.check);

  const updateCheck =
    lastChecked === null
      ? null
      : { latestVersion, isUpdateAvailable, downloadUrl };

  // Re-run background check when language changes so messages/URLs match
  useEffect(() => {
    checkForUpdates();
  }, [language, checkForUpdates]);

  const handleSignOut = async () => {
    await logout();
    navigate(profiles.length > 0 ? "/profile-picker" : "/login");
  };

  const handleSwitchProfile = () => {
    goToProfilePicker();
    navigate("/profile-picker");
  };

  return (
    <div className="mx-auto max-w-2xl px-4 py-8 md:px-8">
      <h1 className="mb-8 text-2xl font-bold text-text-primary">{t("settings.title")}</h1>

      <div className="space-y-8">
        {/* Account */}
        <section className="rounded-2xl border border-white/10 bg-surface/50 p-6">
          <h2 className="mb-3 flex items-center gap-2 text-sm font-semibold uppercase tracking-wider text-text-tertiary">
            <User className="h-4 w-4" />
            {t("settings.account")}
          </h2>
          <p className="text-text-primary">
            {t("settings.signedInAs")} <strong>{user?.Name ?? t("common.guest")}</strong>
          </p>
          {serverUrl && (
            <p className="mt-1 truncate text-sm text-text-tertiary">
              {t("settings.server")}: {censorUrl(serverUrl)}
            </p>
          )}
          <div className="mt-4 flex flex-wrap gap-3">
            {profiles.length > 0 && (
              <Button
                variant="outline"
                leftIcon={<UserCircle className="h-4 w-4" />}
                onClick={handleSwitchProfile}
              >
                {t("settings.switchProfile")}
              </Button>
            )}
            <Button
              variant="outline"
              leftIcon={<LogOut className="h-4 w-4" />}
              onClick={handleSignOut}
            >
              {t("settings.signOut")}
            </Button>
          </div>
        </section>

        {/* Customization */}
        <section className="rounded-2xl border border-white/10 bg-surface/50 p-6">
          <h2 className="mb-4 flex items-center gap-2 text-sm font-semibold uppercase tracking-wider text-text-tertiary">
            <Palette className="h-4 w-4" />
            {t("settings.customization")}
          </h2>

          <div className="space-y-6">
            {/* Accent colour */}
            <div>
              <label className="mb-2 block text-sm font-medium text-text-secondary">
                {t("settings.accentColour")}
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
                {t("settings.theme")}
              </label>
              <div className="flex flex-wrap gap-2">
                {THEME_IDS.map((id) => (
                  <button
                    key={id}
                    type="button"
                    onClick={() => setTheme(id)}
                    className={`rounded-xl px-4 py-2 text-sm font-medium transition-colors ${
                      theme === id
                        ? "bg-primary text-background"
                        : "bg-surface-elevated text-text-secondary hover:bg-white/10 hover:text-text-primary"
                    }`}
                  >
                    {t(`common.${id}`)}
                  </button>
                ))}
              </div>
            </div>

            {/* Language */}
            <div>
              <label className="mb-2 flex items-center gap-2 text-sm font-medium text-text-secondary">
                <Globe className="h-4 w-4" />
                {t("settings.language")}
              </label>
              <DropdownMenu.Root>
                <DropdownMenu.Trigger asChild>
                  <button
                    type="button"
                    className="flex w-full items-center justify-between gap-2 rounded-xl border border-divider bg-surface-elevated px-4 py-3 text-left text-text-primary transition-colors hover:bg-text-primary/5 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                  >
                    <span>{SUPPORTED_LANGUAGES.find((l) => l.code === language)?.label ?? "English"}</span>
                    <ChevronDown className="h-4 w-4 shrink-0 text-text-tertiary" />
                  </button>
                </DropdownMenu.Trigger>
                <DropdownMenu.Portal>
                  <DropdownMenu.Content
                    className="min-w-[var(--radix-dropdown-menu-trigger-width)] rounded-xl border border-divider bg-surface shadow-lg"
                    sideOffset={4}
                    align="start"
                  >
                    {SUPPORTED_LANGUAGES.map((l) => (
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
          <h2 className="mb-4 flex items-center gap-2 text-sm font-semibold uppercase tracking-wider text-text-tertiary">
            <Info className="h-4 w-4" />
            {t("settings.about")}
          </h2>
          <p className="mb-4 text-sm text-text-secondary">
            {t("settings.aboutDescription")}
          </p>
          <div className="overflow-hidden rounded-xl border border-white/10 bg-surface-elevated/50">
            {/* Version row */}
            <div className="flex items-center gap-4 px-4 py-3">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-blue-500/20 text-blue-400">
                <Info className="h-5 w-5" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-medium text-text-primary">{t("settings.version")}</p>
              </div>
              <span className="text-sm text-text-tertiary">{pkg.version}</span>
            </div>
            <div className="border-t border-white/10" />
            {/* Check for updates row — label shows status */}
            <button
              type="button"
              onClick={() => checkForUpdates()}
              disabled={checkingUpdate}
              className="flex w-full items-center gap-4 px-4 py-3 text-left transition-colors hover:bg-white/5 disabled:opacity-60"
            >
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-violet-500/20 text-violet-400">
                <RefreshCw className={`h-5 w-5 ${checkingUpdate ? "animate-spin" : ""}`} />
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-medium text-text-primary">
                  {checkingUpdate
                    ? t("settings.checkingUpdates")
                    : updateCheck?.isUpdateAvailable
                      ? t("settings.updateAvailable")
                      : updateCheck
                        ? t("settings.upToDate")
                        : t("settings.checkForUpdates")}
                </p>
                {!checkingUpdate && !updateCheck && (
                  <p className="text-xs text-text-tertiary">{t("settings.checkForUpdatesDescription")}</p>
                )}
              </div>
              <ChevronRight className="h-5 w-5 shrink-0 text-text-tertiary" />
            </button>
            <div className="border-t border-white/10" />
            {/* Visit OpenLyst row */}
            <button
              type="button"
              onClick={() => window.open("https://openlyst.ink/", "_blank", "noopener,noreferrer")}
              className="flex w-full items-center gap-4 px-4 py-3 text-left transition-colors hover:bg-white/5"
            >
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-amber-500/20 text-amber-400">
                <Globe className="h-5 w-5" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-medium text-text-primary">{t("settings.visitOpenLyst")}</p>
              </div>
              <ChevronRight className="h-5 w-5 shrink-0 text-text-tertiary" />
            </button>
            <div className="border-t border-white/10" />
            {/* Support OpenLyst row */}
            <button
              type="button"
              onClick={() => window.open("https://openlyst.ink/support", "_blank", "noopener,noreferrer")}
              className="flex w-full items-center gap-4 px-4 py-3 text-left transition-colors hover:bg-white/5"
            >
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-rose-500/20 text-rose-400">
                <Heart className="h-5 w-5" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-medium text-text-primary">{t("settings.supportOpenLyst")}</p>
              </div>
              <ChevronRight className="h-5 w-5 shrink-0 text-text-tertiary" />
            </button>
            <div className="border-t border-white/10" />
            {/* Privacy Policy row */}
            <button
              type="button"
              onClick={() => window.open("https://gitlab.com/Openlyst/finar/-/blob/main/PRIVACY.md", "_blank", "noopener,noreferrer")}
              className="flex w-full items-center gap-4 px-4 py-3 text-left transition-colors hover:bg-white/5"
            >
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-emerald-500/20 text-emerald-400">
                <Lock className="h-5 w-5" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-medium text-text-primary">{t("settings.privacyPolicy")}</p>
              </div>
              <ChevronRight className="h-5 w-5 shrink-0 text-text-tertiary" />
            </button>
          </div>
          {updateCheck?.isUpdateAvailable && (
            <div className="mt-4 rounded-xl bg-primary/10 px-4 py-3">
              <p className="font-medium text-primary">
                {t("settings.updateAvailable")}: v{updateCheck.latestVersion}
              </p>
              {updateCheck.downloadUrl && (
                <a
                  href={updateCheck.downloadUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-2 inline-flex items-center gap-1.5 text-sm font-medium text-primary hover:underline"
                >
                  <ExternalLink className="h-4 w-4" />
                  {t("settings.downloadFromOpenLyst")}
                </a>
              )}
            </div>
          )}
        </section>
      </div>
    </div>
  );
}
