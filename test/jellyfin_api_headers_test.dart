import 'package:finar/core/api/jellyfin_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authHeaders sends both authorization header names', () {
    final api = JellyfinApi(deviceName: 'test-device', deviceId: 'device-1');

    expect(
      api.authHeaders.keys,
      containsAll(['Authorization', 'X-Emby-Authorization']),
    );
    expect(
      api.authHeaders['Authorization'],
      api.authHeaders['X-Emby-Authorization'],
    );
    expect(api.authHeaders['Authorization'], contains('Client="Finar"'));
  });

  test('authHeaders include the access token once credentials are set', () {
    final api = JellyfinApi(deviceName: 'test-device', deviceId: 'device-1');
    api.setCredentials(accessToken: 'token123', userId: 'user1');

    expect(api.authHeaders['Authorization'], contains('Token="token123"'));
  });
}
