# Finar — Jellyfin Client (Tauri)

A cross-platform Jellyfin client built with **Tauri 2**, **React 18**, **TypeScript**, and **Vite**. Ported from the Finar Flutter app.

## Stack

- **Frontend:** React 18, TypeScript, Vite
- **Desktop / Web:** Tauri 2.x
- **Styling:** Tailwind CSS v4
- **UI:** Radix UI, Lucide React, Framer Motion
- **State:** Zustand
- **Routing:** React Router DOM
- **Video:** Native `<video>` (HLS/direct stream)

## Targets

- **Web** — run as a static site or inside Tauri webview
- **Linux** — `npm run tauri build` (deb, rpm; AppImage may need extra setup)
- **macOS** — `npm run tauri build` on macOS (Intel/ARM)
- **Windows** — `npm run tauri build` on Windows
- **Android** — `npm run tauri android init` then `npm run tauri android build`
- **iOS** — `npm run tauri ios init` then `npm run tauri ios build`

## Commands

```bash
# Install
npm install

# Development (desktop)
npm run tauri dev

# Build (current OS)
npm run tauri build

# Build for a specific target (examples)
npm run tauri build -- --target x86_64-pc-windows-msvc   # Windows
npm run tauri build -- --target x86_64-apple-darwin      # macOS Intel
npm run tauri build -- --target aarch64-apple-darwin     # macOS ARM
npm run tauri build -- --target x86_64-unknown-linux-gnu # Linux
```

## Features

- **Login** — Server URL, username/password, Quick Connect
- **Home** — Hero, Continue Watching, Next Up, Recently Added, Recommended, Favorites
- **Search** — Full Jellyfin search
- **Libraries** — Browse by library (movies, TV, music, etc.)
- **Item detail** — Overview, seasons/episodes for series, similar items, play
- **Video player** — Direct play / HLS, progress reporting, basic controls
- **Settings** — Account info
- **Layout** — Single responsive layout (sidebar + main), reusable components

## Project layout

- `src/` — React app
  - `api/` — Jellyfin API client and home data
  - `components/` — Reusable UI (Button, Input, MediaCard, Layout, etc.)
  - `pages/` — Splash, Login, Home, Search, Favorites, Library, ItemDetail, Player, Settings
  - `stores/` — Zustand (auth, library, player)
  - `types/` — Jellyfin TypeScript types
  - `utils/` — Image URL helpers
- `src-tauri/` — Tauri 2 Rust backend and config

## License

Same as the original Finar project.
