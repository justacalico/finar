import 'package:finar/core/utils/server_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerUrl.normalize', () {
    test('adds https when scheme missing', () {
      expect(ServerUrl.normalize('jellyfin.example.com'),
          'https://jellyfin.example.com');
    });

    test('keeps explicit http scheme', () {
      expect(ServerUrl.normalize('http://192.168.1.5:8096'),
          'http://192.168.1.5:8096');
    });

    test('strips trailing slashes', () {
      expect(ServerUrl.normalize('https://demo.jellyfin.org/stable/'),
          'https://demo.jellyfin.org/stable');
    });

    test('keeps non-default ports', () {
      expect(ServerUrl.normalize('https://x.local:8920'),
          'https://x.local:8920');
    });

    test('rejects empty and invalid input', () {
      expect(ServerUrl.normalize('   '), isNull);
      expect(ServerUrl.normalize(''), isNull);
      expect(ServerUrl.normalize('ftp://host'), isNull);
      expect(ServerUrl.normalize('://no-scheme'), isNull);
    });
  });
}
