import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { User, UserPlus } from "lucide-react";
import { useAuthStore, type Profile } from "../stores/auth";
import { getProfileAvatarUrl } from "../utils/image";
import { useTranslation } from "../translations";
import { Button } from "../components/Button";

function ProfileCard({
  profile,
  onSelect,
}: {
  profile: Profile;
  onSelect: (profileId: string) => Promise<boolean>;
}) {
  const [switching, setSwitching] = useState(false);
  const avatarUrl = getProfileAvatarUrl({
    serverUrl: profile.serverUrl,
    userId: profile.userId,
    primaryImageTag: profile.primaryImageTag,
  });

  const handleClick = async () => {
    setSwitching(true);
    try {
      await onSelect(profile.id);
    } finally {
      setSwitching(false);
    }
  };

  return (
    <motion.button
      type="button"
      onClick={handleClick}
      disabled={switching}
      className="group flex flex-col items-center gap-3 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-background disabled:opacity-60"
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.2 }}
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
    >
      <div className="relative flex h-24 w-24 items-center justify-center overflow-hidden rounded-xl border-2 border-white/20 bg-surface-elevated ring-2 ring-white/5 transition-all group-hover:border-primary/50 group-hover:ring-primary/30 group-focus:border-primary group-focus:ring-primary/50 md:h-28 md:w-28">
        {avatarUrl ? (
          <img
            src={avatarUrl}
            alt=""
            className="h-full w-full object-cover"
            referrerPolicy="no-referrer"
          />
        ) : (
          <User className="h-12 w-12 text-text-tertiary md:h-14 md:w-14" />
        )}
      </div>
      <span className="max-w-[120px] truncate text-center text-sm font-medium text-text-primary md:max-w-[140px]">
        {profile.userName}
      </span>
    </motion.button>
  );
}

export function ProfilePicker() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const profiles = useAuthStore((s) => s.profiles);
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const switchProfile = useAuthStore((s) => s.switchProfile);
  const error = useAuthStore((s) => s.error);
  const clearError = useAuthStore((s) => s.clearError);

  useEffect(() => {
    if (profiles.length === 0) navigate("/login", { replace: true });
  }, [profiles.length, navigate]);
  useEffect(() => {
    if (isAuthenticated) navigate("/", { replace: true });
  }, [isAuthenticated, navigate]);

  const handleSelect = async (profileId: string) => {
    clearError();
    const ok = await switchProfile(profileId);
    if (ok) navigate("/", { replace: true });
    return ok;
  };

  const handleManageProfiles = () => {
    clearError();
    navigate("/login", { replace: true });
  };

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background p-6">
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div
          className="absolute left-1/2 top-1/2 h-[min(100vmax,720px)] w-[min(100vmax,720px)] -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary/12 blur-3xl"
          aria-hidden
        />
      </div>
      <div className="relative flex w-full max-w-2xl flex-col items-center">
        <motion.h1
          className="text-center text-3xl font-semibold text-text-primary md:text-4xl"
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.25 }}
        >
          {t("profilePicker.whoIsWatching")}
        </motion.h1>
        {error && (
          <div className="mt-4 flex max-w-md flex-col items-center gap-3 rounded-xl border border-error/30 bg-error/10 px-4 py-3 text-center text-sm text-error">
            <span>{error.startsWith("profilePicker.") ? t(error) : error}</span>
            <Button
              variant="primary"
              size="sm"
              onClick={handleManageProfiles}
            >
              {t("profilePicker.signInAgain")}
            </Button>
          </div>
        )}
        <motion.div
          className="mt-10 flex flex-wrap justify-center gap-8 md:gap-12"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.08, duration: 0.25 }}
        >
          {profiles.map((profile, i) => (
            <motion.div
              key={profile.id}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.05 * i, duration: 0.2 }}
            >
              <ProfileCard profile={profile} onSelect={handleSelect} />
            </motion.div>
          ))}
        </motion.div>
        <motion.div
          className="mt-12"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.15, duration: 0.2 }}
        >
          <Button
            variant="outline"
            leftIcon={<UserPlus className="h-4 w-4" />}
            onClick={handleManageProfiles}
          >
            {t("profilePicker.manageProfiles")}
          </Button>
        </motion.div>
      </div>
    </div>
  );
}
