# Finar

Finar is a Jellyfin client built with Flutter.

![desktop.png](desktop.png)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

## Features

- Video playback powered by `media_kit`
- Android, iOS, macOS, Windows, Linux, and Web support
- Shared core with separate page layouts for desktop and mobile
- Riverpod-based state management
- Local persistence and cache with Hive/shared preferences
- Designed for media browsing with gamepad/remote-friendly input support

## Requirements

- Flutter SDK `^3.10.3`
- A running [Jellyfin](https://jellyfin.org/) server

## Getting Started

```bash
git clone https://github.com/openlyst/finar.git
cd finar
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

If you are actively working on models/adapters, run this in a second terminal:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Project Structure

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── api/
│   ├── services/
│   ├── theme/
│   └── utils/
├── pages/
│   ├── desktop/
│   └── mobile/
├── providers/
└── widgets/
```

## Tech Stack

- Flutter + Dart
- Riverpod
- media_kit
- Dio/http
- Hive + shared_preferences
- flutter_animate + glassmorphism

## Build Releases

```bash
flutter build apk --release
flutter build ios --release
flutter build macos --release
flutter build windows --release
flutter build linux --release
flutter build web --release
```

## Contributing

Pull requests are welcome.

## License

This project is licensed under [GPL](LICENSE).
