/**
 * Syncs version from package.json to tauri.conf.json.
 * Run before Tauri builds so the native app version matches.
 */
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, "..");
const pkg = JSON.parse(readFileSync(join(root, "package.json"), "utf-8"));
const version = pkg.version;
const tauriPath = join(root, "src-tauri", "tauri.conf.json");
const tauri = JSON.parse(readFileSync(tauriPath, "utf-8"));
if (tauri.version !== version) {
  tauri.version = version;
  writeFileSync(tauriPath, JSON.stringify(tauri, null, 2) + "\n");
  console.log(`Synced version to tauri.conf.json: ${version}`);
}
