import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

const _securityChannel = MethodChannel('com.learnsbuy/security');

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  bool _isPlaying = true;
  bool _showControls = true;
  bool _isMuted = false;
  double _progress = 0.013; // ~30s of 40min demo
  int _currentLesson = 0;
  bool _isFullscreen = false;

  Timer? _controlsTimer;
  Timer? _progressTimer;

  static const _totalSeconds = 40 * 60; // 40 minutes demo

  static const List<_LessonData> _lessons = [
    _LessonData('Hiragana ตอนที่ 1', '20 min', [Color(0xFF2C3E7A), Color(0xFF1A2460)], Icons.text_fields),
    _LessonData('Hiragana ตอนที่ 2', '20 min', [Color(0xFF2C3E7A), Color(0xFF1A2460)], Icons.text_fields),
    _LessonData('การออกเสียง Hiragana พื้นฐาน', '20 min', [Color(0xFFB8860B), Color(0xFF8B6914)], Icons.record_voice_over_rounded),
    _LessonData('Akiko บทที่ 1 การแนะนำตัวและการเรียกขาน', '20 min', [Color(0xFF1565C0), Color(0xFF0D47A1)], Icons.people_rounded),
    _LessonData('Hiragana ตอนที่ 3', '20 min', [Color(0xFF2C3E7A), Color(0xFF1A2460)], Icons.text_fields),
    _LessonData('Hiragana ตอนที่ 1 (เพิ่มเติม)', '20 min', [Color(0xFFE65100), Color(0xFFBF360C)], Icons.add_circle_outline),
    _LessonData('Katakana ตอนที่ 1', '20 min', [Color(0xFF6A1B9A), Color(0xFF4A148C)], Icons.font_download_rounded),
    _LessonData('Katakana ตอนที่ 2', '20 min', [Color(0xFF6A1B9A), Color(0xFF4A148C)], Icons.font_download_rounded),
    _LessonData('คำศัพท์พื้นฐาน บทที่ 1', '25 min', [Color(0xFF00695C), Color(0xFF004D40)], Icons.book_rounded),
    _LessonData('ไวยากรณ์ は・が・を', '30 min', [Color(0xFFC62828), Color(0xFFB71C1C)], Icons.menu_book_rounded),
  ];

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableSecurity();
    _startControlsTimer();
    _startProgressTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlsTimer?.cancel();
    _progressTimer?.cancel();
    _disableSecurity();
    if (_isFullscreen) _exitFullscreen();
    super.dispose();
  }

  Future<void> _enableSecurity() async {
    try {
      await _securityChannel.invokeMethod('enableSecure');
    } catch (_) {}
  }

  Future<void> _disableSecurity() async {
    try {
      await _securityChannel.invokeMethod('disableSecure');
    } catch (_) {}
  }

  // ─── Controls & Progress ───────────────────────────────────────────────────

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    if (_isPlaying) {
      _controlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPlaying && mounted) {
        setState(() {
          _progress = (_progress + 1 / _totalSeconds).clamp(0.0, 1.0);
        });
      }
    });
  }

  void _tapVideo() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    _startControlsTimer();
  }

  void _seek(double delta) {
    setState(() {
      _progress = (_progress + delta / _totalSeconds).clamp(0.0, 1.0);
    });
    _startControlsTimer();
  }

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

  // ─── Time helpers ──────────────────────────────────────────────────────────

  String _fmtTime(double progress, {bool remaining = false}) {
    final cur = (progress * _totalSeconds).round();
    final secs = remaining ? _totalSeconds - cur : cur;
    final m = secs ~/ 60;
    final s = secs % 60;
    final str = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return remaining ? '-$str' : str;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) return _buildFullscreenPlayer();

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
              child: _buildLessonList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenPlayer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _tapVideo,
        child: Stack(
          children: [
            _buildVideoBackground(),
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildControlsOverlay(fullscreen: true),
            ),
          ],
        ),
      ),
    );
  }

  // ─── App Bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Point - 509,849.1',
              style: GoogleFonts.sarabun(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'kim kundad.',
              style: GoogleFonts.sarabun(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Video Area ────────────────────────────────────────────────────────────

  Widget _buildVideoArea() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: _tapVideo,
        child: Stack(
          children: [
            _buildVideoBackground(),
            // Watermark (semi-transparent, harder to remove from recording)
            Positioned(
              bottom: 44,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'kim kundad.  ·  ID:509849  ·  learnsbuy',
                  style: GoogleFonts.sarabun(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.1),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildControlsOverlay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBackground() {
    return Container(
      color: const Color(0xFF0D0D1A),
      child: Stack(
        children: [
          // Subtle gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.2,
                colors: [Color(0xFF1A1A3E), Color(0xFF050510)],
              ),
            ),
          ),
          // ZA-SHI logo center (dim)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                  ),
                  child: Center(
                    child: Text('ホ',
                      style: GoogleFonts.sarabun(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary.withOpacity(0.25),
                      )),
                  ),
                ),
                const SizedBox(height: 8),
                Text('ZA-SHI',
                  style: GoogleFonts.sarabun(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.08),
                    letterSpacing: 4,
                  )),
              ],
            ),
          ),
          // Playing indicator pulse
          if (_isPlaying)
            const Positioned(
              top: 8,
              right: 8,
              child: _PulsingDot(),
            ),
        ],
      ),
    );
  }

  // ─── Controls Overlay ──────────────────────────────────────────────────────

  Widget _buildControlsOverlay({bool fullscreen = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.75),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.85),
          ],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: fullscreen ? _exitFullscreen : _enterFullscreen,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      fullscreen ? Icons.fullscreen_exit_rounded : Icons.open_in_full_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('ZA-SHI',
                    style: GoogleFonts.sarabun(
                      fontSize: 10, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: 1,
                    )),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _isMuted = !_isMuted),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white, size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Center play controls
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _controlBtn(Icons.replay_10_rounded, size: 44, onTap: () => _seek(-10)),
                const SizedBox(width: 28),
                _controlBtn(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 60,
                  primary: true,
                  onTap: _togglePlay,
                ),
                const SizedBox(width: 28),
                _controlBtn(Icons.forward_10_rounded, size: 44, onTap: () => _seek(10)),
              ],
            ),
          ),
          // Bottom progress + time
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppTheme.primary,
                    inactiveTrackColor: Colors.white.withOpacity(0.25),
                    thumbColor: Colors.white,
                    overlayColor: AppTheme.primary.withOpacity(0.3),
                  ),
                  child: Slider(
                    value: _progress,
                    onChanged: (v) => setState(() => _progress = v),
                    onChangeStart: (_) => _controlsTimer?.cancel(),
                    onChangeEnd: (_) => _startControlsTimer(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmtTime(_progress),
                      style: GoogleFonts.sarabun(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    Text(_fmtTime(_progress, remaining: true),
                      style: GoogleFonts.sarabun(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, {double size = 44, bool primary = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: primary
              ? AppTheme.primary.withOpacity(0.9)
              : Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: primary ? Border.all(color: Colors.white.withOpacity(0.3), width: 1.5) : null,
          boxShadow: primary
              ? [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 16, spreadRadius: 2)]
              : null,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.55),
      ),
    );
  }

  // ─── Lesson List ───────────────────────────────────────────────────────────

  Widget _buildLessonList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _lessons.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) return _buildListHeader();
        return _buildLessonRow(_lessons[i - 1], i - 1);
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
          Text('${_lessons.length} Lessons',
            style: GoogleFonts.sarabun(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          const Spacer(),
          Text('ทั้งหมด ${_lessons.length * 20} นาที',
            style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.textLight)),
        ],
      ),
    );
  }

  Widget _buildLessonRow(_LessonData lesson, int index) {
    final isActive = index == _currentLesson;
    return GestureDetector(
      onTap: () => setState(() {
        _currentLesson = index;
        _progress = 0;
        _isPlaying = true;
        _showControls = true;
        _startControlsTimer();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryLight.withOpacity(0.6) : Colors.white,
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
                Container(
                  width: 104,
                  height: 66,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: lesson.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Course ID overlay
                      Positioned(
                        top: 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('ZA-SHI',
                            style: GoogleFonts.sarabun(
                              fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ),
                      Center(
                        child: Icon(lesson.icon, color: Colors.white.withOpacity(0.3), size: 28),
                      ),
                    ],
                  ),
                ),
                // Active overlay
                if (isActive)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.pause_circle_filled_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                // Episode number badge
                Positioned(
                  bottom: 5, right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(lesson.duration,
                      style: GoogleFonts.sarabun(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
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
                    lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sarabun(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? AppTheme.primary : AppTheme.textDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 11, color: AppTheme.textLight),
                      const SizedBox(width: 3),
                      Text(lesson.duration,
                        style: GoogleFonts.sarabun(fontSize: 11, color: AppTheme.textLight)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : AppTheme.primaryLight,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]
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
}

// ─── Pulsing Live Dot ─────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
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
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _LessonData {
  final String title, duration;
  final List<Color> gradient;
  final IconData icon;

  const _LessonData(this.title, this.duration, this.gradient, this.icon);
}
