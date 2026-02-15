import { useAuthStore } from "../stores/auth";

export function Settings() {
  const { user, serverUrl } = useAuthStore();

  return (
    <div className="mx-auto max-w-2xl px-4 py-8 md:px-8">
      <h1 className="mb-8 text-2xl font-bold text-text-primary">Settings</h1>
      <div className="space-y-6 rounded-2xl border border-white/10 bg-surface/50 p-6">
        <section>
          <h2 className="mb-2 text-sm font-semibold uppercase tracking-wider text-text-tertiary">
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
