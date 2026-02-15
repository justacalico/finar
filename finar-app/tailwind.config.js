/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        background: "#0D0D0F",
        "background-secondary": "#141416",
        surface: "#1A1A1E",
        "surface-elevated": "#242428",
        primary: "#00E5B8",
        "primary-dark": "#00B894",
        accent: "#00B8D9",
        secondary: "#9D7EF7",
        "text-primary": "#FAFAFA",
        "text-secondary": "#B0B0B0",
        "text-tertiary": "#707070",
        divider: "#2A2A2E",
        error: "#FF6B6B",
        warning: "#FBBF24",
        success: "#2DD4BF",
      },
      borderRadius: {
        sm: "8px",
        md: "12px",
        lg: "16px",
        xl: "20px",
      },
      animation: {
        "fade-in": "fadeIn 0.3s ease-out",
      },
      keyframes: {
        fadeIn: {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
      },
    },
  },
  plugins: [],
};
