import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/api/jellyfin_client.dart';
import '../core/storage/app_storage.dart';

/// Overridden in main() with the SharedPreferences-backed instance.
final appStorageProvider = Provider<AppStorage>(
  (ref) => throw UnimplementedError('appStorageProvider not overridden'),
);

final jellyfinClientProvider = Provider<JellyfinClient>((ref) {
  final storage = ref.watch(appStorageProvider);
  var deviceId = storage.deviceId();
  if (deviceId.isEmpty) {
    deviceId = const Uuid().v4();
    storage.setDeviceId(deviceId);
  }
  return JellyfinClient(deviceId: deviceId);
});
