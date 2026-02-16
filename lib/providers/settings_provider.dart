import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UI mode options for forcing a specific UI engine
enum UiMode {
  auto,   // Use platform detection
  desktop,
  mobile,
}

/// App settings model
class AppSettings {
  // Playback
  final int defaultVideoQuality;
  final bool autoPlayNext;
  final bool skipIntros;
  final bool skipCredits;
  final int forwardSkipDuration;
  final int rewindSkipDuration;

  // Subtitles
  final bool subtitlesEnabled;
  final String subtitleLanguage;
  final double subtitleSize;
  final Color subtitleColor;
  final Color subtitleBackgroundColor;

  // Audio
  final String audioLanguage;
  final bool normalizeVolume;

  // Appearance
  final ThemeMode themeMode;
  final bool useSystemAccent;
  final bool enableAnimations;
  final bool reducedMotion;

  // Network
  final int maxStreamingBitrate;
  final bool allowCellularStreaming;
  final bool preloadNextEpisode;

  // Cache
  final int imageCacheSize;
  final bool cacheImages;

  // UI Mode
  final UiMode forcedUiMode;

  const AppSettings({
    this.defaultVideoQuality = 1080,
    this.autoPlayNext = true,
    this.skipIntros = false,
    this.skipCredits = false,
    this.forwardSkipDuration = 10,
    this.rewindSkipDuration = 10,
    this.subtitlesEnabled = false,
    this.subtitleLanguage = 'eng',
    this.subtitleSize = 1.0,
    this.subtitleColor = Colors.white,
    this.subtitleBackgroundColor = Colors.black54,
    this.audioLanguage = 'eng',
    this.normalizeVolume = false,
    this.themeMode = ThemeMode.dark,
    this.useSystemAccent = false,
    this.enableAnimations = true,
    this.reducedMotion = false,
    this.maxStreamingBitrate = 40000000,
    this.allowCellularStreaming = true,
    this.preloadNextEpisode = true,
    this.imageCacheSize = 500,
    this.cacheImages = true,
    this.forcedUiMode = UiMode.auto,
  });

  AppSettings copyWith({
    int? defaultVideoQuality,
    bool? autoPlayNext,
    bool? skipIntros,
    bool? skipCredits,
    int? forwardSkipDuration,
    int? rewindSkipDuration,
    bool? subtitlesEnabled,
    String? subtitleLanguage,
    double? subtitleSize,
    Color? subtitleColor,
    Color? subtitleBackgroundColor,
    String? audioLanguage,
    bool? normalizeVolume,
    ThemeMode? themeMode,
    bool? useSystemAccent,
    bool? enableAnimations,
    bool? reducedMotion,
    int? maxStreamingBitrate,
    bool? allowCellularStreaming,
    bool? preloadNextEpisode,
    int? imageCacheSize,
    bool? cacheImages,
    UiMode? forcedUiMode,
  }) {
    return AppSettings(
      defaultVideoQuality: defaultVideoQuality ?? this.defaultVideoQuality,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      skipIntros: skipIntros ?? this.skipIntros,
      skipCredits: skipCredits ?? this.skipCredits,
      forwardSkipDuration: forwardSkipDuration ?? this.forwardSkipDuration,
      rewindSkipDuration: rewindSkipDuration ?? this.rewindSkipDuration,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      subtitleSize: subtitleSize ?? this.subtitleSize,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      subtitleBackgroundColor: subtitleBackgroundColor ?? this.subtitleBackgroundColor,
      audioLanguage: audioLanguage ?? this.audioLanguage,
      normalizeVolume: normalizeVolume ?? this.normalizeVolume,
      themeMode: themeMode ?? this.themeMode,
      useSystemAccent: useSystemAccent ?? this.useSystemAccent,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      maxStreamingBitrate: maxStreamingBitrate ?? this.maxStreamingBitrate,
      allowCellularStreaming: allowCellularStreaming ?? this.allowCellularStreaming,
      preloadNextEpisode: preloadNextEpisode ?? this.preloadNextEpisode,
      imageCacheSize: imageCacheSize ?? this.imageCacheSize,
      cacheImages: cacheImages ?? this.cacheImages,
      forcedUiMode: forcedUiMode ?? this.forcedUiMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultVideoQuality': defaultVideoQuality,
      'autoPlayNext': autoPlayNext,
      'skipIntros': skipIntros,
      'skipCredits': skipCredits,
      'forwardSkipDuration': forwardSkipDuration,
      'rewindSkipDuration': rewindSkipDuration,
      'subtitlesEnabled': subtitlesEnabled,
      'subtitleLanguage': subtitleLanguage,
      'subtitleSize': subtitleSize,
      'subtitleColor': subtitleColor.toARGB32(),
      'subtitleBackgroundColor': subtitleBackgroundColor.toARGB32(),
      'audioLanguage': audioLanguage,
      'normalizeVolume': normalizeVolume,
      'themeMode': themeMode.index,
      'useSystemAccent': useSystemAccent,
      'enableAnimations': enableAnimations,
      'reducedMotion': reducedMotion,
      'maxStreamingBitrate': maxStreamingBitrate,
      'allowCellularStreaming': allowCellularStreaming,
      'preloadNextEpisode': preloadNextEpisode,
      'imageCacheSize': imageCacheSize,
      'cacheImages': cacheImages,
      'forcedUiMode': forcedUiMode.index,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      defaultVideoQuality: json['defaultVideoQuality'] as int? ?? 1080,
      autoPlayNext: json['autoPlayNext'] as bool? ?? true,
      skipIntros: json['skipIntros'] as bool? ?? false,
      skipCredits: json['skipCredits'] as bool? ?? false,
      forwardSkipDuration: json['forwardSkipDuration'] as int? ?? 10,
      rewindSkipDuration: json['rewindSkipDuration'] as int? ?? 10,
      subtitlesEnabled: json['subtitlesEnabled'] as bool? ?? false,
      subtitleLanguage: json['subtitleLanguage'] as String? ?? 'eng',
      subtitleSize: (json['subtitleSize'] as num?)?.toDouble() ?? 1.0,
      subtitleColor: json['subtitleColor'] != null
          ? Color(json['subtitleColor'] as int)
          : Colors.white,
      subtitleBackgroundColor: json['subtitleBackgroundColor'] != null
          ? Color(json['subtitleBackgroundColor'] as int)
          : Colors.black54,
      audioLanguage: json['audioLanguage'] as String? ?? 'eng',
      normalizeVolume: json['normalizeVolume'] as bool? ?? false,
      themeMode: json['themeMode'] != null
          ? ThemeMode.values[json['themeMode'] as int]
          : ThemeMode.dark,
      useSystemAccent: json['useSystemAccent'] as bool? ?? false,
      enableAnimations: json['enableAnimations'] as bool? ?? true,
      reducedMotion: json['reducedMotion'] as bool? ?? false,
      maxStreamingBitrate: json['maxStreamingBitrate'] as int? ?? 40000000,
      allowCellularStreaming: json['allowCellularStreaming'] as bool? ?? true,
      preloadNextEpisode: json['preloadNextEpisode'] as bool? ?? true,
      imageCacheSize: json['imageCacheSize'] as int? ?? 500,
      cacheImages: json['cacheImages'] as bool? ?? true,
      forcedUiMode: json['forcedUiMode'] != null
          ? UiMode.values[json['forcedUiMode'] as int]
          : UiMode.auto,
    );
  }
}

/// Settings notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  static const _prefsKey = 'app_settings';
  SharedPreferences? _prefs;

  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    final json = _prefs?.getString(_prefsKey);
    if (json != null) {
      try {
        final map = Map<String, dynamic>.from(
          Uri.splitQueryString(json).map((k, v) => MapEntry(k, _parseValue(v))),
        );
        state = AppSettings.fromJson(map);
      } catch (_) {
        // Use defaults on error
      }
    }
  }

  dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    final intVal = int.tryParse(value);
    if (intVal != null) return intVal;
    final doubleVal = double.tryParse(value);
    if (doubleVal != null) return doubleVal;
    return value;
  }

  Future<void> _saveSettings() async {
    final json = state.toJson().entries.map((e) => '${e.key}=${e.value}').join('&');
    await _prefs?.setString(_prefsKey, json);
  }

  Future<void> updateSettings(AppSettings Function(AppSettings) update) async {
    state = update(state);
    await _saveSettings();
  }

  // Playback settings
  Future<void> setDefaultVideoQuality(int quality) async {
    await updateSettings((s) => s.copyWith(defaultVideoQuality: quality));
  }

  Future<void> setAutoPlayNext(bool value) async {
    await updateSettings((s) => s.copyWith(autoPlayNext: value));
  }

  Future<void> setSkipIntros(bool value) async {
    await updateSettings((s) => s.copyWith(skipIntros: value));
  }

  Future<void> setSkipCredits(bool value) async {
    await updateSettings((s) => s.copyWith(skipCredits: value));
  }

  Future<void> setForwardSkipDuration(int seconds) async {
    await updateSettings((s) => s.copyWith(forwardSkipDuration: seconds));
  }

  Future<void> setRewindSkipDuration(int seconds) async {
    await updateSettings((s) => s.copyWith(rewindSkipDuration: seconds));
  }

  // Subtitle settings
  Future<void> setSubtitlesEnabled(bool value) async {
    await updateSettings((s) => s.copyWith(subtitlesEnabled: value));
  }

  Future<void> setSubtitleLanguage(String language) async {
    await updateSettings((s) => s.copyWith(subtitleLanguage: language));
  }

  Future<void> setSubtitleSize(double size) async {
    await updateSettings((s) => s.copyWith(subtitleSize: size));
  }

  Future<void> setSubtitleColor(Color color) async {
    await updateSettings((s) => s.copyWith(subtitleColor: color));
  }

  // Audio settings
  Future<void> setAudioLanguage(String language) async {
    await updateSettings((s) => s.copyWith(audioLanguage: language));
  }

  Future<void> setNormalizeVolume(bool value) async {
    await updateSettings((s) => s.copyWith(normalizeVolume: value));
  }

  // Appearance settings
  Future<void> setThemeMode(ThemeMode mode) async {
    await updateSettings((s) => s.copyWith(themeMode: mode));
  }

  Future<void> setEnableAnimations(bool value) async {
    await updateSettings((s) => s.copyWith(enableAnimations: value));
  }

  Future<void> setReducedMotion(bool value) async {
    await updateSettings((s) => s.copyWith(reducedMotion: value));
  }

  // Network settings
  Future<void> setMaxStreamingBitrate(int bitrate) async {
    await updateSettings((s) => s.copyWith(maxStreamingBitrate: bitrate));
  }

  Future<void> setAllowCellularStreaming(bool value) async {
    await updateSettings((s) => s.copyWith(allowCellularStreaming: value));
  }

  Future<void> setPreloadNextEpisode(bool value) async {
    await updateSettings((s) => s.copyWith(preloadNextEpisode: value));
  }

  // Cache settings
  Future<void> setImageCacheSize(int sizeInMB) async {
    await updateSettings((s) => s.copyWith(imageCacheSize: sizeInMB));
  }

  Future<void> setCacheImages(bool value) async {
    await updateSettings((s) => s.copyWith(cacheImages: value));
  }

  // UI Mode settings
  Future<void> setForcedUiMode(UiMode mode) async {
    await updateSettings((s) => s.copyWith(forcedUiMode: mode));
  }

  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }
}

/// Settings provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

/// Theme mode provider
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.themeMode;
});

/// Animations enabled provider
final animationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.enableAnimations && !settings.reducedMotion;
});

/// Forced UI mode provider
final forcedUiModeProvider = Provider<UiMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.forcedUiMode;
});

/// Video quality options
const videoQualityOptions = [
  (value: 480, label: '480p', bitrate: 1500000),
  (value: 720, label: '720p', bitrate: 4000000),
  (value: 1080, label: '1080p', bitrate: 10000000),
  (value: 1440, label: '1440p', bitrate: 20000000),
  (value: 2160, label: '4K', bitrate: 40000000),
];

/// Language options
const languageOptions = [
  (code: 'eng', name: 'English'),
  (code: 'spa', name: 'Spanish'),
  (code: 'fra', name: 'French'),
  (code: 'deu', name: 'German'),
  (code: 'ita', name: 'Italian'),
  (code: 'jpn', name: 'Japanese'),
  (code: 'kor', name: 'Korean'),
  (code: 'zho', name: 'Chinese'),
  (code: 'por', name: 'Portuguese'),
  (code: 'rus', name: 'Russian'),
];

extension ColorExtension on Color {
  int toARGB32() {
    return (a.toInt() << 24) | (r.toInt() << 16) | (g.toInt() << 8) | b.toInt();
  }
}
