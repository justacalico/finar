import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform detection utilities
class PlatformDetector {
  PlatformDetector._();

  /// Check if running on mobile (iOS or Android)
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Check if running on desktop (macOS, Linux, Windows)
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// Check if running on Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// Check if running on macOS
  static bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }

  /// Check if running on Linux
  static bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }

  /// Check if running on Windows
  static bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// Check if platform supports haptic feedback
  static bool get supportsHaptics {
    return isMobile;
  }

  /// Check if platform supports picture-in-picture
  static bool get supportsPiP {
    return isIOS || isAndroid;
  }

  /// Check if platform supports native video player
  static bool get supportsNativePlayer {
    return !kIsWeb;
  }

  /// Get current platform type
  static PlatformType get current {
    if (kIsWeb) return PlatformType.web;
    if (Platform.isIOS) return PlatformType.ios;
    if (Platform.isAndroid) return PlatformType.android;
    if (Platform.isMacOS) return PlatformType.macos;
    if (Platform.isLinux) return PlatformType.linux;
    if (Platform.isWindows) return PlatformType.windows;
    return PlatformType.unknown;
  }

  /// Get OS version string
  static String get osVersion {
    if (kIsWeb) return 'Web';
    return Platform.operatingSystemVersion;
  }
}

/// Platform types
enum PlatformType {
  ios,
  android,
  macos,
  linux,
  windows,
  web,
  tv,
  unknown,
}

/// Extension for platform-specific values
extension PlatformTypeExtension on PlatformType {
  bool get isMobile => this == PlatformType.ios || this == PlatformType.android;
  bool get isDesktop => 
      this == PlatformType.macos || 
      this == PlatformType.linux || 
      this == PlatformType.windows;
  bool get isApple => this == PlatformType.ios || this == PlatformType.macos;
}
