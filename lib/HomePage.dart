import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:untitled1/video_thumbnail_widget.dart';
import 'dart:io';
import 'Api_Key.dart';
import 'image_cache_manager.dart';
import 'main.dart';
import 'LoginPage.dart';
import 'VideoPlayerPage.dart';
import 'ImageViewerPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MediaFilter { all, photos, videos }

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List   posts       = [];
  bool   isLoading   = true;
  bool   isUploading = false;

  MediaFilter _activeFilter = MediaFilter.all;

  final picker = ImagePicker();
  late AnimationController _fabAnimController;
  late AnimationController _listAnimController;
  bool _fabOpen = false;

  List get _filtered {
    if (_activeFilter == MediaFilter.photos) {
      return posts.where((p) => p['type'] != 'video').toList();
    } else if (_activeFilter == MediaFilter.videos) {
      return posts.where((p) => p['type'] == 'video').toList();
    }
    return posts;
  }

  int get _photoCount => posts.where((p) => p['type'] != 'video').length;
  int get _videoCount => posts.where((p) => p['type'] == 'video').length;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _fabAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _listAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    loadPosts();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  Future<void> loadPosts() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.getpostUrl));
      setState(() {
        posts     = jsonDecode(res.body);
        isLoading = false;
      });
      _listAnimController.forward(from: 0);
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future pickImage() async {
    _toggleFab();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) await upload(File(file.path), "image");
  }

  Future pickVideo() async {
    _toggleFab();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file != null) await upload(File(file.path), "video");
  }

  Future upload(File file, String type) async {
    setState(() => isUploading = true);
    final request = http.MultipartRequest(
        "POST", Uri.parse(ApiConfig.uploadpostUrl));
    request.fields['user_id'] = widget.userId;
    request.fields['type']    = type;
    request.files.add(await http.MultipartFile.fromPath("file", file.path));
    await request.send();
    setState(() => isUploading = false);
    loadPosts();
  }

  Future logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("user_id");
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  void _toggleFab() {
    setState(() => _fabOpen = !_fabOpen);
    _fabOpen ? _fabAnimController.forward() : _fabAnimController.reverse();
  }

  int _crossAxisCount(double width) {
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              if (!isLoading && posts.isNotEmpty)
                SliverToBoxAdapter(child: _buildStatsBar()),
              if (!isLoading && posts.isNotEmpty)
                SliverToBoxAdapter(child: _buildFilterRow()),
              SliverToBoxAdapter(
                child: isLoading
                    ? _buildLoader()
                    : _filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildGalleryBody(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          if (isUploading) _buildUploadBanner(),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.bg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        titlePadding: const EdgeInsets.only(left: 20, bottom: 7),
        title: const _AppBarTitle(),
        background: _AppBarBackground(isUploading: isUploading),
      ),
      actions: [
        _AppBarAction(
          icon: Icons.refresh_rounded,
          onTap: loadPosts,
          tooltip: "Refresh",
        ),
        _AppBarAction(
          icon: Icons.logout_rounded,
          onTap: _showLogoutDialog,
          tooltip: "Sign out",
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Stats bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatChip(
            value: posts.length.toString(),
            label: "Total",
            icon: Icons.grid_view_rounded,
            color: AppColors.red,
          ),
          _buildStatDivider(),
          _StatChip(
            value: _photoCount.toString(),
            label: "Photos",
            icon: Icons.image_rounded,
            color: const Color(0xFF3B82F6),
          ),
          _buildStatDivider(),
          _StatChip(
            value: _videoCount.toString(),
            label: "Videos",
            icon: Icons.videocam_rounded,
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() => Container(
      width: 1,
      height: 32,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 12));

  // ── Filter row ────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _FilterChip(
            label: "All",
            icon: Icons.grid_view_rounded,
            active: _activeFilter == MediaFilter.all,
            onTap: () => setState(() {
              _activeFilter = MediaFilter.all;
              _listAnimController.forward(from: 0);
            }),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: "Photos",
            icon: Icons.image_rounded,
            active: _activeFilter == MediaFilter.photos,
            onTap: () => setState(() {
              _activeFilter = MediaFilter.photos;
              _listAnimController.forward(from: 0);
            }),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: "Videos",
            icon: Icons.videocam_rounded,
            active: _activeFilter == MediaFilter.videos,
            onTap: () => setState(() {
              _activeFilter = MediaFilter.videos;
              _listAnimController.forward(from: 0);
            }),
          ),
          const Spacer(),
          Text(
            "${_filtered.length} item${_filtered.length == 1 ? '' : 's'}",
            style: const TextStyle(color: AppColors.inkLight, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Gallery body ──────────────────────────────────────────────────────────
  Widget _buildGalleryBody() {
    final items = _filtered;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          if (items.isNotEmpty) ...[
            _FeaturedCard(
              item: items[0],
              index: 0,
              baseUrl: ApiConfig.baseUrl,
              animController: _listAnimController,
              onTap: () => _openMedia(items[0], 0),
            ),
            const SizedBox(height: 10),
          ],
          if (items.length > 1)
            LayoutBuilder(
              builder: (_, constraints) {
                final cols = _crossAxisCount(constraints.maxWidth);
                final rest = items.sublist(1);
                return _StaggeredGrid(
                  items: rest,
                  cols: cols,
                  baseUrl: ApiConfig.baseUrl,
                  animController: _listAnimController,
                  startIndex: 1,
                  onTap: _openMedia,
                );
              },
            ),
        ],
      ),
    );
  }

  void _openMedia(dynamic item, int index) {
    final url = "${ApiConfig.baseUrl}/uploads/${item['file_name']}";
    Navigator.push(
      context,
      _fadeRoute(item['type'] == 'video'
          ? VideoPlayerPage(url: url)
          : ImageViewerPage(url: url)),
    );
  }

  // ── Upload banner ─────────────────────────────────────────────────────────
  Widget _buildUploadBanner() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: AppColors.red, strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              const Text(
                "Uploading…",
                style: TextStyle(color: AppColors.inkMid, fontSize: 14),
              ),
              const Spacer(),
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.surface2,
                  color: AppColors.red,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withOpacity(0.10),
                    blurRadius: 20,
                  )
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                    color: AppColors.red, strokeWidth: 2.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Loading gallery…",
                style: TextStyle(color: AppColors.inkLight, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.redLight,
                border: Border.all(color: AppColors.red.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withOpacity(0.08),
                    blurRadius: 32,
                  )
                ],
              ),
              child: const Icon(Icons.photo_library_outlined,
                  color: AppColors.red, size: 38),
            ),
            const SizedBox(height: 22),
            const Text("Nothing here yet",
                style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              _activeFilter == MediaFilter.all
                  ? "Tap + to upload your first photo or video"
                  : "No ${_activeFilter == MediaFilter.photos ? 'photos' : 'videos'} yet",
              style: const TextStyle(color: AppColors.inkLight, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── Speed dial ────────────────────────────────────────────────────────────
  Widget _buildSpeedDial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _FabOption(
            visible: _fabOpen,
            delay: 200,
            label: "Video",
            icon: Icons.videocam_rounded,
            heroTag: "video_fab",
            onTap: pickVideo),
        _FabOption(
            visible: _fabOpen,
            delay: 120,
            label: "Photo",
            icon: Icons.image_rounded,
            heroTag: "image_fab",
            onTap: pickImage),
        FloatingActionButton(
          heroTag: "main_fab",
          onPressed: _toggleFab,
          backgroundColor: AppColors.red,
          elevation: 6,
          child: AnimatedRotation(
            turns: _fabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Sign out?",
            style: TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w700)),
        content: const Text(
            "You'll need to sign in again to access your gallery.",
            style: TextStyle(color: AppColors.inkMid)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(color: AppColors.inkLight))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                logout(context);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
              child: const Text("Sign out",
                  style: TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, anim, __) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 280),
  );
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.red),
            ),
            const SizedBox(width: 6),
            Text(
              "Galler Nas",
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 3,
                color: AppColors.red.withOpacity(0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Text(
          "Gallery",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _AppBarBackground extends StatelessWidget {
  final bool isUploading;
  const _AppBarBackground({required this.isUploading});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Warm off-white gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF0F1), // redLight tint top-left
                Color(0xFFF7F5F2), // bg color
                Color(0xFFF7F5F2),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        // Soft red bloom top-right
        Positioned(
          right: -60,
          top: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [Color(0x18D72638), Colors.transparent]),
            ),
          ),
        ),
        // Tiny warm accent bottom-left
        Positioned(
          left: 40,
          bottom: 10,
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [Color(0x10D72638), Colors.transparent]),
            ),
          ),
        ),
        // Bottom separator
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(height: 1, color: AppColors.border),
        ),
        // Upload progress line
        if (isUploading)
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppColors.red,
                minHeight: 2),
          ),
      ],
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _AppBarAction(
      {required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.inkMid, size: 18),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatChip(
      {required this.value,
        required this.label,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.inkLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
        required this.icon,
        required this.active,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.red : AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? AppColors.red : AppColors.border,
            width: 1,
          ),
          boxShadow: active
              ? [
            BoxShadow(
                color: AppColors.red.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? Colors.white : AppColors.inkMid),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.inkMid,
                )),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final dynamic item;
  final int index;
  final String baseUrl;
  final AnimationController animController;
  final VoidCallback onTap;
  const _FeaturedCard(
      {required this.item,
        required this.index,
        required this.baseUrl,
        required this.animController,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String url   = "$baseUrl/uploads/${item['file_name']}";
    final bool isVideo = item['type'] == 'video';

    return FadeTransition(
      opacity: CurvedAnimation(
          parent: animController, curve: const Interval(0.0, 0.6)),
      child: SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: animController,
            curve: const Interval(0.0, 0.6,
                curve: Curves.easeOutCubic))),
        child: GestureDetector(
          onTap: onTap,
          child: Hero(
            tag: isVideo ? "video_0" : "image_$url",
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.surface2,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.red.withOpacity(0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isVideo)
                    VideoThumbnailWidget(
                      videoUrl: url,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      showPlayIcon: false,
                    )
                  else
                    AppCachedImage(
                      url: url,
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                    ),

                  // Bottom scrim — softer on light theme
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),

                  // Featured label
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.red.withOpacity(0.4),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded,
                              size: 11, color: Colors.white),
                          SizedBox(width: 4),
                          Text("FEATURED",
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),

                  // Bottom info row
                  Positioned(
                    bottom: 14,
                    left: 14,
                    right: 14,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  isVideo
                                      ? Icons.play_circle_filled_rounded
                                      : Icons.image_rounded,
                                  size: 12,
                                  color: Colors.white),
                              const SizedBox(width: 4),
                              Text(isVideo ? "VIDEO" : "PHOTO",
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isVideo
                                ? AppColors.red
                                : Colors.white.withOpacity(0.2),
                          ),
                          child: Icon(
                              isVideo
                                  ? Icons.play_arrow_rounded
                                  : Icons.open_in_full_rounded,
                              color: Colors.white,
                              size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggeredGrid extends StatelessWidget {
  final List items;
  final int cols;
  final String baseUrl;
  final AnimationController animController;
  final int startIndex;
  final void Function(dynamic, int) onTap;
  const _StaggeredGrid(
      {required this.items,
        required this.cols,
        required this.baseUrl,
        required this.animController,
        required this.startIndex,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final columns = List.generate(cols, (_) => <MapEntry<int, dynamic>>[]);
    for (var i = 0; i < items.length; i++) {
      columns[i % cols].add(MapEntry(i + startIndex, items[i]));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(cols, (col) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left:  col == 0 ? 0 : 5,
              right: col == cols - 1 ? 0 : 5,
            ),
            child: Column(
              children: columns[col].map((entry) {
                final tall  = entry.key % 3 != 2;
                final delay = (entry.key * 80).clamp(0, 500);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AnimatedCard(
                    item: entry.value,
                    index: entry.key,
                    baseUrl: baseUrl,
                    animController: animController,
                    delayMs: delay,
                    height: tall ? 180.0 : 130.0,
                    onTap: () => onTap(entry.value, entry.key),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }),
    );
  }
}

class _AnimatedCard extends StatelessWidget {
  final dynamic item;
  final int index;
  final String baseUrl;
  final AnimationController animController;
  final int delayMs;
  final double height;
  final VoidCallback onTap;
  const _AnimatedCard(
      {required this.item,
        required this.index,
        required this.baseUrl,
        required this.animController,
        required this.delayMs,
        required this.height,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final start = (delayMs / 800).clamp(0.0, 0.8);
    final end   = (start + 0.4).clamp(0.0, 1.0);
    final curve = Interval(start, end, curve: Curves.easeOutCubic);

    return FadeTransition(
      opacity: CurvedAnimation(parent: animController, curve: curve),
      child: SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(CurvedAnimation(parent: animController, curve: curve)),
        child: _MediaCard(
            item: item,
            index: index,
            baseUrl: baseUrl,
            height: height,
            onTap: onTap),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final dynamic item;
  final int index;
  final String baseUrl;
  final double height;
  final VoidCallback onTap;
  const _MediaCard(
      {required this.item,
        required this.index,
        required this.baseUrl,
        required this.height,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String url   = "$baseUrl/uploads/${item['file_name']}";
    final bool isVideo = item['type'] == 'video';

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: isVideo ? "video_$index" : "image_${url}_$index",
        child: Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surface2,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isVideo)
                VideoThumbnailWidget(
                  videoUrl: url,
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover,
                  showPlayIcon: false,
                )
              else
                AppCachedImage(
                  url: url,
                  width: double.infinity,
                  height: height,
                  fit: BoxFit.cover,
                ),

              // Softer bottom scrim
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Type badge
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVideo
                        ? AppColors.red.withOpacity(0.92)
                        : Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          isVideo
                              ? Icons.play_circle_filled_rounded
                              : Icons.image_rounded,
                          size: 10,
                          color: Colors.white),
                      const SizedBox(width: 3),
                      Text(isVideo ? "VIDEO" : "PHOTO",
                          style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),

              // Video play button
              if (isVideo)
                Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.red.withOpacity(0.92),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.red.withOpacity(0.4),
                            blurRadius: 16)
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FabOption extends StatelessWidget {
  final bool visible;
  final int delay;
  final String label;
  final IconData icon;
  final String heroTag;
  final VoidCallback onTap;
  const _FabOption(
      {required this.visible,
        required this.delay,
        required this.label,
        required this.icon,
        required this.heroTag,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: delay),
      alignment: Alignment.bottomRight,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: Duration(milliseconds: delay),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.inkMid,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 10),
              FloatingActionButton.small(
                heroTag: heroTag,
                onPressed: onTap,
                backgroundColor: AppColors.surface,
                elevation: 4,
                child: Icon(icon, color: AppColors.red, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}