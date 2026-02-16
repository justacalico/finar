/**
 * Syncs APP_VERSION from src/version.ts to tauri.conf.json.
 * Run before Tauri builds so the native app version matches the frontend.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, "..");
const versionTs = readFileSync(join(root, "src", "version.ts"), "utf-8");
const match = versionTs.match(/APP_VERSION\s*=\s*["']([^"']+)["']/);
if (!match) {
  console.error("Could not find APP_VERSION in src/version.ts");
  process.exit(1);
}
const version = match[1];
const tauriPath = join(root, "src-tauri", "tauri.conf.json");
const tauri = JSON.parse(readFileSync(tauriPath, "utf-8"));
if (tauri.version !== version) {
  tauri.version = version;
  writeFileSync(tauriPath, JSON.stringify(tauri, null, 2) + "\n");
  console.log(`Synced version to tauri.conf.json: ${version}`);
}
