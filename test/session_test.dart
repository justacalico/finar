import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:finar/core/api/jellyfin_client.dart';
import 'package:finar/core/storage/app_storage.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAdapter implements HttpClientAdapter {
  final dynamic Function(RequestOptions options)? handler;
  FakeAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Stream<Uint8List>? stream = requestStream;
    if (stream != null) await stream.drain<void>();
    final data = handler?.call(options);
    return ResponseBody.fromString(
      jsonEncode(data ?? {}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

Future<ProviderContainer> container({
  required dynamic Function(RequestOptions) api,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = AppStorage(await SharedPreferences.getInstance());
  final dio = Dio()..httpClientAdapter = FakeAdapter(api);
  final client = JellyfinClient(dio: dio, deviceId: 't')
    ..setServerUrl('http://srv');
  final c = ProviderContainer(
    overrides: [
      appStorageProvider.overrideWithValue(storage),
      jellyfinClientProvider.overrideWithValue(client),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

SavedAccount saved() => const SavedAccount(
  serverUrl: 'http://srv',
  serverName: 'Srv',
  userId: 'u1',
  userName: 'Cal',
  accessToken: 'tok',
);

Future<Map<String, Object>> prefsWithAccount() async {
  final json = jsonEncode([saved().toJson()]);
  return {'accounts.v1': json, 'activeAccount.v1': saved().key};
}

void main() {
  group('SessionNotifier', () {
    test('signed out when no account saved', () async {
      final c = await container(api: (_) => {});
      c.read(sessionProvider);
      await pumpEventQueue();
      expect(c.read(sessionProvider), isA<SignedOut>());
      final out = c.read(sessionProvider) as SignedOut;
      expect(out.accounts, isEmpty);
    });

    test('restores the saved active account', () async {
      final c = await container(
        api: (o) => o.path == '/Users/u1/Views'
            ? {
                'Items': [
                  {'Id': 'l1', 'Name': 'Movies'},
                ],
              }
            : {},
        prefs: await prefsWithAccount(),
      );
      c.read(sessionProvider);
      await pumpEventQueue();
      final s = c.read(sessionProvider);
      expect(s, isA<SignedIn>());
      final signed = s as SignedIn;
      expect(signed.account.userId, 'u1');
      expect(signed.libraries.single.name, 'Movies');
    });

    test('signIn stores and activates the account', () async {
      final c = await container(
        api: (o) {
          if (o.path == '/Users/AuthenticateByName') {
            return {
              'User': {'Id': 'u9', 'Name': 'Sam'},
              'AccessToken': 'fresh',
              'ServerId': 'srv',
            };
          }
          return {'Items': []};
        },
      );
      await pumpEventQueue();
      await c
          .read(sessionProvider.notifier)
          .signIn(
            serverUrl: 'http://srv',
            serverName: 'Srv',
            username: 'sam',
            password: 'pw',
          );
      final s = c.read(sessionProvider) as SignedIn;
      expect(s.account.userId, 'u9');
      final storage = c.read(appStorageProvider);
      expect(storage.activeAccount()?.accessToken, 'fresh');
    });

    test('signOut clears session and stored account', () async {
      final c = await container(
        api: (_) => {'Items': []},
        prefs: await prefsWithAccount(),
      );
      c.read(sessionProvider);
      await pumpEventQueue();
      expect(c.read(sessionProvider), isA<SignedIn>());
      await c.read(sessionProvider.notifier).signOut();
      expect(c.read(sessionProvider), isA<SignedOut>());
      expect(c.read(appStorageProvider).activeAccount(), isNull);
      expect(c.read(appStorageProvider).accounts(), isEmpty);
    });

    test('switchAccount activates another saved account', () async {
      final c = await container(api: (_) => {'Items': []});
      await pumpEventQueue();
      await c.read(sessionProvider.notifier).switchAccount(saved());
      expect(c.read(sessionProvider), isA<SignedIn>());
    });

    test('removeAccount drops the session when active', () async {
      final c = await container(
        api: (_) => {'Items': []},
        prefs: await prefsWithAccount(),
      );
      c.read(sessionProvider);
      await pumpEventQueue();
      await c.read(sessionProvider.notifier).removeAccount(saved());
      expect(c.read(sessionProvider), isA<SignedOut>());
    });
  });
}
