import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { motion } from "framer-motion";
import { Play, Server, User, Lock, QrCode, Loader2, Sun, Globe, ChevronDown } from "lucide-react";
import { useAuthStore } from "../stores/auth";
import { useSettingsStore, type Theme } from "../stores/settings";
import { Button } from "../components/Button";

const THEMES: { id: Theme; label: string }[] = [
  { id: "light", label: "Light" },
  { id: "dark", label: "Dark" },
  { id: "oled", label: "OLED" },
];

const LANGUAGES = [
  { code: "en", label: "English" },
  { code: "zh-CN", label: "简体中文" },
  { code: "ru", label: "Русский" },
  { code: "de", label: "Deutsch" },
  { code: "fr", label: "Français" },
  { code: "es", label: "Español" },
];
import { Input } from "../components/Input";
import { GlassCard } from "../components/GlassCard";

export function Login() {
  const navigate = useNavigate();
  const {
    login,
    initiateQuickConnect,
    checkQuickConnect,
    isLoading,
    error,
    clearError,
    isAuthenticated,
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
      <div className="flex min-h-screen items-center justify-center bg-background p-4">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="w-full max-w-md"
        >
          <GlassCard padding="lg">
            <div className="flex flex-col items-center text-center">
              <div className="rounded-2xl bg-primary/20 p-4">
                <QrCode className="h-12 w-12 text-primary" />
              </div>
              <h2 className="mt-4 text-xl font-bold text-text-primary">
                Quick Connect
              </h2>
              <p className="mt-2 text-sm text-text-secondary">
                Enter this code in your Jellyfin dashboard
              </p>
              <div className="mt-6 rounded-xl bg-primary/10 px-8 py-4">
                <span className="font-mono text-3xl font-bold tracking-[0.3em] text-primary">
                  {quickConnectCode}
                </span>
              </div>
              <div className="mt-6 flex items-center gap-2 text-text-secondary">
                <Loader2 className="h-5 w-5 animate-spin" />
                <span>Waiting for authorization...</span>
              </div>
              <Button
                variant="outline"
                className="mt-8"
                onClick={() => {
                  setQuickConnectCode(null);
                  setQuickConnectPolling(false);
                }}
              >
                Cancel
              </Button>
            </div>
          </GlassCard>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute -right-20 -top-20 h-72 w-72 rounded-full bg-primary/20 blur-3xl" />
        <div className="absolute -bottom-32 -left-20 h-96 w-96 rounded-full bg-accent/10 blur-3xl" />
      </div>
      <div className="relative flex min-h-screen flex-col items-center justify-center p-4 md:flex-row md:gap-12">
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          className="mb-8 flex flex-col items-center md:mb-0 md:items-start"
        >
          <div className="flex h-20 w-20 items-center justify-center rounded-2xl bg-gradient-to-br from-primary to-accent shadow-xl shadow-primary/30">
            <Play className="h-10 w-10 text-background" fill="currentColor" />
          </div>
          <h1 className="mt-4 bg-gradient-to-r from-primary to-accent bg-clip-text text-4xl font-bold text-transparent">
            Finar
          </h1>
          <p className="mt-1 text-sm text-text-tertiary">
            Your Jellyfin Experience
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="w-full max-w-md"
        >
          <GlassCard padding="lg">
            <form onSubmit={handleSubmit} className="space-y-4">
              <h2 className="text-xl font-bold text-text-primary">Welcome</h2>
              <p className="text-sm text-text-secondary">
                Sign in to your Jellyfin server
              </p>

              <Input
                label="Server URL"
                placeholder="https://jellyfin.example.com"
                value={serverUrl}
                onChange={(e) => setServerUrl(e.target.value)}
                leftIcon={<Server className="h-5 w-5" />}
                required
              />
              <Input
                label="Username"
                placeholder="Enter your username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                leftIcon={<User className="h-5 w-5" />}
                required
              />
              <Input
                label="Password"
                type={showPassword ? "text" : "password"}
                placeholder="Enter your password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                leftIcon={<Lock className="h-5 w-5" />}
                rightIcon={
                  <button
                    type="button"
                    onClick={togglePasswordVisibility}
                    className="text-text-tertiary hover:text-text-primary"
                    aria-label={showPassword ? "Hide password" : "Show password"}
                  >
                    {showPassword ? "🙈" : "👁"}
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
                Sign In
              </Button>
              <Button
                type="button"
                variant="outline"
                className="w-full"
                onClick={handleQuickConnect}
                disabled={isLoading}
                leftIcon={<QrCode className="h-4 w-4" />}
              >
                Quick Connect
              </Button>

              <div className="flex flex-wrap items-center justify-between gap-4 border-t border-white/10 pt-4">
                <div>
                  <label className="mb-1.5 flex items-center gap-1.5 text-xs font-medium text-text-tertiary">
                    <Sun className="h-4 w-4" />
                    Theme
                  </label>
                  <div className="flex gap-1.5">
                    {THEMES.map((t) => (
                      <button
                        key={t.id}
                        type="button"
                        onClick={() => setTheme(t.id)}
                        className={`rounded-lg px-3 py-1.5 text-xs font-medium transition-colors ${
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
                <div className="min-w-0 flex-1 basis-32">
                  <label className="mb-1.5 flex items-center gap-1.5 text-xs font-medium text-text-tertiary">
                    <Globe className="h-4 w-4" />
                    Language
                  </label>
                  <DropdownMenu.Root>
                    <DropdownMenu.Trigger asChild>
                      <button
                        type="button"
                        className="flex w-full items-center justify-between gap-2 rounded-lg border border-divider bg-surface-elevated px-3 py-1.5 text-left text-sm text-text-primary transition-colors hover:bg-text-primary/5 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
                      >
                        <span className="truncate">
                          {LANGUAGES.find((l) => l.code === language)?.label ?? "English"}
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
            </form>
          </GlassCard>
        </motion.div>
      </div>
    </div>
  );
}
