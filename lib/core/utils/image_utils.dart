import 'dart:convert';
import 'dart:typed_data';

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

    // Data URIs (base64 avatars from calium.fun) are already complete images.
    if (url.startsWith('data:')) return url;

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

  /// Whether [url] is a base64-embedded `data:image/...` URI.
  static bool isDataUri(String url) =>
      url.startsWith('data:image/') && url.contains(',');

  /// Decodes the base64 payload of a `data:image/...;base64,...` URI.
  /// Returns null if the URI is malformed.
  static Uint8List? dataUriToBytes(String dataUri) {
    final commaIndex = dataUri.indexOf(',');
    if (commaIndex == -1 || commaIndex + 1 >= dataUri.length) return null;
    final payload = dataUri.substring(commaIndex + 1);
    try {
      return base64Decode(payload);
    } on FormatException {
      return null;
    }
  }

  /// Builds alternate URL variants to try when the primary image fails.
  /// - Proxied URLs (calium.fun asset proxy) fall back to the direct source.
  /// - Direct non-calium URLs fall back to the proxied version.
  static List<String> fallbackVariants(String? url) {
    final cleaned = cleanImageUrl(url);
    if (cleaned.isEmpty || isDataUri(cleaned)) return const [];
    final uri = Uri.tryParse(cleaned);
    if (uri == null || !cleaned.startsWith('http')) return const [];

    final variants = <String>[];
    if (uri.host.contains('calium.fun')) {
      final inner = uri.queryParameters['url'];
      if (inner != null && inner.isNotEmpty) {
        variants.add(inner);
      }
    } else {
      variants.add(
        '${ApiConstants.caliumBackendUrl}/api/anizium/asset?url=${Uri.encodeComponent(cleaned)}',
      );
    }
    return variants;
  }
}
