import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageViewerPage extends StatefulWidget {
  final String url;
  const ImageViewerPage({super.key, required this.url});

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  bool _showUI = true;

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
    if (_showUI) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// 🔥 PHOTO VIEW (ZOOM WORKS PERFECT)
          GestureDetector(
            onTap: _toggleUI,
            child: PhotoView(
              imageProvider: NetworkImage(widget.url),
              backgroundDecoration:
              const BoxDecoration(color: Colors.black),

              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,

              loadingBuilder: (context, event) {
                return Center(
                  child: CircularProgressIndicator(
                    value: event == null
                        ? null
                        : event.cumulativeBytesLoaded /
                        (event.expectedTotalBytes ?? 1),
                    color: Colors.red,
                  ),
                );
              },

              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white24,
                    size: 80,
                  ),
                );
              },
            ),
          ),

          /// 🔥 TOP BAR
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showUI ? 0 : -100,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),

                child: Row(
                  children: [

                    _glassButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(.08),
            border: Border.all(
              color: Colors.white.withOpacity(.10),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}