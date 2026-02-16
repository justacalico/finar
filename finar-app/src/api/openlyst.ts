/**
 * OpenLyst API client for update checks.
 * @see https://openlyst.ink/docs/api
 */

const OPENLYST_BASE =
  import.meta.env.DEV ? "/api/openlyst" : "https://openlyst.ink/api/v1";
const APP_SLUG = "finar";

export interface OpenLystLatest {
  success: boolean;
  language: string;
  appName: string;
  appSlug: string;
  data: {
    version: string;
    date: string;
    platforms: string[];
    downloads?: Record<string, unknown>;
    sourceCode?: string;
  };
}

export interface UpdateCheckResult {
  latestVersion: string;
  isUpdateAvailable: boolean;
  releaseDate?: string;
  downloadUrl?: string;
  sourceCode?: string;
}

function compareVersions(a: string, b: string): number {
  const pa = a.split(".").map((n) => parseInt(n, 10) || 0);
  const pb = b.split(".").map((n) => parseInt(n, 10) || 0);
  const len = Math.max(pa.length, pb.length);
  for (let i = 0; i < len; i++) {
    const va = pa[i] ?? 0;
    const vb = pb[i] ?? 0;
    if (va > vb) return 1;
    if (va < vb) return -1;
  }
  return 0;
}

function getDownloadUrl(downloads: Record<string, unknown> | undefined): string | undefined {
  if (!downloads) return undefined;
  const platform =
    typeof navigator !== "undefined" && navigator.userAgent.includes("Win")
      ? "Windows"
      : typeof navigator !== "undefined" && navigator.userAgent.includes("Mac")
        ? "macOS"
        : typeof navigator !== "undefined" && navigator.userAgent.includes("Linux")
          ? "Linux"
          : "Web";
  const plat = downloads[platform];
  if (typeof plat === "string") return plat;
  if (plat && typeof plat === "object") {
    const w = plat as Record<string, unknown>;
    if (typeof w.zip === "object" && w.zip && typeof (w.zip as Record<string, string>).x86_64 === "string")
      return (w.zip as Record<string, string>).x86_64;
    if (typeof w.exe === "object" && w.exe && typeof (w.exe as Record<string, string>).x86_64 === "string")
      return (w.exe as Record<string, string>).x86_64;
    if (typeof w.web === "string") return w.web;
  }
  if (typeof downloads.Web === "string") return downloads.Web as string;
  return undefined;
}

/**
 * Check for updates via OpenLyst API.
 */
export async function checkForUpdate(
  currentVersion: string,
  lang = "en",
): Promise<UpdateCheckResult> {
  try {
    const langParam = lang === "zh-CN" ? "zh" : lang === "ru" ? "ru" : "en";
    const res = await fetch(
      `${OPENLYST_BASE}/apps/${APP_SLUG}/latest?lang=${langParam}`,
      { headers: { Accept: "application/json" } },
    );
    if (!res.ok) {
      return { latestVersion: currentVersion, isUpdateAvailable: false };
    }
    const json = (await res.json()) as OpenLystLatest;
    if (!json.success || !json.data) {
      return { latestVersion: currentVersion, isUpdateAvailable: false };
    }
    const latest = json.data.version;
    const isUpdateAvailable = compareVersions(latest, currentVersion) > 0;
    return {
      latestVersion: latest,
      isUpdateAvailable,
      releaseDate: json.data.date,
      downloadUrl: getDownloadUrl(json.data.downloads as Record<string, unknown>),
      sourceCode: json.data.sourceCode,
    };
  } catch {
    return { latestVersion: currentVersion, isUpdateAvailable: false };
  }
}
