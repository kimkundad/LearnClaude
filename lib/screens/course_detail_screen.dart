import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? courseData;
  const CourseDetailScreen({super.key, this.courseData});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _tabIndex     = 0;
  bool _showFullDesc = false;
  bool _isOwned     = false;
  bool _isLoggedIn  = false;
  String? _endDay;

  // detail data
  bool _detailLoading = true;
  Map<String, dynamic> _course    = {};
  List<Map<String, dynamic>> _exVideos = [];
  List<Map<String, dynamic>> _videos   = [];
  List<dynamic> _exercises = [];
  bool _exercisesLoaded = false;
  int _selectedEx = 0;

  // reviews
  bool _reviewsLoading = false;
  bool _reviewsLoaded  = false;
  List<Map<String, dynamic>> _reviewList = [];
  double _avgRating  = 0;
  int _totalReviews  = 0;
  Map<int, int> _ratingDist = {};
  bool _hasMyReview     = false;
  int  _myRating        = 5;
  final TextEditingController _reviewCtrl = TextEditingController();
  bool _submittingReview = false;
  int  _currentUserId   = 0;

  // media controller
  WebViewController? _mediaCtrl;

  static const _thumbBase = 'https://learnsbuy.com/assets/uploads/';
  static const _imgBase   = 'https://learnsbuy.com/assets/uploads/';

  // ── computed helpers ───────────────────────────────────────────────────────

  int get _courseId {
    final raw = widget.courseData?['id']
        ?? widget.courseData?['c_id']
        ?? widget.courseData?['course_id'];
    return (raw as num?)?.toInt() ?? 0;
  }

  String get _title    => (_course['title_course']     as String?) ??
      (widget.courseData?['title_course'] as String?) ?? 'รายละเอียดคอร์ส';
  String get _desc     => (_course['detail_course']    as String?) ?? '';
  int    get _price    => (_course['price_course']     as num?)?.toInt() ??
      (widget.courseData?['price_course'] as num?)?.toInt() ?? 0;
  int    get _students => (widget.courseData?['student_count'] as num?)?.toInt() ?? 0;
  String get _duration => (_course['time_course_text'] as String?) ?? '';
  String? get _youtubeUrl => (_course['url_youtube'] as String?)?.isNotEmpty == true
      ? _course['url_youtube'] as String : null;
  String? get _imageFile  => (_course['image_course']  as String?);

  bool get _isExpired {
    final d = _endDay;
    if (d == null || d.isEmpty) return false;
    try {
      final exp = DateTime.parse(d);
      final expDate = DateTime(exp.year, exp.month, exp.day);
      final today   = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      return todayDate.isAfter(expDate);
    } catch (_) { return false; }
  }

  static const _thMonthsShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  String get _endDayFormatted {
    final d = _endDay;
    if (d == null || d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day} ${_thMonthsShort[dt.month - 1]} ${dt.year + 543}';
    } catch (_) { return d; }
  }

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // ถ้ามาจาก MyCourseScreen (มี key 'course_id') แสดงว่าซื้อแล้ว
    if (widget.courseData?.containsKey('course_id') == true) {
      _isOwned = true;
    }
    _endDay = widget.courseData?['end_day'] as String?;
    print('>>> [initState] end_day from courseData: $_endDay');
    _checkLogin();
    if (_courseId > 0) {
      _loadDetail();
    } else {
      _initMediaFromCourseData();
      setState(() => _detailLoading = false);
    }
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkLogin() async {
    final token = await AuthService.instance.getToken();
    if (mounted) setState(() => _isLoggedIn = token != null);
  }

  Future<void> _loadDetail() async {
    try {
      final data = await ApiService.instance.getCourseDetail(_courseId);
      print('>>> course detail keys: ${data.keys}');
      print('>>> end_day: ${data['end_day']}');
      print('>>> submitcourse: ${data['submitcourse']}');
      print('>>> is_owned: ${data['is_owned']}');
      if (!mounted) return;
      final course   = Map<String, dynamic>.from(data['course'] as Map);
      final exVideos = (data['ex_video'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final videos   = (data['videos'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final isOwned = data['is_owned'] == true;
      String? endDay = (data['end_day'] as String?)
          ?? (data['submitcourse']?['end_day'] as String?)
          ?? _endDay;

      // ถ้า owned แต่ยังไม่มี end_day → ดึงจาก my-courses
      if (isOwned && (endDay == null || endDay.isEmpty)) {
        try {
          final myCourses = await ApiService.instance.getMyCourses();
          final match = myCourses.cast<Map<String, dynamic>>().firstWhere(
            (c) => (c['course_id'] as num?)?.toInt() == _courseId
                || (c['id'] as num?)?.toInt() == _courseId,
            orElse: () => {},
          );
          if (match.isNotEmpty) {
            endDay = match['end_day'] as String?;
          }
        } catch (_) {}
      }

      setState(() {
        _course   = course;
        _exVideos = exVideos;
        _videos   = videos;
        _isOwned  = isOwned;
        _endDay   = endDay;
        _detailLoading = false;
      });
      _initMedia();
    } catch (_) {
      if (mounted) setState(() => _detailLoading = false);
      _initMediaFromCourseData();
    }
  }

  Future<void> _loadReviews() async {
    if (_reviewsLoaded || _courseId <= 0) return;
    setState(() => _reviewsLoading = true);
    try {
      final data = await ApiService.instance.getReviews(_courseId);
      final reviews = (data['reviews'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final dist = Map<String, dynamic>.from(data['distribution'] as Map? ?? {});

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_profile');
      int uid = 0;
      if (raw != null) {
        try {
          final p = jsonDecode(raw) as Map<String, dynamic>;
          uid = (p['id'] as num?)?.toInt() ?? 0;
        } catch (_) {}
      }

      final myReview = reviews.where(
        (r) => (r['user_id'] as num?)?.toInt() == uid
      ).firstOrNull;

      if (!mounted) return;
      setState(() {
        _reviewList   = reviews;
        _avgRating    = (data['average'] as num?)?.toDouble() ?? 0;
        _totalReviews = (data['total'] as num?)?.toInt() ?? 0;
        _ratingDist   = {
          for (int i = 1; i <= 5; i++)
            i: (dist['$i'] as num?)?.toInt() ?? 0,
        };
        _currentUserId = uid;
        if (myReview != null) {
          _hasMyReview = true;
          _myRating    = (myReview['rating'] as num?)?.toInt() ?? 5;
          _reviewCtrl.text = (myReview['review_text'] as String?) ?? '';
        }
        _reviewsLoaded  = true;
        _reviewsLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() { _reviewsLoading = false; _reviewsLoaded = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดรีวิวไม่สำเร็จ: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    final text = _reviewCtrl.text.trim();
    if (text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเขียนรีวิวอย่างน้อย 10 ตัวอักษร')),
      );
      return;
    }
    setState(() => _submittingReview = true);
    try {
      final msg = await ApiService.instance.submitReview(_courseId, _myRating, text);
      if (!mounted) return;
      setState(() { _hasMyReview = true; _reviewsLoaded = false; _submittingReview = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      _loadReviews();
    } catch (e) {
      if (mounted) setState(() => _submittingReview = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loadExercises() async {
    if (_exercisesLoaded || _courseId <= 0) return;
    try {
      final list = await ApiService.instance.getExamList(_courseId);
      if (!mounted) return;
      setState(() {
        _exercises = list;
        _exercisesLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _exercisesLoaded = true);
    }
  }

  void _initMedia() {
    if (_exVideos.isNotEmpty) {
      _loadExVideo(0);
    } else {
      _initMediaFromCourseData();
    }
  }

  void _initMediaFromCourseData() {
    final ytUrl = _youtubeUrl;
    if (ytUrl != null) {
      _mediaCtrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..loadRequest(Uri.parse(ytUrl));
      if (mounted) setState(() {});
    }
  }

  void _loadExVideo(int index) {
    if (index < 0 || index >= _exVideos.length) return;
    final v       = _exVideos[index];
    final url     = (v['course_video_url'] as String?) ?? '';
    final thumb   = (v['thumbnail_img']    as String?) ?? '';
    final poster  = thumb.isNotEmpty ? '$_thumbBase$thumb' : '';
    if (url.isEmpty) return;

    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(_videoHtml(url, poster));

    setState(() {
      _selectedEx = index;
      _mediaCtrl  = ctrl;
    });
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
  <video controls playsinline preload="metadata"${poster.isNotEmpty ? ' poster="$poster"' : ''}>
    <source src="$videoUrl" type="video/mp4">
  </video>
</body>
</html>
''';

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildMediaSection()),
          SliverToBoxAdapter(child: _buildCourseInfo()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBar(
              tabIndex: _tabIndex,
              onChanged: (i) {
                setState(() => _tabIndex = i);
                if (i == 2) _loadExercises();
              },
            ),
          ),
          SliverToBoxAdapter(child: _buildTabContent()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 30),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: Text(
        'รายละเอียดคอร์ส',
        style: GoogleFonts.notoSansThai(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      centerTitle: true,
    );
  }

  // ── Media Section ──────────────────────────────────────────────────────────

  Widget _buildMediaSection() {
    return Column(
      children: [
        _buildMainPlayer(),
        if (_exVideos.length > 1) _buildExVideoSelector(),
      ],
    );
  }

  Widget _buildMainPlayer() {
    final hasExVideo = _exVideos.isNotEmpty;
    final ctrl = _mediaCtrl;

    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── background ──
          if (ctrl != null)
            WebViewWidget(controller: ctrl)
          else if (_imageFile != null && _imageFile!.isNotEmpty)
            Image.network(
              '$_imgBase$_imageFile',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradientBg(),
            )
          else
            _gradientBg(),

          // ── scrim ──
          if (ctrl == null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

          // ── "ทดลองชมฟรี" badge ──
          if (hasExVideo)
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_filled, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'ทดลองชมฟรี',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── action buttons ──
          Positioned(
            top: 12, right: 12,
            child: Row(
              children: [
                _overlayBtn(Icons.bookmark_border_rounded),
                const SizedBox(width: 8),
                _overlayBtn(Icons.share_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // เมนูเลือก ex_video (กรณีมีหลาย clip)
  Widget _buildExVideoSelector() {
    return Container(
      height: 90,
      color: Colors.black,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _exVideos.length,
        itemBuilder: (_, i) {
          final v     = _exVideos[i];
          final thumb = (v['thumbnail_img'] as String?) ?? '';
          final name  = (v['course_video_name'] as String?) ?? 'คลิป ${i + 1}';
          final sel   = _selectedEx == i;
          return GestureDetector(
            onTap: () => _loadExVideo(i),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: sel ? const Color(0xFF2ECC71) : Colors.transparent,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumb.isNotEmpty
                      ? Image.network(
                          '$_thumbBase$thumb',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF333333)),
                        )
                      : Container(color: const Color(0xFF333333)),
                  Container(color: Colors.black.withOpacity(0.35)),
                  Center(
                    child: Icon(
                      sel ? Icons.pause_circle_filled : Icons.play_circle_outline,
                      color: sel ? const Color(0xFF2ECC71) : Colors.white,
                      size: 28,
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansThai(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _gradientBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B8A), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _overlayBtn(IconData icon) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: AppTheme.textDark),
    );
  }

  // ── Course Info ────────────────────────────────────────────────────────────

  Widget _buildCourseInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: GoogleFonts.notoSansThai(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: AppTheme.textDark, height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              if (_duration.isNotEmpty)
                _chip(Icons.access_time_rounded, _duration, AppTheme.primary),
              _chip(Icons.star_rounded, '5.0', const Color(0xFFFFB800)),
              if (_videos.isNotEmpty)
                _chip(Icons.play_lesson_outlined, '${_videos.length} บทเรียน', AppTheme.primary),
            ],
          ),
          if (_students > 0) ...[
            const SizedBox(height: 10),
            Text('$_students students',
                style: GoogleFonts.notoSansThai(fontSize: 13, color: AppTheme.textLight)),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.notoSansThai(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Tab Content ────────────────────────────────────────────────────────────

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 1:  return _buildLessonsContent();
      case 2:  return _buildQuizContent();
      default: return _buildOverviewContent();
    }
  }

  // ── Overview ───────────────────────────────────────────────────────────────

  Widget _buildOverviewContent() {
    return Column(
      children: [
        _buildDescSection(),
        _buildInstructorSection(),
        if (_videos.isNotEmpty) _buildLessonsPreview(),
      ],
    );
  }

  Widget _buildDescSection() {
    final text = _desc.isNotEmpty ? _desc : 'กำลังโหลด...';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Overview'),
          const SizedBox(height: 10),
          Text(
            text,
            maxLines: _showFullDesc ? null : 4,
            overflow: _showFullDesc ? null : TextOverflow.ellipsis,
            style: GoogleFonts.notoSansThai(
                fontSize: 13, color: AppTheme.textMedium, height: 1.7),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showFullDesc = !_showFullDesc),
            child: Text(
              _showFullDesc ? 'Show less' : 'Show more',
              style: GoogleFonts.notoSansThai(
                  fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('ผู้สอน'),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF28A874)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Text('ホ',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ครูพี่โฮม',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                    Text('No.1 ที่สื่อชั้นนำยอมรับ',
                        style: GoogleFonts.notoSansThai(fontSize: 12, color: AppTheme.textLight)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _stat('12K+', 'ผู้เรียน'),
                        const SizedBox(width: 16),
                        _stat('24', 'คอร์ส'),
                        const SizedBox(width: 16),
                        _stat('4.9★', 'คะแนน'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.notoSansThai(
                fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        Text(label,
            style: GoogleFonts.notoSansThai(fontSize: 10, color: AppTheme.textLight)),
      ],
    );
  }

  Widget _buildLessonsPreview() {
    final preview = _videos.take(3).toList();
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Lessons'),
          const SizedBox(height: 4),
          Text('${_videos.length} บทเรียน',
              style: GoogleFonts.notoSansThai(fontSize: 12, color: AppTheme.textLight)),
          const SizedBox(height: 12),
          ...preview.map((v) => _lessonRow(v)),
          GestureDetector(
            onTap: () => setState(() => _tabIndex = 1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Text(
                'ดูบทเรียนทั้งหมด ${_videos.length} บท →',
                style: GoogleFonts.notoSansThai(
                    fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lessons Tab ────────────────────────────────────────────────────────────

  Widget _buildLessonsContent() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Lessons'),
                const SizedBox(height: 4),
                Text('${_videos.length} บทเรียน',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 12, color: AppTheme.textLight)),
              ],
            ),
          ),
          if (_detailLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_videos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('ยังไม่มีบทเรียน',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 14, color: AppTheme.textLight)),
              ),
            )
          else
            ..._videos.asMap().entries.map((e) => _lessonRow(e.value, index: e.key)),
        ],
      ),
    );
  }

  Widget _lessonRow(Map<String, dynamic> v, {int? index}) {
    final name      = (v['course_video_name'] as String?) ?? 'บทเรียนที่ ${(index ?? 0) + 1}';
    final duration  = (v['time_video'] as String?) ?? '';
    final isFree    = (v['free_video'] as num?)?.toInt() == 1;
    final thumbFile = (v['thumbnail_img'] as String?) ?? '';
    final thumbUrl  = thumbFile.isNotEmpty ? '$_thumbBase$thumbFile' : '';

    const placeholderColors = [
      Color(0xFFFF6B8A), Color(0xFF5B8DEF), Color(0xFFFFB347),
      Color(0xFF7EC8E3), Color(0xFFD291BC), Color(0xFF87CEAB),
    ];
    final placeholderColor = placeholderColors[(index ?? 0) % placeholderColors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border.withOpacity(0.5)))),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80, height: 52,
              child: thumbUrl.isNotEmpty
                  ? Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: placeholderColor,
                        child: Center(
                          child: Text(
                            '${(index ?? 0) + 1}',
                            style: GoogleFonts.notoSansThai(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: placeholderColor,
                      child: Center(
                        child: Text(
                          '${(index ?? 0) + 1}',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                        height: 1.4)),
                if (duration.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(duration,
                      style: GoogleFonts.notoSansThai(
                          fontSize: 11, color: AppTheme.textLight)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isFree)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('ฟรี',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2ECC71))),
            )
          else
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                  color: AppTheme.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline,
                  color: AppTheme.textLight, size: 16),
            ),
        ],
      ),
    );
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  static const _avatarColors = [
    Color(0xFFFF8FAB), Color(0xFF6BCB77), Color(0xFFFFAA5A),
    Color(0xFF5B8DEF), Color(0xFFD291BC), Color(0xFF87CEAB),
  ];

  Widget _buildReviewsContent() {
    if (_reviewsLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRatingSummary(),
          if (_isLoggedIn) ...[
            const SizedBox(height: 16),
            _buildReviewForm(),
          ],
          const SizedBox(height: 16),
          if (_reviewList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('ยังไม่มีรีวิว เป็นคนแรกที่รีวิวคอร์สนี้!',
                    style: GoogleFonts.notoSansThai(fontSize: 14, color: AppTheme.textLight)),
              ),
            )
          else
            ..._reviewList.map((r) => _reviewCardFromData(r)),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    final avg   = _reviewsLoaded ? _avgRating : 0.0;
    final total = _reviewsLoaded ? _totalReviews : 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(avg.toStringAsFixed(1),
                  style: GoogleFonts.notoSansThai(
                      fontSize: 48, fontWeight: FontWeight.w900,
                      color: AppTheme.textDark, height: 1)),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 14, color: const Color(0xFFFFB800),
                )),
              ),
              const SizedBox(height: 4),
              Text('$total รีวิว',
                  style: GoogleFonts.notoSansThai(fontSize: 11, color: AppTheme.textLight)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = _ratingDist[star] ?? 0;
                final pct = total > 0 ? count / total : 0.0;
                return _ratingBar(star, pct, count);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(int star, double value, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star★',
              style: GoogleFonts.notoSansThai(fontSize: 11, color: AppTheme.textLight)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppTheme.border,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 24,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: GoogleFonts.notoSansThai(fontSize: 11, color: AppTheme.textLight)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_hasMyReview ? 'แก้ไขรีวิวของคุณ' : 'เขียนรีวิว',
              style: GoogleFonts.notoSansThai(
                  fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _myRating = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  i < _myRating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFB800), size: 34,
                ),
              ),
            )),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewCtrl,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'เขียนรีวิวของคุณ... (อย่างน้อย 10 ตัวอักษร)',
              hintStyle: GoogleFonts.notoSansThai(fontSize: 13, color: AppTheme.textLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: GoogleFonts.notoSansThai(fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submittingReview ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _submittingReview
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_hasMyReview ? 'แก้ไขรีวิว' : 'ส่งรีวิว',
                      style: GoogleFonts.notoSansThai(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCardFromData(Map<String, dynamic> r) {
    final name   = (r['name'] as String?) ?? 'ผู้ใช้';
    final rating = (r['rating'] as num?)?.toInt() ?? 5;
    final text   = (r['review_text'] as String?) ?? '';
    final uid    = (r['user_id'] as num?)?.toInt() ?? 0;
    final color  = _avatarColors[name.hashCode.abs() % _avatarColors.length];
    final isMe   = uid == _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isMe ? Border.all(color: AppTheme.primary.withOpacity(0.4)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(name.isNotEmpty ? name.substring(0, 1) : '?',
                  style: GoogleFonts.notoSansThai(
                      fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: GoogleFonts.notoSansThai(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('คุณ',
                            style: GoogleFonts.notoSansThai(
                                fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(children: List.generate(rating,
                    (_) => const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB800)))),
                const SizedBox(height: 6),
                Text(text,
                    style: GoogleFonts.notoSansThai(
                        fontSize: 13, color: AppTheme.textMedium, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quiz Tab ───────────────────────────────────────────────────────────────

  Widget _buildQuizContent() {
    if (!_exercisesLoaded) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF32D191), Color(0xFF0A8C80)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('แบบฝึกหัดทั้งหมด',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 15, color: Colors.white, fontWeight: FontWeight.w800)),
                      Text('${_exercises.length} ชุด · ทำได้ไม่จำกัดครั้ง',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_exercises.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('ยังไม่มีแบบฝึกหัดสำหรับคอร์สนี้',
                    style: GoogleFonts.notoSansThai(
                        fontSize: 14, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
              ),
            )
          else
            ..._exercises.map((ex) => _exerciseCard(ex as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _exerciseCard(Map<String, dynamic> ex) {
    final id    = (ex['id'] as num).toInt();
    final title = ex['title'] as String? ?? 'แบบฝึกหัด';
    final qCount  = (ex['question_count'] as num?)?.toInt() ?? 0;
    final passScore = (ex['pass_score'] as num?)?.toDouble() ?? 70.0;
    final timeLimit = (ex['time_limit'] as num?)?.toInt();

    return GestureDetector(
      onTap: () => context.push('/exam-v2', extra: {
        'exerciseId':    id,
        'exerciseTitle': title,
        'saveAttempt':   false,
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                  color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.assignment_rounded, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.notoSansThai(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.help_outline_rounded, size: 13, color: AppTheme.textLight),
                      const SizedBox(width: 3),
                      Text('$qCount ข้อ',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('ผ่าน $passScore%',
                            style: GoogleFonts.notoSansThai(
                                fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                      ),
                      if (timeLimit != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.timer_outlined, size: 13, color: AppTheme.textLight),
                        const SizedBox(width: 2),
                        Text('$timeLimit น.',
                            style: GoogleFonts.notoSansThai(
                                fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.play_arrow_rounded, color: AppTheme.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBarContent(BuildContext context) {
    // ยังไม่ซื้อ: ราคา + ปุ่มจอง
    if (!_isOwned) {
      return Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _price > 0 ? '฿${_fmtPrice(_price)}' : 'ราคา',
                style: GoogleFonts.notoSansThai(
                    fontSize: 22, fontWeight: FontWeight.w900,
                    color: AppTheme.textDark, height: 1.1),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.push('/payment', extra: {
                'title': _title,
                'price': _price,
                'id': _courseId,
                'type': 'course',
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('จองคอร์สเรียน',
                  style: GoogleFonts.notoSansThai(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      );
    }

    // ซื้อแล้ว + หมดอายุ: ปุ่มติดต่อเจ้าหน้าที่ (กดได้ แสดง dialog)
    if (_isExpired) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('ติดต่อเจ้าหน้าที่',
                      style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w800)),
                  content: Text('คอร์สนี้หมดอายุแล้ว\nกรุณาติดต่อเจ้าหน้าที่เพื่อต่ออายุ',
                      style: GoogleFonts.notoSansThai()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('ปิด', style: GoogleFonts.notoSansThai()),
                    ),
                  ],
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('ติดต่อเจ้าหน้าที่',
                  style: GoogleFonts.notoSansThai(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
          if (_endDayFormatted.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('หมดอายุ $_endDayFormatted',
                style: GoogleFonts.notoSansThai(fontSize: 11, color: Colors.red.shade400)),
          ],
        ],
      );
    }

    // ซื้อแล้ว + ยังไม่หมดอายุ: 2 ปุ่ม
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _detailLoading
                    ? null
                    : () => context.push('/video', extra: {
                          'courseId': _courseId,
                          'title': _title,
                          'endDay': _endDay,
                        }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('เข้าเรียน',
                    style: GoogleFonts.notoSansThai(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('ติดต่อสอบถาม',
                      style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w800)),
                  content: Text('หากมีข้อสงสัยเกี่ยวกับคอร์สนี้\nกรุณาติดต่อเจ้าหน้าที่',
                      style: GoogleFonts.notoSansThai()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('ปิด', style: GoogleFonts.notoSansThai()),
                    ),
                  ],
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('ติดต่อ',
                  style: GoogleFonts.notoSansThai(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        if (_endDayFormatted.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('หมดอายุ $_endDayFormatted',
              style: GoogleFonts.notoSansThai(fontSize: 11, color: AppTheme.textLight)),
        ],
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4))],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      child: _buildBottomBarContent(context),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmtPrice(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
          decoration: BoxDecoration(
              color: AppTheme.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.notoSansThai(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
      ],
    );
  }
}

// ── Sticky Tab Bar ────────────────────────────────────────────────────────────

class _StickyTabBar extends SliverPersistentHeaderDelegate {
  final int tabIndex;
  final ValueChanged<int> onChanged;

  const _StickyTabBar({required this.tabIndex, required this.onChanged});

  static const _tabs = ['Overview', 'Lessons', 'แบบฝึกหัด'];

  @override double get minExtent => 48;
  @override double get maxExtent => 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
        boxShadow: overlapsContent
            ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3))]
            : [],
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppTheme.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[i],
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? AppTheme.primary : AppTheme.textLight,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBar old) => old.tabIndex != tabIndex;
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _Review {
  final String name, text;
  final int rating;
  final Color avatarColor;
  const _Review(this.name, this.rating, this.text, this.avatarColor);
}

class _QuizSet {
  final String title;
  final int questionCount;
  final String difficulty;
  final Color diffColor;
  const _QuizSet(this.title, this.questionCount, this.difficulty, this.diffColor);
}
