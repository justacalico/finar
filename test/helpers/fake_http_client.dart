import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// A tiny 8x8 purple PNG served for every image request in tests.
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAIAQMAAAD+wSzIAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAADUExURWNm8RT2RggAAAAHdElNRQfqCg0WBB3cECQnAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI2LTEwLTEzVDIyOjA0OjI5KzAwOjAw6gDrtwAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNi0xMC0xM1QyMjowNDoyOSswMDowMJtdUwsAAAAodEVYdGRhdGU6dGltZXN0YW1wADIwMjYtMTAtMTNUMjI6MDQ6MjkrMDA6MDDMSHLUAAAAC0lEQVQI12NgQAUAABAAAaHFIcEAAAAASUVORK5CYII=';

class FakeImageHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      FakeImageRequest(url.toString().contains('broken') ? 404 : 200);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async =>
      FakeImageRequest(path.contains('broken') ? 404 : 200);
}

class FakeImageRequest extends Fake implements HttpClientRequest {
  FakeImageRequest([this.code = 200]);
  final int code;

  @override
  HttpHeaders get headers => FakeImageHeaders();

  @override
  Future<HttpClientResponse> close() async => FakeImageResponse(code);
}

class FakeImageHeaders extends Fake implements HttpHeaders {
  final _map = <String, List<String>>{};

  @override
  void set(String name, Object value,
          {bool preserveHeaderCase = false}) =>
      _map[name] = [value.toString()];

  @override
  void add(String name, Object value,
          {bool preserveHeaderCase = false}) =>
      _map.putIfAbsent(name, () => []).add(value.toString());
}

class FakeImageResponse extends Fake implements HttpClientResponse {
  FakeImageResponse([this.code = 200]);
  final int code;

  static final _bytes = base64Decode(_pngBase64);

  @override
  int get statusCode => code;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpHeaders get headers => FakeImageHeaders();

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  List<Cookie> get cookies => const [];

  @override
  StreamSubscription<List<int>> listen(
          void Function(List<int> event)? onData,
          {Function? onError,
          void Function()? onDone,
          bool? cancelOnError}) =>
      Stream.value(_bytes).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  Stream<List<int>> asBroadcastStream(
          {void Function(StreamSubscription<List<int>>)? onListen,
          void Function(StreamSubscription<List<int>>)? onCancel}) =>
      Stream.value(_bytes).asBroadcastStream(
          onListen: onListen, onCancel: onCancel);
}

class FakeImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      FakeImageHttpClient();
}
