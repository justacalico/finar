# Finar

Finar is a Jellyfin client built to just work.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-AGPL%20v3-green?style=for-the-badge)

## Features

- Video playback with resume, speed control and audio/subtitle selection
- Music playback with a persistent mini player and shuffle queues
- Downloads for offline playback
- Multiple accounts with a who's-watching picker
- Adaptive layout: one app for phone, tablet, desktop and web
- Keyboard and controller navigation across every screen
- Android, iOS, macOS, Windows, Linux and Web

## Requirements

- Flutter SDK `^3.10.3`
- A running [Jellyfin](https://jellyfin.org/) server

## Building

```bash
flutter pub get
flutter run -d <device>
```

Release builds are produced by CI for every platform. Android release
builds are signed when `android/key.properties` is present (CI injects
it); otherwise the build falls back to debug signing.

## Testing

```bash
flutter test --coverage
python3 scripts/filter_coverage.py
bash test/scripts/run_all.sh
```

## Project layout

- `lib/core` — Jellyfin client, models, storage, theme, utilities
- `lib/providers` — Riverpod providers for session, library, playback, downloads and settings
- `lib/widgets` — shared UI kit: cards, rails, grids, headers, menus
- `lib/pages` — screens composed from the shared kit

## Contributing

Pull requests are welcome.

## AI

- All AI made code is allowed however you are responsible for testing and verifying the code.

## License

[AGPL-3.0](LICENSE)
