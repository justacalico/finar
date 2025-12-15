import 'package:flutter/foundation.dart';

/// Converts image URLs to go through the nginx proxy on web to avoid CORS issues.
/// On other platforms, returns the URL unchanged.
String proxyImageUrl(String imageUrl) {
  if (!kIsWeb || imageUrl.isEmpty) {
    return imageUrl;
  }

  // On web, route image requests through the nginx proxy
  // The proxy endpoint is /proxy/{full-url}
  // This only works when running in the Docker container with nginx
  
  // Get the current origin (where the web app is hosted)
  // and route through the proxy endpoint
  try {
    final uri = Uri.parse(imageUrl);
    
    // If it's already a relative URL or same origin, no need to proxy
    if (!uri.hasScheme || uri.host.isEmpty) {
      return imageUrl;
    }
    
    // Route through proxy: /proxy/https://jellyfin.server/path
    return '/proxy/$imageUrl';
  } catch (_) {
    return imageUrl;
  }
}

/// Helper extension on String for easy proxying
extension ImageProxyExtension on String {
  String get proxied => proxyImageUrl(this);
}
