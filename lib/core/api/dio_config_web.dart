import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

/// Configure Dio HTTP client adapter for web platform
void configureDioForPlatform(Dio dio) {
  // Use BrowserHttpClientAdapter for web to handle CORS properly
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: false);
}
