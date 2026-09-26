import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'providers.dart';

class AppSettings {
  final AppThemeMode themeMode;
  final String accentName;
  final bool autoplayNext;
  final bool rememberPosition;
  final int maxStreamingBitrate; // 0 = auto
  final String preferredAudioLanguage;
  final String preferredSubtitleLanguage;
  final bool subtitlesEnabled;
  final double subtitleSize;
  final double subtitleBackground; // 0..1 opacity
  final bool downloadWifiOnly;
  final bool showThumbnails;
  final double uiScale;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.accentName = 'System',
    this.autoplayNext = true,
    this.rememberPosition = true,
    this.maxStreamingBitrate = 0,
    this.preferredAudioLanguage = '',
    this.preferredSubtitleLanguage = '',
    this.subtitlesEnabled = true,
    this.subtitleSize = 1.0,
    this.subtitleBackground = 0.6,
    this.downloadWifiOnly = false,
    this.showThumbnails = true,
    this.uiScale = 1.0,
  });

  Color get accent =>
      kAccentOptions[accentName] ?? kAccentOptions['System']!;

  ThemeMode get flutterThemeMode => switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        _ => ThemeMode.dark,
      };

  bool get oled => themeMode == AppThemeMode.oled;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? accentName,
    bool? autoplayNext,
    bool? rememberPosition,
    int? maxStreamingBitrate,
    String? preferredAudioLanguage,
    String? preferredSubtitleLanguage,
    bool? subtitlesEnabled,
    double? subtitleSize,
    double? subtitleBackground,
    bool? downloadWifiOnly,
    bool? showThumbnails,
    double? uiScale,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        accentName: accentName ?? this.accentName,
        autoplayNext: autoplayNext ?? this.autoplayNext,
        rememberPosition: rememberPosition ?? this.rememberPosition,
        maxStreamingBitrate:
            maxStreamingBitrate ?? this.maxStreamingBitrate,
        preferredAudioLanguage:
            preferredAudioLanguage ?? this.preferredAudioLanguage,
        preferredSubtitleLanguage:
            preferredSubtitleLanguage ?? this.preferredSubtitleLanguage,
        subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
        subtitleSize: subtitleSize ?? this.subtitleSize,
        subtitleBackground: subtitleBackground ?? this.subtitleBackground,
        downloadWifiOnly: downloadWifiOnly ?? this.downloadWifiOnly,
        showThumbnails: showThumbnails ?? this.showThumbnails,
        uiScale: uiScale ?? this.uiScale,
      );

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'accentName': accentName,
        'autoplayNext': autoplayNext,
        'rememberPosition': rememberPosition,
        'maxStreamingBitrate': maxStreamingBitrate,
        'preferredAudioLanguage': preferredAudioLanguage,
        'preferredSubtitleLanguage': preferredSubtitleLanguage,
        'subtitlesEnabled': subtitlesEnabled,
        'subtitleSize': subtitleSize,
        'subtitleBackground': subtitleBackground,
        'downloadWifiOnly': downloadWifiOnly,
        'showThumbnails': showThumbnails,
        'uiScale': uiScale,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        themeMode: themeModeFromName(j['themeMode'] as String?),
        accentName: j['accentName'] as String? ?? 'System',
        autoplayNext: j['autoplayNext'] as bool? ?? true,
        rememberPosition: j['rememberPosition'] as bool? ?? true,
        maxStreamingBitrate: j['maxStreamingBitrate'] as int? ?? 0,
        preferredAudioLanguage:
            j['preferredAudioLanguage'] as String? ?? '',
        preferredSubtitleLanguage:
            j['preferredSubtitleLanguage'] as String? ?? '',
        subtitlesEnabled: j['subtitlesEnabled'] as bool? ?? true,
        subtitleSize: (j['subtitleSize'] as num?)?.toDouble() ?? 1.0,
        subtitleBackground:
            (j['subtitleBackground'] as num?)?.toDouble() ?? 0.6,
        downloadWifiOnly: j['downloadWifiOnly'] as bool? ?? false,
        showThumbnails: j['showThumbnails'] as bool? ?? true,
        uiScale: (j['uiScale'] as num?)?.toDouble() ?? 1.0,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() =>
      AppSettings.fromJson(ref.read(appStorageProvider).settings());

  Future<void> update(AppSettings Function(AppSettings) fn) async {
    state = fn(state);
    await ref.read(appStorageProvider).saveSettings(state.toJson());
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      update((s) => s.copyWith(themeMode: mode));
  Future<void> setAccent(String name) =>
      update((s) => s.copyWith(accentName: name));
  Future<void> setAutoplayNext(bool v) =>
      update((s) => s.copyWith(autoplayNext: v));
  Future<void> setRememberPosition(bool v) =>
      update((s) => s.copyWith(rememberPosition: v));
  Future<void> setMaxBitrate(int v) =>
      update((s) => s.copyWith(maxStreamingBitrate: v));
  Future<void> setPreferredAudioLanguage(String v) =>
      update((s) => s.copyWith(preferredAudioLanguage: v));
  Future<void> setPreferredSubtitleLanguage(String v) =>
      update((s) => s.copyWith(preferredSubtitleLanguage: v));
  Future<void> setSubtitlesEnabled(bool v) =>
      update((s) => s.copyWith(subtitlesEnabled: v));
  Future<void> setSubtitleSize(double v) =>
      update((s) => s.copyWith(subtitleSize: v));
  Future<void> setSubtitleBackground(double v) =>
      update((s) => s.copyWith(subtitleBackground: v));
  Future<void> setDownloadWifiOnly(bool v) =>
      update((s) => s.copyWith(downloadWifiOnly: v));
  Future<void> setShowThumbnails(bool v) =>
      update((s) => s.copyWith(showThumbnails: v));

  static const zoomSteps = <double>[
    0.5, 0.67, 0.75, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5, 1.75, 2.0
  ];

  Future<void> zoomIn() => update((s) => s.copyWith(
      uiScale: zoomSteps.firstWhere((v) => v > s.uiScale + 0.001,
          orElse: () => zoomSteps.last)));
  Future<void> zoomOut() => update((s) => s.copyWith(
      uiScale: zoomSteps.lastWhere((v) => v < s.uiScale - 0.001,
          orElse: () => zoomSteps.first)));
  Future<void> resetZoom() =>
      update((s) => s.copyWith(uiScale: 1.0));
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
