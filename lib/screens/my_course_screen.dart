import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class MyCourseScreen extends StatefulWidget {
  const MyCourseScreen({super.key});

  @override
  State<MyCourseScreen> createState() => MyCourseScreenState();
}

class MyCourseScreenState extends State<MyCourseScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideIn;

  List<_OwnedCourse> _courses = [];
  List<_PendingOrder> _pendingOrders = [];
  bool _loading = true;
  int _userPoint = 0;

  static const _gradients = [
    [Color(0xFFFF7B8A), Color(0xFFE8273D)],
    [Color(0xFF34D399), Color(0xFF047857)],
    [Color(0xFF60A5FA), Color(0xFF2563EB)],
    [Color(0xFFFBBF24), Color(0xFFD97706)],
    [Color(0xFFA78BFA), Color(0xFF6D28D9)],
  ];
  static const _icons = [
    Icons.track_changes_rounded, Icons.menu_book_rounded,
    Icons.translate_rounded, Icons.bolt_rounded, Icons.star_rounded,
  ];
  static const _pendingGradients = [
    [Color(0xFF7C3AED), Color(0xFF4C1D95)],
    [Color(0xFFFF7B8A), Color(0xFFE8273D)],
    [Color(0xFF34D399), Color(0xFF047857)],
    [Color(0xFF60A5FA), Color(0xFF2563EB)],
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final rawCourses = await ApiService.instance.getMyCourses();
      List<dynamic> rawPending = [];
      try {
        rawPending = await ApiService.instance.getPendingOrders();
      } catch (e) {
        print('>>> getPendingOrders error: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      int userPoint = 0;
      try { userPoint = await ApiService.instance.getPoint(); } catch (_) {}

      List<_OwnedCourse> courses = [];
      List<_PendingOrder> pending = [];

      try {
        courses = List.generate(rawCourses.length, (i) {
          final c = rawCourses[i] as Map<String, dynamic>;
          final total = (c['videocount'] as num?)?.toInt() ?? 0;
          final cid = (c['course_id'] ?? c['id'] ?? c['c_id']);
          final courseId = (cid as num?)?.toInt() ?? 0;
          final done = prefs.getStringList('cdone_$courseId')?.length ?? 0;
          return _OwnedCourse(
            courseId: courseId,
            title: (c['title_course'] as String?) ?? 'คอร์ส',
            teacher: 'ครูพี่โฮม',
            progress: total > 0 ? done / total : 0.0,
            expiresAt: (c['end_day'] as String?) ?? '',
            daysLeft: _daysLeft(c['end_day'] as String?),
            lessonsDone: done,
            lessonsTotal: total,
            gradient: _gradients[i % _gradients.length],
            icon: _icons[i % _icons.length],
            imageFile: c['image_course'] as String?,
          );
        });
        // dedup by courseId — keep last occurrence (latest order)
        final seen = <int>{};
        courses = courses.reversed
            .where((c) => seen.add(c.courseId))
            .toList()
            .reversed
            .toList();
      } catch (e) {
        print('>>> _courses generate error: $e');
      }

      try {
        pending = List.generate(rawPending.length, (i) {
          final o = rawPending[i] as Map<String, dynamic>;
          final statusInt = (o['order_status'] as num?)?.toInt() ?? 1;
          final rawCode = (o['code_order'] ?? o['order_code'])?.toString() ?? '${o['order_id']}';
          final isPackage = o['type'] == 'package';
          final coursesList = (o['courses'] as List?)?.map((e) => e.toString()).toList();
          return _PendingOrder(
            orderNumber: rawCode,
            title: (o['title'] as String?) ?? 'รายการสั่งซื้อ',
            price: int.tryParse('${o['amount'] ?? 0}') ?? 0,
            bankName: 'ธนาคาร',
            submittedAt: _formatDate(o['order_date'] as String?),
            status: statusInt >= 2 ? _OrderStatus.confirmed : _OrderStatus.reviewing,
            gradient: isPackage ? _pendingGradients[0] : _pendingGradients[i % _pendingGradients.length],
            icon: isPackage ? Icons.card_giftcard_rounded : Icons.workspace_premium_rounded,
            packageName: o['package_name'] as String?,
            courses: coursesList,
          );
        });
      } catch (e) {
        print('>>> _pendingOrders generate error: $e');
      }

      print('>>> setState courses=${courses.length} pending=${pending.length}');
      setState(() {
        _userPoint = userPoint;
        _courses = courses;
        _pendingOrders = pending;
        _loading = false;
      });
      print('>>> after setState _loading=$_loading _courses=${_courses.length}');
    } catch (e) {
      print('>>> _loadData error: $e');
      setState(() => _loading = false);
    }
  }

  void reload() => _loadData();

  static int _daysLeft(String? endDay) {
    if (endDay == null || endDay.isEmpty) return 999;
    try {
      final end = DateTime.parse(endDay);
      final expDate = DateTime(end.year, end.month, end.day);
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      return expDate.difference(todayDate).inDays;
    } catch (_) {
      return 999;
    }
  }

  static String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year + 543}';
    } catch (_) {
      return raw;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _switchTab(int i) {
    if (_tab == i) return;
    setState(() => _tab = i);
    _slideController
      ..reset()
      ..forward();
  }

  void _onEnterCourse(BuildContext context, _OwnedCourse course) {
    if (course.daysLeft < 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(
            'คอร์สนี้หมดอายุแล้ว',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansThai(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: AppTheme.textDark),
          ),
          content: Text(
            'กรุณาติดต่อเจ้าหน้าที่ LINE : @ZA-SHI',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansThai(
                fontSize: 14, color: AppTheme.textMedium),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.notoSansThai(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary),
              ),
            ),
          ],
        ),
      );
      return;
    }
    context.push('/video', extra: {
      'courseId': course.courseId,
      'title':    course.title,
      'endDay':   course.expiresAt,
    });
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SlideTransition(
                    position: _slideIn,
                    child: FadeTransition(
                      opacity: _slideController,
                      child: _tab == 0 ? _buildActiveTab() : _buildPendingTab(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pendingCount = _pendingOrders
        .where((o) => o.status != _OrderStatus.confirmed)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Courses',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  _tab == 0
                      ? 'คอร์สทั้งหมดที่ซื้อแล้ว พร้อมวันหมดอายุ'
                      : 'ติดตามสถานะการชำระเงินของคุณ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: AppTheme.primary),
              ),
              if (pendingCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8273D),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$pendingCount',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final pendingCount = _pendingOrders
        .where((o) => o.status != _OrderStatus.confirmed)
        .length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tabItem(0, Icons.play_circle_rounded, 'กำลังเรียน', null),
          _tabItem(1, Icons.pending_actions_rounded, 'รอยืนยัน',
              pendingCount > 0 ? pendingCount : null),
        ],
      ),
    );
  }

  Widget _tabItem(int index, IconData icon, String label, int? badge) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppTheme.primary : AppTheme.textLight,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppTheme.primary : AppTheme.textLight,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary
                        : const Color(0xFFE8273D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$badge',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab 0: กำลังเรียน ──────────────────────────────────────────────────────

  Widget _buildActiveTab() {
    if (_courses.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                        color: AppTheme.primaryLight, shape: BoxShape.circle),
                    child: const Icon(Icons.school_rounded, color: AppTheme.primary, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text('ยังไม่มีคอร์สที่ซื้อ',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  Text('เลือกซื้อคอร์สและเริ่มเรียนได้เลย!',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 13, color: AppTheme.textLight, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSummary()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: EdgeInsets.only(bottom: i == _courses.length - 1 ? 0 : 14),
                  child: _courseCard(_courses[i], context),
                ),
                childCount: _courses.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryItem('${_courses.length}', 'คอร์สที่มี'),
          _divider(),
          _summaryItem('${_courses.fold(0, (s, c) => s + c.lessonsTotal)}', 'บทเรียนทั้งหมด'),
          _divider(),
          _summaryItem('$_userPoint', 'Point'),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.notoSansThai(
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              color: Colors.white.withOpacity(0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: Colors.white.withOpacity(0.22),
      );

  Widget _courseCard(_OwnedCourse course, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/course', extra: {
        'course_id': course.courseId,
        'title_course': course.title,
        'image_course': course.imageFile,
        'end_day': course.expiresAt,
      }),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 132,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // รูปคอร์ส — fallback เป็น gradient ถ้าไม่มีรูป
                  if (course.imageFile != null && course.imageFile!.isNotEmpty)
                    Image.network(
                      '${AppConfig.uploadsBase}${course.imageFile}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: course.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: course.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  // overlay มืดเพื่อให้อ่านข้อความได้
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black54],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${course.lessonsDone}/${course.lessonsTotal} lessons',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 15,
                        height: 1.3,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          course.teacher,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            color: AppTheme.textMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'หมดอายุ ${course.expiresAt}',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 11,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 8,
                      backgroundColor: AppTheme.border.withOpacity(0.65),
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Text(
                        '${(course.progress * 100).round()}% สำเร็จ',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${course.lessonsDone}/${course.lessonsTotal} บทเรียน',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _onEnterCourse(context, course),
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text(
                            'เข้าเรียน',
                            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showFilesSheet(context, course),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        icon: const Icon(Icons.folder_open_rounded,
                            size: 18, color: AppTheme.primary),
                        label: Text(
                          'ไฟล์',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _onExam(context, course),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF32D191),
                        side: const BorderSide(color: Color(0xFF32D191)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                      label: Text(
                        'แบบทดสอบ',
                        style: GoogleFonts.notoSansThai(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onExam(BuildContext context, _OwnedCourse course) {
    context.push('/exam-v2-list', extra: {
      'courseId':    course.courseId,
      'courseTitle': course.title,
    });
  }

  void _showFilesSheet(BuildContext context, _OwnedCourse course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilesSheet(
        courseId: course.courseId,
        courseTitle: course.title,
      ),
    );
  }

  // ─── Tab 1: รอยืนยัน ────────────────────────────────────────────────────────

  Widget _buildPendingTab() {
    if (_pendingOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: 400, child: _buildEmptyPending()),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildPendingBanner(),
          const SizedBox(height: 16),
          ..._pendingOrders.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _pendingOrderCard(o),
              )),
        ],
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECB3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_rounded,
                color: Color(0xFFE65100), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ทีมงานจะตรวจสอบสลิปและยืนยันการชำระภายใน 1-3 ชม. ในวันทำการ',
              style: GoogleFonts.notoSansThai(
                fontSize: 12,
                color: const Color(0xFF5D4037),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingOrderCard(_PendingOrder order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Thumbnail header
          Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: order.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 16,
                  top: 12,
                  child: Icon(order.icon,
                      size: 58, color: Colors.white.withOpacity(0.18)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          _statusPill(order.status),
                          const Spacer(),
                          Text(
                            '#${order.orderNumber.length > 6 ? order.orderNumber.substring(order.orderNumber.length - 6) : order.orderNumber}',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Info row
                Row(
                  children: [
                    _infoChip(
                      Icons.payments_rounded,
                      '฿${order.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _infoChip(
                        Icons.account_balance_rounded,
                        order.bankName.replaceFirst('ธนาคาร', ''),
                        const Color(0xFF5C6BC0)),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 13, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Text(
                          order.submittedAt,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 12,
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (order.courses != null && order.courses!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.library_books_rounded, size: 13, color: Color(0xFF6D28D9)),
                            const SizedBox(width: 5),
                            Text(
                              'คอร์สในแพ็กเกจ (${order.courses!.length} คอร์ส)',
                              style: GoogleFonts.notoSansThai(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6D28D9)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...order.courses!.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 5, color: Color(0xFF6D28D9)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(c, style: GoogleFonts.notoSansThai(fontSize: 12, color: const Color(0xFF4C1D95)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Timeline
                _buildTimeline(order.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(_OrderStatus status) {
    final info = _statusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: info.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            info.label,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.notoSansThai(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(_OrderStatus currentStatus) {
    final steps = [
      _TimelineStep(
        icon: Icons.upload_file_rounded,
        label: 'ส่งสลิปแล้ว',
        done: true,
        active: false,
      ),
      _TimelineStep(
        icon: Icons.manage_search_rounded,
        label: 'กำลังตรวจสอบ',
        done: currentStatus.index >= _OrderStatus.confirmed.index,
        active: currentStatus == _OrderStatus.reviewing,
      ),
      _TimelineStep(
        icon: Icons.verified_rounded,
        label: 'ยืนยันแล้ว',
        done: currentStatus == _OrderStatus.confirmed,
        active: false,
      ),
      _TimelineStep(
        icon: Icons.play_circle_rounded,
        label: 'เรียนได้เลย!',
        done: currentStatus == _OrderStatus.confirmed,
        active: false,
      ),
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // connector line
          final leftDone = steps[i ~/ 2].done;
          return Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: leftDone
                      ? [AppTheme.primary, AppTheme.primary.withOpacity(0.3)]
                      : [AppTheme.border, AppTheme.border],
                ),
              ),
            ),
          );
        }
        final step = steps[i ~/ 2];
        return _timelineNode(step);
      }),
    );
  }

  Widget _timelineNode(_TimelineStep step) {
    Color bg;
    Color iconColor;
    if (step.done) {
      bg = AppTheme.primary;
      iconColor = Colors.white;
    } else if (step.active) {
      bg = const Color(0xFFFF9800);
      iconColor = Colors.white;
    } else {
      bg = AppTheme.border.withOpacity(0.5);
      iconColor = AppTheme.textLight;
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: step.active
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: step.active
              ? Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                )
              : Icon(step.icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 60,
          child: Text(
            step.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansThai(
              fontSize: 10,
              color: step.done
                  ? AppTheme.primary
                  : step.active
                      ? const Color(0xFFE65100)
                      : AppTheme.textLight,
              fontWeight: step.done || step.active
                  ? FontWeight.w700
                  : FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPending() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppTheme.primary, size: 48),
          ),
          const SizedBox(height: 16),
          Text('ไม่มีรายการรอยืนยัน',
              style: GoogleFonts.notoSansThai(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 6),
          Text('การชำระเงินทั้งหมดได้รับการยืนยันแล้ว',
              style: GoogleFonts.notoSansThai(
                  fontSize: 13, color: AppTheme.textLight,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  _StatusInfo _statusInfo(_OrderStatus status) {
    switch (status) {
      case _OrderStatus.reviewing:
        return _StatusInfo('กำลังตรวจสอบ', const Color(0xFFFF9800));
      case _OrderStatus.confirmed:
        return _StatusInfo('ยืนยันแล้ว', AppTheme.primary);
    }
  }
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _OwnedCourse {
  final int courseId;
  final String title;
  final String teacher;
  final double progress;
  final String expiresAt;
  final int daysLeft;
  final int lessonsDone;
  final int lessonsTotal;
  final List<Color> gradient;
  final IconData icon;
  final String? imageFile;

  const _OwnedCourse({
    required this.courseId,
    required this.title,
    required this.teacher,
    required this.progress,
    required this.expiresAt,
    required this.daysLeft,
    required this.lessonsDone,
    required this.lessonsTotal,
    required this.gradient,
    required this.icon,
    this.imageFile,
  });
}

enum _OrderStatus { reviewing, confirmed }

class _PendingOrder {
  final String orderNumber;
  final String title;
  final int price;
  final String bankName;
  final String submittedAt;
  final _OrderStatus status;
  final List<Color> gradient;
  final IconData icon;
  final String? packageName;
  final List<String>? courses;

  const _PendingOrder({
    required this.orderNumber,
    required this.title,
    required this.price,
    required this.bankName,
    required this.submittedAt,
    required this.status,
    required this.gradient,
    required this.icon,
    this.packageName,
    this.courses,
  });
}

class _TimelineStep {
  final IconData icon;
  final String label;
  final bool done;
  final bool active;
  const _TimelineStep(
      {required this.icon,
      required this.label,
      required this.done,
      required this.active});
}

class _StatusInfo {
  final String label;
  final Color dotColor;
  const _StatusInfo(this.label, this.dotColor);
}

// ─── Files Bottom Sheet ───────────────────────────────────────────────────────

class _FilesSheet extends StatefulWidget {
  final int courseId;
  final String courseTitle;
  const _FilesSheet({required this.courseId, required this.courseTitle});

  @override
  State<_FilesSheet> createState() => _FilesSheetState();
}

class _FilesSheetState extends State<_FilesSheet> {
  List<Map<String, dynamic>> _files = [];
  bool _loading = true;
  final Map<int, double> _progress = {};
  final Map<int, String> _localPath = {};
  final Map<int, bool> _downloading = {};

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<Directory> _getSaveDir() async {
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final folder = Directory('${ext.path}/LearnSbuy');
        if (!folder.existsSync()) folder.createSync(recursive: true);
        return folder;
      }
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }

  Future<void> _loadFiles() async {
    try {
      final data = await ApiService.instance.getFileApp(widget.courseId);
      print('>>> getFileApp courseId=${widget.courseId} keys=${data.keys} fileCount=${(data['file'] as List?)?.length}');
      final files = (data['file'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final dir = await _getSaveDir();
      final localPaths = <int, String>{};
      for (int i = 0; i < files.length; i++) {
        final fn = files[i]['file_of_course'] as String? ?? '';
        if (fn.isEmpty) continue;
        final path = '${dir.path}/$fn';
        if (File(path).existsSync()) localPaths[i] = path;
      }
      if (mounted) {
        setState(() {
          _files = files;
          _localPath.addAll(localPaths);
          _loading = false;
        });
      }
    } catch (e) {
      print('>>> _loadFiles error courseId=${widget.courseId}: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download(int index) async {
    final file = _files[index];
    final fileName = file['file_of_course'] as String? ?? '';
    if (fileName.isEmpty) return;
    final url = '${AppConfig.fileCoursesBase}$fileName';

    setState(() {
      _downloading[index] = true;
      _progress[index] = 0;
    });

    try {
      final dir = await _getSaveDir();
      final savePath = '${dir.path}/$fileName';

      await Dio().download(
        url,
        savePath,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress[index] = received / total);
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _downloading[index] = false;
        _localPath[index] = savePath;
      });

      // auto-open after download
      final result = await OpenFile.open(savePath);
      if (mounted && result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกแล้วที่: $savePath',
                style: GoogleFonts.notoSansThai(fontSize: 12)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading[index] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('ดาวน์โหลดล้มเหลว: $e',
              style: GoogleFonts.notoSansThai(fontSize: 12, color: Colors.white)),
        ),
      );
    }
  }

  Future<void> _open(int index) async {
    final path = _localPath[index];
    if (path == null) return;
    final result = await OpenFile.open(path);
    if (mounted && result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่พบแอปสำหรับเปิดไฟล์ PDF',
              style: GoogleFonts.notoSansThai(fontSize: 13)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_rounded,
                      color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ไฟล์ประกอบการเรียน',
                          style: GoogleFonts.notoSansThai(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark)),
                      Text(widget.courseTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansThai(
                              fontSize: 12,
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (_files.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.inbox_rounded,
                      size: 40, color: AppTheme.textLight),
                  const SizedBox(height: 8),
                  Text('ไม่มีไฟล์ประกอบการเรียน',
                      style: GoogleFonts.notoSansThai(
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _files.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (_, i) => _fileRow(i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fileRow(int i) {
    final name = _files[i]['file_of_name'] as String? ??
        (_files[i]['file_of_course'] as String? ?? 'ไฟล์ ${i + 1}');
    final isDownloading = _downloading[i] == true;
    final isDownloaded = _localPath.containsKey(i);
    final prog = _progress[i] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded,
                color: Color(0xFFE65100), size: 22),
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
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                if (isDownloading) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: prog,
                    backgroundColor: AppTheme.border,
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.primary),
                    minHeight: 3,
                  ),
                  const SizedBox(height: 2),
                  Text('${(prog * 100).round()}%',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 10, color: AppTheme.textLight)),
                ] else if (isDownloaded) ...[
                  const SizedBox(height: 3),
                  Text('ดาวน์โหลดแล้ว',
                      style: GoogleFonts.notoSansThai(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _actionButton(i, isDownloading, isDownloaded),
        ],
      ),
    );
  }

  Widget _actionButton(int i, bool isDownloading, bool isDownloaded) {
    if (isDownloading) {
      return const SizedBox(
        width: 22, height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (isDownloaded) {
      return ElevatedButton.icon(
        onPressed: () => _open(i),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: const Icon(Icons.open_in_new_rounded, size: 14),
        label: Text('เปิด',
            style: GoogleFonts.notoSansThai(
                fontSize: 12, fontWeight: FontWeight.w700)),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => _download(i),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.primary),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      icon: const Icon(Icons.download_rounded,
          size: 14, color: AppTheme.primary),
      label: Text('โหลด',
          style: GoogleFonts.notoSansThai(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary)),
    );
  }
}
