import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

const _securityChannel = MethodChannel('com.learnsbuy/security');

// ── How point deduction works ────────────────────────────────────────────────
// • Fetch current point on screen open via POST /api/get_point_v2
// • Track actual play seconds with a 1-second periodic ticker
// • Every 60 actual play seconds → deduct 1 point via /api/del_point_v4
// • Seeking forward does NOT count — only real watch time accumulates
// • Ticker pauses (skips increment) when video is paused
// • Accumulated seconds preserved across pause/resume within same video
// • Switching video resets accumulated seconds to 0
// • If point reaches 0 → pause video & show "no points" dialog
// ── Video resume (YouTube-style) ─────────────────────────────────────────────
// • Save current time to SharedPreferences key "vp_{videoId}" every ~10 s
// • On load: if saved time > 30 s, inject JS to seek to that position
// ─────────────────────────────────────────────────────────────────────────────

class VideoPlayerScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const VideoPlayerScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  bool _isFullscreen = false;
  bool _loading = true;

  List<Map<String, dynamic>> _videos = [];
  int _currentIndex = 0;
  WebViewController? _webCtrl;

  // watermark
  String _userName = '';
  int _userId = 0;

  // point
  int _point = 0;
  bool _pointLoaded = false;

  // point deduction — accumulator-based (1 point per 60 real play seconds)
  bool _isVideoPlaying = false;
  bool _deductInFlight = false;
  Timer? _watchTicker;
  int _watchedSeconds = 0;

  // video id of current video (for resume key)
  int? _currentVideoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecurity();
    _loadUserProfile();
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopWatchTicker();
    _disableSecurity();
    if (_isFullscreen) _exitFullscreen();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      setState(() => _isVideoPlaying = false);
    }
  }

  // ── Security ───────────────────────────────────────────────────────────────

  Future<void> _enableSecurity() async {
    try { await _securityChannel.invokeMethod('enableSecure'); } catch (_) {}
  }

  Future<void> _disableSecurity() async {
    try { await _securityChannel.invokeMethod('disableSecure'); } catch (_) {}
  }

  // ── User profile (watermark) ───────────────────────────────────────────────

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_profile');
    if (raw == null || !mounted) return;
    try {
      final profile = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _userName = (profile['name'] as String?) ?? '';
        _userId   = (profile['id'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {}
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _loadInitialData() async {
    await Future.wait([_fetchPoint(), _loadVideos()]);
  }

  Future<void> _fetchPoint() async {
    try {
      final p = await ApiService.instance.getPoint();
      if (!mounted) return;
      if (p == 0) {
        setState(() { _point = 0; _pointLoaded = true; });
        _showNoPointDialog();
        return;
      }
      setState(() { _point = p; _pointLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _pointLoaded = true);
    }
  }

  Future<void> _loadVideos() async {
    try {
      final data = await ApiService.instance.getFileApp(widget.courseId);
      final videos = (data['video'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _loading = false;
      });
      if (videos.isNotEmpty) _playVideo(0);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Point deduction ────────────────────────────────────────────────────────

  void _stopWatchTicker() {
    _watchTicker?.cancel();
    _watchTicker = null;
  }

  // Start a 1-second tick; only increments when video is actually playing.
  // Preserved across pause/resume so 45s watched + pause + 15s = 1 point.
  void _startWatchTicker() {
    _watchTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isVideoPlaying || !mounted) return;
      _watchedSeconds++;
      if (_watchedSeconds >= 60) {
        _watchedSeconds = 0;
        _doDeductPoint();
      }
      setState(() {}); // rebuild progress ring every second
    });
  }

  Future<void> _doDeductPoint() async {
    if (_deductInFlight || !mounted) return;
    _deductInFlight = true;
    try {
      final newPoint = await ApiService.instance.deductPoint();
      if (!mounted) return;
      setState(() => _point = newPoint);
      if (newPoint == 0) {
        _stopWatchTicker();
        setState(() => _isVideoPlaying = false);
        _webCtrl?.runJavaScript('document.querySelector("video").pause()');
        _showNoPointDialog();
      }
    } catch (_) {
      // network error — pause video until connection is restored
      if (!mounted) return;
      _stopWatchTicker();
      setState(() => _isVideoPlaying = false);
      _webCtrl?.runJavaScript('document.querySelector("video").pause()');
      _showNoNetworkDialog();
    } finally {
      _deductInFlight = false;
    }
  }

  void _showNoNetworkDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ไม่มีการเชื่อมต่อ',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansThai(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: AppTheme.textDark),
        ),
        content: Text(
          'กรุณาตรวจสอบอินเทอร์เน็ตแล้วกด "ดูต่อ"\nระบบจะหัก Point เมื่อเชื่อมต่อได้แล้ว',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansThai(
              fontSize: 14, color: AppTheme.textMedium, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // ลอง deduct ทันที ถ้าสำเร็จค่อย resume
              _deductInFlight = false;
              await _doDeductPoint();
              if (mounted && _point > 0) {
                _webCtrl?.runJavaScript('document.querySelector("video").play()');
                setState(() => _isVideoPlaying = true);
                _startWatchTicker();
              }
            },
            child: Text('ดูต่อ',
                style: GoogleFonts.notoSansThai(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _onVideoPlay() {
    if (!mounted) return;
    setState(() => _isVideoPlaying = true);
    _startWatchTicker();
  }

  void _onVideoPause() {
    if (!mounted) return;
    setState(() => _isVideoPlaying = false);
    // ticker keeps running but skips increments while _isVideoPlaying is false
  }

  // ── Video progress (resume) ────────────────────────────────────────────────

  String _progressKey(int videoId) => 'vp_$videoId';

  Future<double> _getSavedPosition(int videoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_progressKey(videoId)) ?? 0.0;
  }

  Future<void> _savePosition(int videoId, double seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_progressKey(videoId), seconds);
  }

  void _onTimeUpdate(int videoId, double seconds) {
    _savePosition(videoId, seconds);
  }

  Future<void> _markVideoCompleted(int videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cdone_${widget.courseId}';
    final done = prefs.getStringList(key) ?? [];
    if (!done.contains('$videoId')) {
      done.add('$videoId');
      await prefs.setStringList(key, done);
    }
  }

  // ── Video playback ─────────────────────────────────────────────────────────

  Future<void> _playVideo(int index) async {
    if (index < 0 || index >= _videos.length) return;
    _stopWatchTicker();
    _watchedSeconds = 0;
    setState(() {
      _isVideoPlaying = false;
      _currentIndex = index;
      _webCtrl = null;
    });

    final v       = _videos[index];
    final videoId = (v['id'] as num?)?.toInt() ?? index;
    final thumb   = (v['thumbnail_img'] as String?) ?? '';
    final poster  = thumb.isNotEmpty ? '${AppConfig.uploadsBase}$thumb' : '';

    _currentVideoId = videoId;

    String videoUrl;
    try {
      videoUrl = await ApiService.instance.getSignedVideoUrl(videoId);
    } catch (_) {
      videoUrl = (v['course_video_url'] as String?) ?? '';
    }
    if (videoUrl.isEmpty || !mounted) return;

    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'VideoChannel',
        onMessageReceived: (msg) => _onJsMessage(videoId, msg.message),
      )
      ..loadHtmlString(_videoHtml(videoUrl, poster));

    if (!mounted) return;
    setState(() => _webCtrl = ctrl);
  }

  void _onJsMessage(int videoId, String msg) {
    if (msg == 'play')  { _onVideoPlay();  return; }
    if (msg == 'pause') { _onVideoPause(); return; }
    if (msg == 'ended') {
      _onVideoPause();
      _savePosition(videoId, 0);
      return;
    }
    if (msg == 'completed') {
      _markVideoCompleted(videoId);
      return;
    }
    if (msg.startsWith('time:')) {
      final secs = double.tryParse(msg.substring(5)) ?? 0;
      _onTimeUpdate(videoId, secs);
      return;
    }
    if (msg == 'ready') {
      // video metadata loaded → seek to saved position
      _getSavedPosition(videoId).then((savedTime) {
        if (savedTime > 30 && _webCtrl != null) {
          _webCtrl!.runJavaScript(
            'document.querySelector("video").currentTime = $savedTime;'
          );
        }
      });
    }
  }

  String _videoHtml(String videoUrl, String poster) => '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    html,body{background:#000;width:100%;height:100%;overflow:hidden}
    video{width:100%;height:100%;object-fit:contain;display:block}
  </style>
</head>
<body>
  <video controls controlsList="nodownload" playsinline preload="metadata"${poster.isNotEmpty ? ' poster="$poster"' : ''}>
    <source src="$videoUrl" type="video/mp4">
  </video>
  <script>
    var video = document.querySelector('video');
    var lastT = -1;
    video.addEventListener('loadedmetadata', function() {
      window.VideoChannel.postMessage('ready');
    });
    video.addEventListener('play', function() {
      window.VideoChannel.postMessage('play');
    });
    video.addEventListener('pause', function() {
      window.VideoChannel.postMessage('pause');
    });
    video.addEventListener('ended', function() {
      window.VideoChannel.postMessage('ended');
    });
    var completed = false;
    video.addEventListener('timeupdate', function() {
      var t = Math.floor(video.currentTime);
      if (t !== lastT && t % 10 === 0) {
        lastT = t;
        window.VideoChannel.postMessage('time:' + video.currentTime);
      }
      if (!completed && video.duration > 0 &&
          video.currentTime / video.duration >= 0.9) {
        completed = true;
        window.VideoChannel.postMessage('completed');
      }
    });
  </script>
</body>
</html>
''';

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showNoPointDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Point หมดแล้ว',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansThai(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: AppTheme.textDark),
        ),
        content: Text(
          'กรุณาติดต่อเจ้าหน้าที่ LINE : @ZA-SHI\nเพื่อเติม Point',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansThai(
              fontSize: 14, color: AppTheme.textMedium, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (context.canPop()) context.pop();
            },
            child: Text('OK',
                style: GoogleFonts.notoSansThai(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  // ── Fullscreen ─────────────────────────────────────────────────────────────

  void _enterFullscreen() {
    setState(() => _isFullscreen = true);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    setState(() => _isFullscreen = false);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) return _buildFullscreen();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(),
                _buildVideoArea(),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildLessonList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _webCtrl != null
              ? WebViewWidget(controller: _webCtrl!)
              : const SizedBox.expand(),
          _buildWatermark(),
          Positioned(
            top: 16, left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: _exitFullscreen,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fullscreen_exit_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: Colors.white, size: 28),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          Expanded(
            child: Text(
              widget.courseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansThai(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          // Point badge with progress ring
          if (_pointLoaded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18, height: 18,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _isVideoPlaying
                              ? _watchedSeconds / 60.0
                              : 0,
                          strokeWidth: 2,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        ),
                        const Icon(Icons.stars_rounded,
                            color: Colors.white, size: 10),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_point',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'point',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWatermark() {
    if (_userName.isEmpty && _userId == 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Transform.rotate(
            angle: -0.25,
            child: Opacity(
              opacity: 0.22,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: $_userId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
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

  Widget _buildVideoArea() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          _webCtrl != null
              ? WebViewWidget(controller: _webCtrl!)
              : Container(
                  color: const Color(0xFF0D0D1A),
                  child: Center(
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('เลือกบทเรียน',
                            style: GoogleFonts.notoSansThai(
                                color: Colors.white54, fontSize: 16)),
                  ),
                ),
          _buildWatermark(),
          if (_isVideoPlaying)
            const Positioned(
              top: 8, right: 8,
              child: _PulsingDot(),
            ),
          Positioned(
            bottom: 10, right: 10,
            child: GestureDetector(
              onTap: _enterFullscreen,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.open_in_full_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lesson list ────────────────────────────────────────────────────────────

  Widget _buildLessonList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _videos.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) return _buildListHeader();
        return _buildLessonRow(_videos[i - 1], i - 1);
      },
    );
  }

  Widget _buildListHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 4, height: 22,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text('${_videos.length} บทเรียน',
              style: GoogleFonts.notoSansThai(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const Spacer(),
          // hint about resume feature
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_rounded,
                  size: 13, color: AppTheme.textLight),
              const SizedBox(width: 3),
              Text('บันทึกตำแหน่งอัตโนมัติ',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 11, color: AppTheme.textLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonRow(Map<String, dynamic> v, int index) {
    final isActive  = index == _currentIndex;
    final name      = (v['course_video_name'] as String?) ?? 'บทเรียนที่ ${index + 1}';
    final duration  = (v['time_video'] as String?) ?? '';
    final thumbFile = (v['thumbnail_img'] as String?) ?? '';
    final thumbUrl  = thumbFile.isNotEmpty
        ? '${AppConfig.uploadsBase}$thumbFile'
        : '';

    return GestureDetector(
      onTap: () => _playVideo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryLight.withOpacity(0.6)
              : Colors.white,
          border: Border(
            left: BorderSide(
              color: isActive ? AppTheme.primary : Colors.transparent,
              width: 3,
            ),
            bottom: BorderSide(color: AppTheme.border.withOpacity(0.5)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 104, height: 66,
                    child: thumbUrl.isNotEmpty
                        ? Image.network(
                            thumbUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _thumbPlaceholder(index),
                          )
                        : _thumbPlaceholder(index),
                  ),
                ),
                if (isActive)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                        child: const Center(
                          child: Icon(Icons.pause_circle_filled_rounded,
                              color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                  ),
                if (duration.isNotEmpty)
                  Positioned(
                    bottom: 5, right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(duration,
                          style: GoogleFonts.notoSansThai(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (!isActive)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? AppTheme.primary : AppTheme.textDark,
                      height: 1.4,
                    ),
                  ),
                  if (duration.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 11, color: AppTheme.textLight),
                        const SizedBox(width: 3),
                        Text(duration,
                            style: GoogleFonts.notoSansThai(
                                fontSize: 11, color: AppTheme.textLight)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : AppTheme.primaryLight,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3))]
                    : null,
              ),
              child: Icon(
                isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isActive ? Colors.white : AppTheme.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(int index) {
    const colors = [
      Color(0xFF2C3E7A), Color(0xFFB8860B), Color(0xFF1565C0),
      Color(0xFFE65100), Color(0xFF6A1B9A), Color(0xFF00695C),
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[index % colors.length],
            colors[index % colors.length].withOpacity(0.7)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_outline,
            color: Colors.white38, size: 28),
      ),
    );
  }
}

// ── Pulsing "live" dot ─────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(
            color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}
