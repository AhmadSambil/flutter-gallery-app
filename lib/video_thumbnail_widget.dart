import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_video_thumbnail_plus/flutter_video_thumbnail_plus.dart';
import 'package:path_provider/path_provider.dart';

/// ─── Video thumbnail widget ──────────────────────────────────────────────────
/// Generates a JPEG thumbnail from [videoUrl] (local path or remote URL),
/// caches it to disk on first call, then reuses the cached file.
///
/// Usage:
///   VideoThumbnailWidget(videoUrl: 'https://…')
///   VideoThumbnailWidget(videoUrl: '/local/path/video.mp4', height: 180)
class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  /// Optional play-button overlay (pass `showPlayIcon: true`).
  final bool showPlayIcon;
  final double playIconSize;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingWidget,
    this.errorWidget,
    this.borderRadius,
    this.showPlayIcon = true,
    this.playIconSize = 48,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  // In-memory cache: url → thumbnail bytes
  static final Map<String, Uint8List> _memCache = {};

  Uint8List? _thumbnail;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget old) {
    super.didUpdateWidget(old);
    if (old.videoUrl != widget.videoUrl) {
      setState(() {
        _thumbnail = null;
        _loading = true;
        _error = false;
      });
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    // ── 1. Check in-memory cache ─────────────────────────────────────────────
    if (_memCache.containsKey(widget.videoUrl)) {
      if (mounted) {
        setState(() {
          _thumbnail = _memCache[widget.videoUrl];
          _loading = false;
        });
      }
      return;
    }

    // ── 2. Check disk cache ──────────────────────────────────────────────────
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheKey = widget.videoUrl.hashCode.toString();
      final cachedFile = File('${cacheDir.path}/vthumb_$cacheKey.jpg');

      if (await cachedFile.exists()) {
        final bytes = await cachedFile.readAsBytes();
        _memCache[widget.videoUrl] = bytes;
        if (mounted) setState(() { _thumbnail = bytes; _loading = false; });
        return;
      }

      // ── 3. Generate thumbnail ─────────────────────────────────────────────
      final Uint8List? bytes = await FlutterVideoThumbnailPlus.thumbnailData(
        video: widget.videoUrl,
        imageFormat: ImageFormat.jpeg,
        maxWidth: 512,        // enough for previews, keeps file small
        quality: 80,
      );

      if (bytes == null || bytes.isEmpty) throw Exception('empty thumbnail');

      // ── 4. Persist to disk + memory ───────────────────────────────────────
      await cachedFile.writeAsBytes(bytes);
      _memCache[widget.videoUrl] = bytes;

      if (mounted) setState(() { _thumbnail = bytes; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_loading) {
      child = widget.loadingWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: const Color(0xFF1E1E1E),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD72638),
                strokeWidth: 1.5,
              ),
            ),
          );
    } else if (_error || _thumbnail == null) {
      child = widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: const Color(0xFF1E1E1E),
            child: const Center(
              child: Icon(
                Icons.videocam_off_outlined,
                color: Color(0x61FFFFFF),
                size: 32,
              ),
            ),
          );
    } else {
      child = Stack(
        alignment: Alignment.center,
        children: [
          Image.memory(
            _thumbnail!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            gaplessPlayback: true,
          ),
          if (widget.showPlayIcon)
            Container(
              width: widget.playIconSize,
              height: widget.playIconSize,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFFFFF),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: const Color(0xFFFFFFFF),
                size: widget.playIconSize * 0.55,
              ),
            ),
        ],
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return SizedBox(width: widget.width, height: widget.height, child: child);
  }
}