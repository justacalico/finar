import { Download } from "lucide-react";

export function Downloads() {
  return (
    <div className="flex min-h-[50vh] flex-col items-center justify-center gap-4 px-4">
      <Download className="h-16 w-16 text-text-tertiary/50" />
      <h2 className="text-xl font-semibold text-text-primary">Downloads</h2>
      <p className="max-w-sm text-center text-sm text-text-tertiary">
        Downloaded content will appear here. This feature can be added later with
        Tauri file system APIs.
      </p>
    </div>
  );
}
