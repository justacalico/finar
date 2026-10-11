import 'dart:async';
import 'dart:convert';
import 'dart:io';

final _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

class FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration idleTimeout = const Duration(seconds: 15);

  @override
  Duration? connectionTimeout;

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest(method, url);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('get', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('post', url);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('put', url);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('delete', url);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('head', url);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('patch', url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isSetter) return null;
    return super.noSuchMethod(invocation);
  }
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this.method, this.uri);

  @override
  final String method;

  @override
  final Uri uri;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  final List<Cookie> cookies = [];

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  bool bufferOutput = true;

  @override
  int contentLength = -1;

  @override
  Encoding encoding = utf8;

  final Completer<HttpClientResponse> _done = Completer();

  @override
  Future<HttpClientResponse> get done => _done.future;

  @override
  Future<HttpClientResponse> close() {
    if (!_done.isCompleted) _done.complete(_FakeHttpClientResponse());
    return _done.future;
  }

  @override
  void add(List<int> data) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain();

  @override
  Future<void> flush() async {}

  @override
  void write(Object? object) {}

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    if (!_done.isCompleted) {
      _done.completeError(exception ?? Exception('aborted'), stackTrace);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isSetter) return null;
    return super.noSuchMethod(invocation);
  }
}

class _FakeHttpClientResponse extends StreamView<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse() : super(Stream.value(_kTransparentImage));

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  int statusCode = HttpStatus.ok;

  @override
  String reasonPhrase = 'OK';

  @override
  int contentLength = _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState compressionState =
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool isRedirect = false;

  @override
  List<RedirectInfo> redirects = const [];

  @override
  bool persistentConnection = false;

  @override
  X509Certificate? certificate;

  @override
  List<Cookie> cookies = const [];

  @override
  Future<Socket> detachSocket() => throw UnsupportedError('detachSocket');

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isSetter) return null;
    return super.noSuchMethod(invocation);
  }
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    (_values[name.toLowerCase()] ??= []).add('$value');
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = ['$value'];
  }

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  String? value(String name) => _values[name.toLowerCase()]?.first;

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  bool get chunkedTransferEncoding => false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isSetter) return null;
    return super.noSuchMethod(invocation);
  }
}
