import { useNavigate } from "react-router-dom";
import { LogOut } from "lucide-react";
import { useAuthStore } from "../stores/auth";
import { Button } from "../components/Button";

export function Settings() {
  const navigate = useNavigate();
  const { user, serverUrl, logout } = useAuthStore();

  const handleSignOut = async () => {
    await logout();
    navigate("/login");
  };

  return (
    <div className="mx-auto max-w-2xl px-4 py-8 md:px-8">
      <h1 className="mb-8 text-2xl font-bold text-text-primary">Settings</h1>
      <div className="space-y-6 rounded-2xl border border-white/10 bg-surface/50 p-6">
        <section>
          <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider text-text-tertiary">
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
        <section>
          <h2 className="mb-2 text-sm font-semibold uppercase tracking-wider text-text-tertiary">
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
