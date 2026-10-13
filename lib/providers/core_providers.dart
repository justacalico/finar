import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/downloads_store.dart';
import '../core/storage/session_store.dart';
import '../core/storage/settings_store.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
    (ref) => throw UnimplementedError('override sharedPrefsProvider'));

final secureStorageProvider = Provider<FlutterSecureStorage>(
    (ref) => const FlutterSecureStorage());

final settingsStoreProvider = Provider<SettingsStore>(
    (ref) => SettingsStore(ref.watch(sharedPrefsProvider)));

final sessionStoreProvider = Provider<SessionStore>((ref) =>
    SessionStore(
        ref.watch(sharedPrefsProvider), ref.watch(secureStorageProvider)));

final downloadsStoreProvider = Provider<DownloadsStore>(
    (ref) => DownloadsStore(ref.watch(sharedPrefsProvider)));

final deviceIdProvider = FutureProvider<String>(
    (ref) => ref.watch(sessionStoreProvider).deviceId());
