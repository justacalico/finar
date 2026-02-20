# Finar

Finar is a cross-platform Jellyfin client built with Tauri, React, and TypeScript.

Pronounced "fye-nar".

![Tauri](https://img.shields.io/badge/Tauri-2-FFC131?style=for-the-badge&logo=tauri&logoColor=black)
![React](https://img.shields.io/badge/React-19-61DAFB?style=for-the-badge&logo=react&logoColor=black)
![TypeScript](https://img.shields.io/badge/TypeScript-5.8-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![License](https://img.shields.io/badge/License-AGPL--3.0-green?style=for-the-badge)

**Downloads** — Pre-built installers and APKs for Android, iOS, macOS, Windows, and Linux: [openlyst.ink/apps/finar](https://openlyst.ink/apps/finar)

## Features

- Video playback with HLS (video.js / hls.js)
- Android, iOS, macOS, Windows, and Linux support
- Multiple Jellyfin accounts and servers; profile picker and manage-profiles flow
- Offline downloads (Tauri desktop)
- Responsive layout with sidebar on desktop and bottom nav on mobile
- Customisable theme (light, dark, OLED) and accent colour (presets + custom hex)
- Multi-language (English, 简体中文, Русский)

## Requirements

- Node.js (LTS)
- Rust (for Tauri; see [Tauri prerequisites](https://v2.tauri.app/start/prerequisites/))
- A running [Jellyfin](https://jellyfin.org/) server

## Getting Started

```bash
git clone https://gitlab.com/Openlyst/finar.git
cd finar
npm install
npm run tauri dev
```

## Project Structure

```text
src/
├── main.tsx
├── App.tsx
├── api/           # Jellyfin API, OpenLyst update check
├── components/    # Layout, Button, Input, GlassCard, etc.
├── pages/         # Home, Login, Player, Settings, Library, …
├── stores/        # Auth, settings, library, player, downloads (Zustand)
├── translations/  # en, zh-CN, ru
├── types/
└── utils/
src-tauri/         # Tauri Rust backend (desktop, mobile)
```

## Tech Stack

- **Tauri 2** — desktop and mobile shell
- **React 19** + **TypeScript**
- **Vite** — build and dev server
- **Zustand** — state (auth, settings, library, player, downloads)
- **React Router** — routing
- **Tailwind CSS** — styling
- **Radix UI** — dropdowns, dialogs, slider, toast
- **Framer Motion** — animations
- **Lucide React** — icons
- **video.js** / **hls.js** — playback

## Build Releases

```bash
# Sync version and build
npm run tauri build
```

Outputs depend on the target (e.g. desktop installers in `src-tauri/target/release/bundle/`, Android APK in the Tauri gen output). For specific platforms, use [Tauri’s build targets](https://v2.tauri.app/guides/build/).

## Contributing

Merge requests are welcome.

## License

This project is licensed under the [GNU Affero General Public License v3](LICENSE) (AGPL-3.0).
