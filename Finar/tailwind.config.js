/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./App.{js,jsx,ts,tsx}",
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        finar: {
          bg: "#0D0D0F",
          "bg-secondary": "#141416",
          surface: "#1A1A1E",
          "surface-elevated": "#242428",
          glass: "rgba(255,255,255,0.08)",
          "glass-border": "rgba(255,255,255,0.16)",
          primary: "#00E5B8",
          "primary-muted": "#00997A",
          accent: "#00B8D9",
          secondary: "#9D7EF7",
          "text-primary": "#FAFAFA",
          "text-secondary": "#B0B0B0",
          "text-tertiary": "#707070",
          "text-on-primary": "#0D0D0F",
          divider: "#2A2A2E",
          error: "#FF6B6B",
          success: "#2DD4BF",
          warning: "#FBBF24",
        },
      },
      fontFamily: {
        display: ["Outfit_600SemiBold", "Outfit_500Medium", "system-ui"],
        body: ["Outfit_400Regular", "system-ui"],
      },
      borderRadius: {
        "finar-sm": "8px",
        "finar-md": "12px",
        "finar-lg": "16px",
        "finar-xl": "20px",
      },
      boxShadow: {
        "finar-glow": "0 0 24px -4px rgba(0, 229, 184, 0.35)",
        "finar-card": "0 4px 24px -4px rgba(0,0,0,0.4)",
      },
    },
  },
  plugins: [],
};
