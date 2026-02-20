import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { motion } from "framer-motion";
import { Play, Server, User, Lock, QrCode, Loader2, Sun, Globe, ChevronDown, Eye, EyeOff, ArrowLeft } from "lucide-react";
import { useAuthStore } from "../stores/auth";
import { useSettingsStore } from "../stores/settings";
import { useTranslation, SUPPORTED_LANGUAGES } from "../translations";
import { Button } from "../components/Button";
import { Input } from "../components/Input";
import { GlassCard } from "../components/GlassCard";

const THEME_IDS = ["light", "dark", "oled"] as const;

export function Login() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const {
    login,
    initiateQuickConnect,
    checkQuickConnect,
    isLoading,
    error,
    clearError,
    isAuthenticated,
    profiles,
  } = useAuthStore();

  const [serverUrl, setServerUrl] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const togglePasswordVisibility = () => setShowPassword((p) => !p);
  const [quickConnectCode, setQuickConnectCode] = useState<string | null>(null);
  const [quickConnectPolling, setQuickConnectPolling] = useState(false);

  const theme = useSettingsStore((s) => s.theme);
  const setTheme = useSettingsStore((s) => s.setTheme);
  const language = useSettingsStore((s) => s.language);
  const setLanguage = useSettingsStore((s) => s.setLanguage);

  useEffect(() => {
    if (isAuthenticated) navigate("/", { replace: true });
  }, [isAuthenticated, navigate]);

  useEffect(() => {
    if (!quickConnectCode || !quickConnectPolling) return;
    const id = setInterval(async () => {
      const ok = await checkQuickConnect(quickConnectCode);
      if (ok) {
        setQuickConnectPolling(false);
        setQuickConnectCode(null);
        navigate("/", { replace: true });
      }
    }, 2000);
    const timeout = setTimeout(() => {
      setQuickConnectPolling(false);
      setQuickConnectCode(null);
    }, 5 * 60 * 1000);
    return () => {
      clearInterval(id);
      clearTimeout(timeout);
    };
  }, [quickConnectCode, quickConnectPolling, checkQuickConnect, navigate]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    clearError();
    const ok = await login(serverUrl.trim(), username.trim(), password);
    if (ok) navigate("/", { replace: true });
  };

  const handleQuickConnect = async () => {
    if (!serverUrl.trim()) return;
    clearError();
    const code = await initiateQuickConnect(serverUrl.trim());
    if (code) {
      setQuickConnectCode(code);
      setQuickConnectPolling(true);
    }
  };

  if (quickConnectCode) {
    return (
      <div className="login-page flex min-h-screen items-center justify-center bg-background p-4">
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute left-1/2 top-1/2 h-[480px] w-[480px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary/15 blur-3xl" />
        </div>
        <motion.div
          initial={{ opacity: 0, scale: 0.96 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.25 }}
          className="relative w-full max-w-md"
        >
          <GlassCard padding="lg" className="login-form-card">
            {profiles.length > 0 && (
              <Button
                type="button"
                variant="ghost"
                className="-ml-2 mb-4"
                leftIcon={<ArrowLeft className="h-4 w-4" />}
                onClick={() => {
                  setQuickConnectCode(null);
                  setQuickConnectPolling(false);
                  navigate("/profile-picker", { replace: true });
                }}
              >
                {t("common.goBack")}
              </Button>
            )}
            <div className="flex flex-col items-center text-center">
              <div className="rounded-2xl bg-primary/20 p-4">
                <QrCode className="h-12 w-12 text-primary" />
              </div>
              <h2 className="login-brand mt-4 text-xl font-semibold text-text-primary">
                {t("login.quickConnectTitle")}
              </h2>
              <p className="mt-2 text-sm text-text-secondary">
                {t("login.quickConnectEnterCode")}
              </p>
              <div className="mt-6 rounded-xl bg-primary/10 px-8 py-4">
                <span className="font-mono text-3xl font-bold tracking-[0.3em] text-primary">
                  {quickConnectCode}
                </span>
              </div>
              <div className="mt-6 flex items-center gap-2 text-text-secondary">
                <Loader2 className="h-5 w-5 animate-spin" />
                <span>{t("login.waitingForAuth")}</span>
              </div>
              <Button
                variant="outline"
                className="mt-8"
                onClick={() => {
                  setQuickConnectCode(null);
                  setQuickConnectPolling(false);
                }}
              >
                {t("login.cancel")}
              </Button>
            </div>
          </GlassCard>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="login-page min-h-screen bg-background">
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div
          className="absolute left-1/2 top-1/2 h-[min(100vmax,720px)] w-[min(100vmax,720px)] -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary/12 blur-3xl"
          aria-hidden
        />
        <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-white/10 to-transparent" aria-hidden />
      </div>
      <div className="relative flex min-h-screen flex-col items-center justify-center p-6 md:flex-row md:gap-16 md:p-8">
        <motion.div
          initial={{ opacity: 0, x: -24 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.35, ease: [0.25, 0.46, 0.45, 0.94] }}
          className="login-brand mb-10 flex flex-col items-center md:mb-0 md:items-start"
        >
          <div className="flex h-24 w-24 items-center justify-center rounded-2xl bg-gradient-to-br from-primary to-accent shadow-xl shadow-primary/25 ring-2 ring-white/10">
            <Play className="h-12 w-12 text-background" fill="currentColor" />
          </div>
          <h1 className="mt-5 bg-gradient-to-r from-primary to-accent bg-clip-text text-4xl font-semibold tracking-tight text-transparent md:text-5xl">
            {t("common.appName")}
          </h1>
          <p className="mt-1.5 text-sm text-text-tertiary">
            {t("common.tagline")}
          </p>
          <div className="mt-8 hidden h-px w-12 bg-gradient-to-r from-primary/50 to-transparent md:block" aria-hidden />
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.08, duration: 0.35, ease: [0.25, 0.46, 0.45, 0.94] }}
          className="w-full max-w-[420px]"
        >
          <GlassCard padding="lg" className="login-form-card">
            {profiles.length > 0 && (
              <Button
                type="button"
                variant="ghost"
                className="-ml-2 mb-2"
                leftIcon={<ArrowLeft className="h-4 w-4" />}
                onClick={() => navigate("/profile-picker", { replace: true })}
              >
                {t("common.goBack")}
              </Button>
            )}
            <form onSubmit={handleSubmit} className="space-y-5">
              <div>
                <h2 className="login-brand text-2xl font-semibold tracking-tight text-text-primary">
                  {t("login.welcome")}
                </h2>
                <p className="mt-1 text-sm text-text-secondary">
                  {t("login.signInTo")}
                </p>
              </div>

              <Input
                label={t("login.serverUrl")}
                placeholder={t("login.serverUrlPlaceholder")}
                value={serverUrl}
                onChange={(e) => setServerUrl(e.target.value)}
                leftIcon={<Server className="h-5 w-5" />}
                required
              />
              <Input
                label={t("login.username")}
                placeholder={t("login.usernamePlaceholder")}
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                leftIcon={<User className="h-5 w-5" />}
                required
              />
              <Input
                label={t("login.password")}
                type={showPassword ? "text" : "password"}
                placeholder={t("login.passwordPlaceholder")}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                leftIcon={<Lock className="h-5 w-5" />}
                rightIcon={
                  <button
                    type="button"
                    onClick={togglePasswordVisibility}
                    className="text-text-tertiary hover:text-text-primary"
                    aria-label={showPassword ? t("login.hidePassword") : t("login.showPassword")}
                  >
                    {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                  </button>
                }
                required
              />

              {error && (
                <div className="rounded-xl border border-error/30 bg-error/10 px-4 py-3 text-sm text-error">
                  {error}
                </div>
              )}

              <Button
                type="submit"
                loading={isLoading}
                className="w-full"
                leftIcon={!isLoading ? <Lock className="h-4 w-4" /> : undefined}
              >
                {t("login.signIn")}
              </Button>
              <Button
                type="button"
                variant="outline"
                className="w-full"
                onClick={handleQuickConnect}
                disabled={isLoading}
                leftIcon={<QrCode className="h-4 w-4" />}
              >
                {t("login.quickConnect")}
              </Button>

              <div className="flex flex-wrap items-end justify-between gap-4 border-t border-white/10 pt-5">
                <div>
                  <span className="mb-2 flex items-center gap-1.5 text-xs font-medium text-text-tertiary">
                    <Sun className="h-3.5 w-3.5" />
                    {t("common.theme")}
                  </span>
                  <div className="flex gap-1.5">
                    {THEME_IDS.map((id) => (
                      <button
                        key={id}
                        type="button"
                        onClick={() => setTheme(id)}
                        className={`rounded-lg px-2.5 py-1.5 text-xs font-medium transition-colors ${
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
                <div className="min-w-0 flex-1 basis-28">
                  <span className="mb-2 flex items-center gap-1.5 text-xs font-medium text-text-tertiary">
                    <Globe className="h-3.5 w-3.5" />
                    {t("common.language")}
                  </span>
                  <DropdownMenu.Root>
                    <DropdownMenu.Trigger asChild>
                      <button
                        type="button"
                        className="flex w-full items-center justify-between gap-2 rounded-lg border border-divider bg-surface-elevated px-3 py-1.5 text-left text-sm text-text-primary transition-colors hover:bg-text-primary/5 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                      >
                        <span className="truncate">
                          {SUPPORTED_LANGUAGES.find((l) => l.code === language)?.label ?? "English"}
                        </span>
                        <ChevronDown className="h-4 w-4 shrink-0 text-text-tertiary" />
                      </button>
                    </DropdownMenu.Trigger>
                    <DropdownMenu.Portal>
                      <DropdownMenu.Content
                        className="min-w-[var(--radix-dropdown-menu-trigger-width)] rounded-xl border border-divider bg-surface shadow-lg"
                        sideOffset={4}
                        align="end"
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
            </form>
          </GlassCard>
        </motion.div>
      </div>
    </div>
  );
}
