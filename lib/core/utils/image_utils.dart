import 'package:calium_stream/core/constants/api_constants.dart';

class ImageUtils {
  ImageUtils._();

  static const List<String> _aniziumHosts = [
    'anizium.co',
    'anizium.com',
    'anizium.net',
    'anizium.org',
  ];

  /// Cleans and formats image URLs to ensure they load reliably across all devices.
  /// Handles protocol-relative URLs (//...), relative paths (/api/anizium/asset...),
  /// TMDB poster hashes, and proxies Anizium URLs through calium.fun asset proxy.
  static String cleanImageUrl(String? rawUrl) {
    if (rawUrl == null) return '';
    String url = rawUrl.trim();
    if (url.isEmpty) return '';

    // If it's already an asset proxy on calium.fun
    if (url.startsWith('/api/anizium/asset') || url.startsWith('/api/')) {
      return '${ApiConstants.caliumBackendUrl}$url';
    }

    // Handle protocol-relative URL
    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    // Handle TMDB relative path (e.g. /7WsyChvgjoqJzp127U0Vp01.jpg)
    if (url.startsWith('/') &&
        (url.endsWith('.jpg') || url.endsWith('.png') || url.endsWith('.jpeg')) &&
        !url.contains('api') &&
        !url.contains('assets')) {
      return 'https://image.tmdb.org/t/p/w500$url';
    }

    // Handle Calium relative path
    if (url.startsWith('/')) {
      return '${ApiConstants.caliumBackendUrl}$url';
    }

    // Handle full HTTP / HTTPS URLs
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final host = uri.host.toLowerCase();
        final isAniziumHost = _aniziumHosts.any((h) => host == h || host.endsWith('.$h'));
        if (isAniziumHost) {
          // Route through calium.fun asset proxy for guaranteed Cloudflare bypass and caching
          return '${ApiConstants.caliumBackendUrl}/api/anizium/asset?url=${Uri.encodeComponent(url)}';
        }
      }
      return url;
    }

    return '${ApiConstants.caliumBackendUrl}/api/anizium/asset?url=${Uri.encodeComponent(url)}';
  }
}
