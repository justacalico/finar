export function censorUrl(url: string): string {
  try {
    const u = new URL(url);
    const host = u.hostname;
    const dot = host.lastIndexOf(".");
    if (dot <= 0 || host.length <= 6) return `${u.protocol}//***`;
    const suffix = host.slice(dot);
    return `${u.protocol}//${host.slice(0, 3)}***${suffix}`;
  } catch {
    return "***";
  }
}
