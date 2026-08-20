import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/utils/image_utils.dart';
import 'package:calium_stream/core/widgets/shimmer_placeholder.dart';

class AppCachedImage extends StatefulWidget {
  const AppCachedImage({
    required this.imageUrl,
    this.fallbackUrls = const [],
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    super.key,
  });

  final String? imageUrl;

  /// Alternate image URLs tried in order when the primary image fails to load.
  final List<String> fallbackUrls;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  /// Custom in-memory decode cache width. If null, computed smartly based on [width].
  final int? memCacheWidth;

  /// Custom in-memory decode cache height. If null, computed smartly based on [height].
  final int? memCacheHeight;

  /// Custom maximum disk cache width.
  final int? maxWidthDiskCache;

  /// Custom maximum disk cache height.
  final int? maxHeightDiskCache;

  @override
  State<AppCachedImage> createState() => _AppCachedImageState();
}

class _AppCachedImageState extends State<AppCachedImage> {
  int _retryKey = 0;
  int _fallbackIndex = 0;

  /// Combined fallback chain: user-provided fallbacks followed by
  /// automatically derived proxy/direct variants of the primary URL.
  List<String> get _effectiveFallbacks {
    final combined = <String>[
      ...widget.fallbackUrls,
      ...ImageUtils.fallbackVariants(widget.imageUrl),
    ];
    final seen = <String>{};
    final deduped = <String>[];
    for (final url in combined) {
      final cleaned = ImageUtils.cleanImageUrl(url);
      if (cleaned.isEmpty) continue;
      if (seen.add(cleaned)) deduped.add(cleaned);
    }
    return deduped;
  }

  String? get _resolvedUrl {
    if (_fallbackIndex == 0) return widget.imageUrl;
    final index = _fallbackIndex - 1;
    if (index < _effectiveFallbacks.length) {
      return _effectiveFallbacks[index];
    }
    return null;
  }

  void _tryNextFallback() {
    if (_fallbackIndex < _effectiveFallbacks.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _fallbackIndex < _effectiveFallbacks.length) {
          setState(() => _fallbackIndex++);
        }
      });
    }
  }

  void _retry() {
    CachedNetworkImage.evictFromCache(ImageUtils.cleanImageUrl(widget.imageUrl));
    setState(() {
      _retryKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Primary URL is cleaned; pre-computed fallback variants are already
    // final URLs and must not be re-cleaned (would re-proxy direct links).
    final isFallback = _fallbackIndex > 0;
    final cleaned = isFallback
        ? (_resolvedUrl ?? '')
        : ImageUtils.cleanImageUrl(_resolvedUrl);

    Widget content;

    if (cleaned.isEmpty) {
      if (_fallbackIndex < _effectiveFallbacks.length) {
        _tryNextFallback();
        return const SizedBox.shrink();
      }
      content = widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.surfaceDark,
            child: const Icon(
              Icons.movie_creation_outlined,
              color: AppColors.textMuted,
            ),
          );
    } else if (ImageUtils.isDataUri(cleaned)) {
      final bytes = ImageUtils.dataUriToBytes(cleaned);
      if (bytes == null) {
        content = widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              color: AppColors.surfaceDark,
              child: const Icon(
                Icons.broken_image_rounded,
                color: AppColors.textMuted,
              ),
            );
      } else {
        content = Image.memory(
          bytes,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) =>
              widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                color: AppColors.surfaceDark,
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: AppColors.textMuted,
                ),
              ),
        );
      }
    } else {
      // Calculate optimized memory cache dimensions based on device DPR and widget constraints
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
      final computedMemWidth = widget.memCacheWidth ?? (widget.width != null ? (widget.width! * dpr).toInt() : (widget.height == null ? 600 : null));
      final computedMemHeight = widget.memCacheHeight ?? (widget.height != null ? (widget.height! * dpr).toInt() : null);

      content = CachedNetworkImage(
        key: ValueKey('${cleaned}_$_retryKey'),
        imageUrl: cleaned,
        httpHeaders: {
          'Referer': ApiConstants.referer,
          'User-Agent': ApiConstants.userAgent,
          'Origin': ApiConstants.origin,
        },
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        memCacheWidth: computedMemWidth,
        memCacheHeight: computedMemHeight,
        maxWidthDiskCache: widget.maxWidthDiskCache ?? 1200,
        maxHeightDiskCache: widget.maxHeightDiskCache ?? 1200,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (_, _) =>
            widget.placeholder ?? ShimmerPlaceholder(width: widget.width, height: widget.height),
        errorWidget: (_, _, _) {
          if (_fallbackIndex < _effectiveFallbacks.length) {
            _tryNextFallback();
            return widget.placeholder ??
                ShimmerPlaceholder(width: widget.width, height: widget.height);
          }
          return widget.errorWidget ??
              GestureDetector(
                onTap: _retry,
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  color: AppColors.surfaceDark,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 24),
                      SizedBox(height: 4),
                      Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              );
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: content);
    }

    return content;
  }
}
