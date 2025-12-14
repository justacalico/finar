# Finar

> *Pronounced "fye-nar" (/faɪ nɑːr/)*

A beautiful, modern multi-platform Jellyfin client built with Flutter.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

## ✨ Features

- 🎬 **Native Video Playback** - Powered by media_kit for smooth, high-quality video streaming
- 📱 **Multi-Platform Support** - Runs on Android, iOS, macOS, Windows, Linux, Web, and TV
- 🎨 **Glassmorphism Design** - Beautiful, modern UI with blur effects and glass-like components
- 🌙 **Dark Mode** - Sleek dark theme designed for comfortable viewing
- 💾 **Offline Support** - Cache media and settings locally with Hive
- 🔄 **State Management** - Efficient state handling with Riverpod
- 📺 **Adaptive UI** - Separate interfaces optimized for desktop, mobile, and TV

## 📦 Installation

### Prerequisites

- Flutter SDK ^3.10.3
- Dart SDK ^3.10.3
- A running [Jellyfin](https://jellyfin.org/) server

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/finar.git
   cd finar
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   dart run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # Main app widget & routing
├── core/
│   ├── api/               # Jellyfin API client & models
│   ├── services/          # Core services
│   ├── theme/             # App theming
│   └── utils/             # Utility functions
├── pages/
│   ├── desktop/           # Desktop-specific pages
│   ├── mobile/            # Mobile-specific pages
│   └── tv/                # TV-specific pages
├── providers/             # Riverpod state providers
└── widgets/               # Reusable UI components
```

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Video Playback | media_kit |
| Local Storage | Hive |
| Networking | Dio |
| UI Effects | Glassmorphism, Flutter Animate |

## 📱 Supported Platforms

| Platform | Status |
|----------|--------|
| Android | ✅ Supported |
| iOS | ✅ Supported |
| macOS | ✅ Supported |
| Windows | ✅ Supported |
| Linux | ✅ Supported |
| Web | ✅ Supported |

## 🚀 Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release

# Web
flutter build web --release
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

---

<p align="center">
  Made with ❤️ and Flutter
</p>
