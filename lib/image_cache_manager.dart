import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// ─── Custom cache manager (singleton) ───────────────────────────────────────
/// Keeps images for 30 days, up to 500 files, max 200 MB.
class AppCacheManager extends CacheManager with ImageCacheManager {
  static const _key = 'luminae_img_cache';

  static final AppCacheManager _instance = AppCacheManager._();
  factory AppCacheManager() => _instance;

  AppCacheManager._()
      : super(Config(
    _key,
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 500,
    repo: JsonCacheInfoRepository(databaseName: _key),
    fileService: HttpFileService(),
  ));
}

/// ─── Drop-in cached image widget ─────────────────────────────────────────────
/// Usage:
///   AppCachedImage(url: 'https://…')
///   AppCachedImage(url: '…', width: 200, height: 200, fit: BoxFit.cover)
class AppCachedImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;   // shown while loading
  final Widget? errorWidget;   // shown on failure
  final BorderRadius? borderRadius;

  const AppCachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      cacheManager: AppCacheManager(),
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 250),
      // ── placeholder ──────────────────────────────────────────────────────
      placeholder: (_, __) =>
      placeholder ??
          Container(
            width: width,
            height: height,
            color: const Color(0xFF1E1E1E),          // AppColors.surface2
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD72638),             // AppColors.red
                strokeWidth: 1.5,
              ),
            ),
          ),
      // ── error ────────────────────────────────────────────────────────────
      errorWidget: (_, __, ___) =>
      errorWidget ??
          Container(
            width: width,
            height: height,
            color: const Color(0xFF1E1E1E),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Color(0x61FFFFFF),             // AppColors.white38
                size: 32,
              ),
            ),
          ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}