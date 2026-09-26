import 'package:finar/core/storage/app_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppStorage> storageWith([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return AppStorage(await SharedPreferences.getInstance());
}

SavedAccount account(String server, String user) => SavedAccount(
      serverUrl: server,
      serverName: 'Srv',
      userId: user,
      userName: user,
      accessToken: 'tok-$user',
    );

void main() {
  group('AppStorage accounts', () {
    test('empty by default', () async {
      final s = await storageWith();
      expect(s.accounts(), isEmpty);
      expect(s.activeAccount(), isNull);
    });

    test('save, read and dedupe by key', () async {
      final s = await storageWith();
      await s.saveAccount(account('http://a', 'u1'));
      await s.saveAccount(account('http://a', 'u2'));
      expect(s.accounts().length, 2);
      await s.saveAccount(SavedAccount(
          serverUrl: 'http://a',
          serverName: 'Srv',
          userId: 'u1',
          userName: 'u1',
          accessToken: 'newtok'));
      expect(s.accounts().length, 2);
      expect(
          s.accounts()
              .firstWhere((a) => a.userId == 'u1')
              .accessToken,
          'newtok');
    });

    test('active account pointer', () async {
      final s = await storageWith();
      await s.saveAccount(account('http://a', 'u1'));
      await s.setActiveAccount('http://a::u1');
      expect(s.activeAccount()?.userId, 'u1');
      await s.setActiveAccount(null);
      expect(s.activeAccount(), isNull);
    });

    test('removing the active account clears the pointer', () async {
      final s = await storageWith();
      await s.saveAccount(account('http://a', 'u1'));
      await s.setActiveAccount('http://a::u1');
      await s.removeAccount('http://a::u1');
      expect(s.accounts(), isEmpty);
      expect(s.activeAccount(), isNull);
    });
  });

  group('AppStorage settings and misc', () {
    test('settings round trip', () async {
      final s = await storageWith();
      expect(s.settings(), isEmpty);
      await s.saveSettings({'themeMode': 'dark', 'n': 3});
      expect(s.settings()['themeMode'], 'dark');
      expect(s.settings()['n'], 3);
    });

    test('corrupt settings returns empty', () async {
      final s = await storageWith({'settings.v1': '{not json'});
      expect(s.settings(), isEmpty);
    });

    test('device id and raw values', () async {
      final s = await storageWith();
      expect(s.deviceId(), '');
      await s.setDeviceId('d1');
      expect(s.deviceId(), 'd1');
      await s.setRaw('k', 'v');
      expect(s.getRaw('k'), 'v');
    });
  });
}
