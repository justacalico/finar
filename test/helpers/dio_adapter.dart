import 'dart:convert';

import 'package:dio/dio.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.routes);

  final Map<String, dynamic Function(RequestOptions)> routes;
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(
      RequestOptions options,
      Stream<List<int>>? requestStream,
      Future<void>? cancelFuture) async {
    await requestStream?.drain();
    final path = options.path.startsWith('http')
        ? Uri.parse(options.path).path
        : options.path;
    final key = '${options.method} $path';
    calls.add(key);
    final handler = routes[key] ??
        routes.entries
            .where((e) => key.startsWith(e.key))
            .map((e) => e.value)
            .firstOrNull;
    if (handler == null) {
      return ResponseBody.fromString(
          jsonEncode({'Message': 'no route $key'}), 404);
    }
    final result = handler(options);
    if (result is int) {
      return ResponseBody.fromString('', result);
    }
    return ResponseBody.fromString(jsonEncode(result), 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });
  }

  @override
  void close({bool force = false}) {}
}
