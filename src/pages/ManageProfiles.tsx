import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import {
  ArrowLeft,
  Server,
  User,
  Lock,
  QrCode,
  Loader2,
  Eye,
  EyeOff,
  Trash2,
} from "lucide-react";
import { useAuthStore, type Profile } from "../stores/auth";
import { useTranslation } from "../translations";
import { getProfileAvatarUrl } from "../utils/image";
import { censorUrl } from "../utils/url";
import { Button } from "../components/Button";
import { Input } from "../components/Input";
import { GlassCard } from "../components/GlassCard";

const CONTAINER_CLASS =
  "relative w-full max-w-[min(32rem,94vw)] sm:max-w-[min(34rem,96vw)]";

function ProfileRow({
  profile,
  onRemove,
}: {
  profile: Profile;
  onRemove: (profile: Profile) => void;
}) {
  const { t } = useTranslation();
  const avatarUrl = getProfileAvatarUrl({
    serverUrl: profile.serverUrl,
    userId: profile.userId,
    primaryImageTag: profile.primaryImageTag,
  });
  const handleRemove = () => {
    const message = t("manageProfiles.removeConfirm", {
      name: profile.userName,
    });
    if (window.confirm(message)) onRemove(profile);
  };
  return (
    <div className="flex items-center gap-4 rounded-xl border border-white/10 bg-white/5 p-3 sm:p-4">
      <div className="flex h-12 w-12 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-surface-elevated sm:h-14 sm:w-14">
        {avatarUrl ? (
          <img
            src={avatarUrl}
            alt=""
            className="h-full w-full object-cover"
            referrerPolicy="no-referrer"
          />
        ) : (
          <User className="h-6 w-6 text-text-tertiary sm:h-7 sm:w-7" />
        )}
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate font-medium text-text-primary">
          {profile.userName}
        </p>
        <p className="truncate text-xs text-text-secondary sm:text-sm">
          {censorUrl(profile.serverUrl)}
        </p>
      </div>
      <Button
        type="button"
        variant="ghost"
        size="sm"
        className="text-error hover:bg-error/10 hover:text-error"
        leftIcon={<Trash2 className="h-4 w-4" />}
        onClick={handleRemove}
      >
        {t("manageProfiles.removeProfile")}
      </Button>
    </div>
  );
}

export function ManageProfiles() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const {
    profiles,
    removeProfile,
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
  const [quickConnectCode, setQuickConnectCode] = useState<string | null>(null);
  const [quickConnectPolling, setQuickConnectPolling] = useState(false);

  useEffect(() => {
    if (isAuthenticated && !quickConnectCode) navigate("/", { replace: true });
  }, [isAuthenticated, quickConnectCode, navigate]);

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
    if (ok) {
      setPassword("");
      navigate("/", { replace: true });
    }
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

  const togglePasswordVisibility = () => setShowPassword((p) => !p);

  if (quickConnectCode) {
    return (
      <div className="h-screen min-h-[100dvh] overflow-y-auto overflow-x-hidden bg-background">
        <div className="flex min-h-full min-h-[100dvh] flex-col items-center justify-center p-4 sm:p-6 pb-8">
          <div
            className="absolute inset-0 overflow-hidden pointer-events-none"
            aria-hidden
          >
            <div className="absolute left-1/2 top-1/2 h-[min(100vmax,32rem)] w-[min(100vmax,32rem)] -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary/15 blur-3xl" />
          </div>
          <motion.div
            initial={{ opacity: 0, scale: 0.98 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.2 }}
            className={CONTAINER_CLASS}
          >
            <GlassCard padding="lg" className="rounded-2xl shadow-xl">
              <Button
                type="button"
                variant="ghost"
                className="-ml-2 mb-3 sm:mb-4"
                leftIcon={<ArrowLeft className="h-4 w-4 shrink-0" />}
                onClick={() => {
                  setQuickConnectCode(null);
                  setQuickConnectPolling(false);
                  navigate("/profile-picker", { replace: true });
                }}
              >
                {t("common.goBack")}
              </Button>
              <div className="flex flex-col items-center text-center">
                <div className="rounded-2xl bg-primary/20 p-3 sm:p-4">
                  <QrCode className="h-10 w-10 sm:h-12 sm:w-12 text-primary" />
                </div>
                <h2 className="mt-3 sm:mt-4 text-lg font-semibold text-text-primary sm:text-xl">
                  {t("login.quickConnectTitle")}
                </h2>
                <p className="mt-1.5 sm:mt-2 text-xs text-text-secondary sm:text-sm">
                  {t("login.quickConnectEnterCode")}
                </p>
                <div className="mt-4 sm:mt-6 rounded-xl bg-primary/10 px-6 py-3 sm:px-8 sm:py-4">
                  <span className="font-mono text-2xl font-bold tracking-[0.2em] text-primary sm:text-3xl sm:tracking-[0.3em]">
                    {quickConnectCode}
                  </span>
                </div>
                <div className="mt-4 sm:mt-6 flex items-center gap-2 text-text-secondary text-sm">
                  <Loader2 className="h-4 w-4 sm:h-5 sm:w-5 animate-spin shrink-0" />
                  <span>{t("login.waitingForAuth")}</span>
                </div>
                <Button
                  variant="outline"
                  className="mt-6 sm:mt-8"
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
      </div>
    );
  }

  return (
    <div className="h-screen min-h-[100dvh] overflow-y-auto overflow-x-hidden bg-background">
      <div className="flex min-h-full min-h-[100dvh] flex-col items-center p-4 sm:p-6 md:p-8 pb-8">
        <div
          className="absolute inset-0 overflow-hidden pointer-events-none"
          aria-hidden
        >
          <div className="absolute left-1/2 top-1/2 h-[min(100vmax,40rem)] w-[min(100vmax,40rem)] -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary/12 blur-3xl" />
          <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-white/10 to-transparent" />
        </div>

        <div className={CONTAINER_CLASS}>
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.25, ease: [0.25, 0.46, 0.45, 0.94] }}
            className="flex flex-col"
          >
            <Button
              type="button"
              variant="ghost"
              className="-ml-2 mb-4 self-start"
              leftIcon={<ArrowLeft className="h-4 w-4 shrink-0" />}
              onClick={() => navigate("/profile-picker", { replace: true })}
            >
              {t("manageProfiles.backToPicker")}
            </Button>

            <h1 className="text-center text-2xl font-semibold text-text-primary sm:text-3xl">
              {t("manageProfiles.title")}
            </h1>

            {/* Existing profiles */}
            <section className="mt-6 sm:mt-8">
              {profiles.length === 0 ? (
                <p className="text-center text-sm text-text-secondary">
                  {t("manageProfiles.noProfilesYet")}
                </p>
              ) : (
                <div className="space-y-3">
                  {profiles.map((profile) => (
                    <ProfileRow
                      key={profile.id}
                      profile={profile}
                      onRemove={(p) => removeProfile(p.id)}
                    />
                  ))}
                </div>
              )}
            </section>

            {/* Add profile */}
            <section className="mt-8 sm:mt-10">
              <GlassCard padding="lg" className="rounded-2xl shadow-xl">
                <h2 className="text-lg font-semibold text-text-primary sm:text-xl">
                  {t("manageProfiles.addProfile")}
                </h2>
                <p className="mt-0.5 text-xs text-text-secondary sm:text-sm">
                  {t("manageProfiles.addNewAccount")}
                </p>
                <form
                  onSubmit={handleSubmit}
                  className="mt-4 space-y-4 sm:space-y-5"
                >
                  <Input
                    label={t("login.serverUrl")}
                    placeholder={t("login.serverUrlPlaceholder")}
                    value={serverUrl}
                    onChange={(e) => setServerUrl(e.target.value)}
                    leftIcon={<Server className="h-4 w-4 sm:h-5 sm:w-5" />}
                    required
                  />
                  <Input
                    label={t("login.username")}
                    placeholder={t("login.usernamePlaceholder")}
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    leftIcon={<User className="h-4 w-4 sm:h-5 sm:w-5" />}
                    required
                  />
                  <Input
                    label={t("login.password")}
                    type={showPassword ? "text" : "password"}
                    placeholder={t("login.passwordPlaceholder")}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    leftIcon={<Lock className="h-4 w-4 sm:h-5 sm:w-5" />}
                    rightIcon={
                      <button
                        type="button"
                        onClick={togglePasswordVisibility}
                        className="text-text-tertiary hover:text-text-primary"
                        aria-label={
                          showPassword
                            ? t("login.hidePassword")
                            : t("login.showPassword")
                        }
                      >
                        {showPassword ? (
                          <EyeOff className="h-4 w-4 sm:h-5 sm:w-5" />
                        ) : (
                          <Eye className="h-4 w-4 sm:h-5 sm:w-5" />
                        )}
                      </button>
                    }
                    required
                  />
                  {error && (
                    <div className="rounded-xl border border-error/30 bg-error/10 px-3 py-2.5 text-sm text-error sm:px-4 sm:py-3">
                      {error.includes(".") && t(error) !== error
                        ? t(error)
                        : error}
                    </div>
                  )}
                  <div className="flex flex-wrap gap-3">
                    <Button
                      type="submit"
                      loading={isLoading}
                      leftIcon={
                        !isLoading ? (
                          <Lock className="h-4 w-4" />
                        ) : undefined
                      }
                    >
                      {t("login.signIn")}
                    </Button>
                    <Button
                      type="button"
                      variant="outline"
                      onClick={handleQuickConnect}
                      disabled={isLoading}
                      leftIcon={<QrCode className="h-4 w-4" />}
                    >
                      {t("login.quickConnect")}
                    </Button>
                  </div>
                </form>
              </GlassCard>
            </section>
          </motion.div>
        </div>
      </div>
    </div>
  );
}
