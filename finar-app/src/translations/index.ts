import { useCallback } from "react";
import { useSettingsStore } from "../stores/settings";
import en from "./en.json";
import zhCN from "./zh-CN.json";
import ru from "./ru.json";

export type Locale = "en" | "zh-CN" | "ru";

const messages: Record<Locale, Record<string, unknown>> = {
  en: en as Record<string, unknown>,
  "zh-CN": zhCN as Record<string, unknown>,
  ru: ru as Record<string, unknown>,
};

function get(obj: Record<string, unknown>, path: string): string | undefined {
  const keys = path.split(".");
  let current: unknown = obj;
  for (const key of keys) {
    if (current == null || typeof current !== "object") return undefined;
    current = (current as Record<string, unknown>)[key];
  }
  return typeof current === "string" ? current : undefined;
}

export const SUPPORTED_LANGUAGES: { code: Locale; label: string }[] = [
  { code: "en", label: "English" },
  { code: "zh-CN", label: "简体中文" },
  { code: "ru", label: "Русский" },
];

export function useTranslation() {
  const language = useSettingsStore((s) => s.language);
  const locale: Locale =
    language === "zh-CN" || language === "ru" ? language : "en";

  const t = useCallback(
    (key: string): string => {
      const dict = messages[locale];
      const value = get(dict, key);
      if (value != null) return value;
      const fallback = get(messages.en as Record<string, unknown>, key);
      return fallback ?? key;
    },
    [locale],
  );

  return { t, locale };
}
