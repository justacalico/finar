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


## Contributing

Pull requests are welcome. 

## AI Contributing
If you use AI please

- Prompt over MR | If you are gonna vibecode a feature submit a new Issue with the prompt you want instead. However mearge requests are still allowed.

- DO TESTING | We dont want vibe coded untested grabage. If you use AI test, test, and test.
- Mark it | Please mark that it is AI code it wont be declinaed but we will need to do more testing.

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

## Build Releases

```bash
flutter build apk --release
flutter build ios --release
flutter build macos --release
flutter build windows --release
flutter build linux --release
flutter build web --release
```

## License

This project is licensed under [AGPL V3](LICENSE).
