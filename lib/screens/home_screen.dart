import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_theme.dart';
import '../widgets/course_card.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../config/app_config.dart';
import 'chat_screen.dart';
import 'teacher_inbox_screen.dart';
import 'help_screen.dart';
import 'my_course_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _myCourseKey = GlobalKey<MyCourseScreenState>();
  final _bannerController = PageController();
  Timer? _bannerTimer;

  // User info
  String  _userName    = '';
  String  _userInitial = 'K';
  int     _userId      = 0;
  String? _avatarUrl;

  static const _avatarBase = 'https://learnsbuy.com/assets/images/avatar/';

  // Data
  bool _isLoading = true;
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _courseList  = [];
  List<Map<String, dynamic>> _packageList = [];
  List<Map<String, dynamic>> _slideList   = [];
  int _selectedDeptId = 0;

  static const _courseColors = <List<Color>>[
    [Color(0xFFFF6B8A), Color(0xFFFF4757)],
    [Color(0xFF9B59B6), Color(0xFF6C3483)],
    [Color(0xFF32D191), Color(0xFF28A874)],
    [Color(0xFFFF9F43), Color(0xFFEE5A24)],
    [Color(0xFF3498DB), Color(0xFF1A73C7)],
    [Color(0xFF2ECC71), Color(0xFF1A9B5F)],
    [Color(0xFFE74C3C), Color(0xFFC0392B)],
    [Color(0xFF2C3E7A), Color(0xFF1A2460)],
  ];

  static const _pkgGradients = <List<Color>>[
    [Color(0xFF2C3E7A), Color(0xFF1A2460)],
    [Color(0xFF0F3460), Color(0xFF533483)],
    [Color(0xFF1A1A2E), Color(0xFF16213E)],
    [Color(0xFF6A0572), Color(0xFF9B59B6)],
    [Color(0xFF1B4332), Color(0xFF2D6A4F)],
    [Color(0xFFCC0000), Color(0xFFFF4444)],
    [Color(0xFF32D191), Color(0xFF28A874)],
    [Color(0xFFE67E22), Color(0xFFD35400)],
  ];

  static const _pkgIcons = <IconData>[
    Icons.school,
    Icons.translate,
    Icons.live_tv,
    Icons.emoji_events,
    Icons.speed,
    Icons.menu_book,
    Icons.bolt,
    Icons.card_giftcard,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startBannerTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NotificationService.instance.init(context);
    });
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_bannerController.hasClients || _slideList.isEmpty) return;
      final next = (_bannerController.page?.round() ?? 0) + 1;
      _bannerController.animateToPage(
        next % _slideList.length,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // โหลด public data และ user data แยกกัน เพื่อกัน auth error ไม่ให้กระทบหน้า
    await Future.wait([
      _loadPublicData(),
      _loadUserName(),
    ]);
  }

  Future<void> _loadPublicData() async {
    try {
      final results = await Future.wait<dynamic>([
        ApiService.instance.getDepartments(),
        ApiService.instance.getCourses(),
        ApiService.instance.getPackages(),
        ApiService.instance.getSlideShows(),
      ]);
      if (!mounted) return;
      setState(() {
        _departments = _asMaps(results[0] as List);
        _courseList  = _asMaps(results[1] as List);
        _packageList = _asMaps(results[2] as List);
        _slideList   = _asMaps(results[3] as List);
        _isLoading   = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserName() async {
    String name = '';
    int uid = 0;
    try {
      // ลอง API ก่อน (fresh data)
      final data = await ApiService.instance.getMe();
      name = (data['name'] as String?) ?? '';
      uid  = (data['id']   as num?)?.toInt() ?? 0;
    } catch (_) {
      // fallback ใช้ cache จาก SharedPreferences
      try {
        final user = await AuthService.instance.getUser();
        name = (user?['name'] as String?) ?? '';
        uid  = (user?['id']   as num?)?.toInt() ?? 0;
      } catch (_) {}
    }
    if (mounted) setState(() => _userId = uid);
    if (uid > 0) NotificationService.instance.saveToken(uid);
    if (mounted && name.isNotEmpty) {
      setState(() => _userInitial = name[0].toUpperCase());
    }
    try {
      final user = await AuthService.instance.getUser();
      final f = user?['avatar'] as String?;
      if (mounted && f != null && f.isNotEmpty) {
        setState(() {
          _userName   = name;
          _avatarUrl  = '$_avatarBase$f';
        });
        return;
      }
    } catch (_) {}
    if (mounted && name.isNotEmpty) setState(() => _userName = name);
  }

  void _openChat() {
    final screen = _userId == AppConfig.teacherId
        ? const TeacherInboxScreen()
        : const ChatScreen();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _selectDept(int deptId) async {
    setState(() => _selectedDeptId = deptId);
    try {
      final courses = await ApiService.instance.getCourses(departmentId: deptId);
      if (mounted) setState(() => _courseList = _asMaps(courses));
    } catch (_) {}
  }

  List<Map<String, dynamic>> _asMaps(List raw) =>
      raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  static const _imgBase = 'https://learnsbuy.com/assets/uploads/';

  List<CourseModel> get _courseModels {
    return _courseList.asMap().entries.map((entry) {
      final i   = entry.key;
      final j   = entry.value;
      final c   = _courseColors[i % _courseColors.length];
      final dept = (j['name_department'] as String?) ?? '';
      final img  = j['image_course'] as String?;
      return CourseModel(
        flashLabel: dept.isNotEmpty ? dept : 'คอร์ส',
        courseName: (j['title_course'] as String?) ?? '-',
        rating: 4.9,
        students: (j['student_count'] as num?)?.toInt() ?? 0,
        price: (j['price_course'] as num?)?.toInt() ?? 0,
        bgStart: c[0],
        bgEnd: c[1],
        icon: Icons.local_florist,
        tags: dept.isNotEmpty ? [dept] : [],
        imageUrl: (img != null && img.isNotEmpty) ? '$_imgBase$img' : null,
      );
    }).toList();
  }

  List<_PackageInfo> get _packageInfoList {
    final sorted = [..._packageList]..sort(
        (a, b) => ((a['id'] as num?)?.toInt() ?? 0)
            .compareTo((b['id'] as num?)?.toInt() ?? 0),
      );
    return sorted.asMap().entries.map((entry) {
      final i    = entry.key;
      final p    = entry.value;
      final sale     = (p['c_pack_price']   as num?)?.toInt() ?? 0;   // ราคาที่ลดแล้ว
      final original = (p['c_pack_price_2'] as num?)?.toInt() ?? sale; // ราคาเดิม
      final grad     = _pkgGradients[i % _pkgGradients.length];
      final img      = p['c_pack_image'] as String?;
      return _PackageInfo(
        badge: 'แพ็กเกจ',
        title: (p['c_pack_name'] as String?) ?? '-',
        originalPrice: original,
        salePrice: sale,
        gradient: grad,
        icon: _pkgIcons[i % _pkgIcons.length],
        id: (p['id'] as num?)?.toInt() ?? 0,
        imageUrl: (img != null && img.isNotEmpty) ? '$_imgBase$img' : null,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(),
          MyCourseScreen(key: _myCourseKey),
          const HelpScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomePage() {
    final courses = _courseModels;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildBanner()),
          if (_packageList.isNotEmpty)
            SliverToBoxAdapter(child: _buildPackages()),
          SliverToBoxAdapter(child: _buildCategorySection()),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (courses.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'ไม่พบคอร์สเรียน',
                    style: GoogleFonts.notoSansThai(fontSize: 15, color: AppTheme.textLight),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => i < courses.length
                      ? CourseCard(
                          course: courses[i],
                          onTap: () => context.push('/course', extra: _courseList[i]),
                        )
                      : null,
                  childCount: courses.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isTablet ? 0.85 : 0.88,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/logo/logo.png',
                height: 52,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Material(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _openChat,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.textMedium,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _slideImgBase = 'https://learnsbuy.com/assets/image/slide/';

  Widget _buildBanner() {
    final slides = _slideList;
    if (slides.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 2.2,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: slides.length,
              itemBuilder: (_, i) => _buildSlideCard(slides[i]),
            ),
          ),
          const SizedBox(height: 10),
          SmoothPageIndicator(
            controller: _bannerController,
            count: slides.length,
            effect: ExpandingDotsEffect(
              activeDotColor: AppTheme.primary,
              dotColor: AppTheme.border,
              dotHeight: 6,
              dotWidth: 6,
              expansionFactor: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideCard(Map<String, dynamic> slide) {
    final imgFile = (slide['image_slide'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade300,
      ),
      clipBehavior: Clip.antiAlias,
      child: imgFile.isNotEmpty
          ? Image.network(
              '$_slideImgBase$imgFile',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2C3E7A)),
            )
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2C3E7A), Color(0xFF1A2460)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
    );
  }

  Widget _buildPackages() {
    final packs = _packageInfoList;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'แพ็กเกจสุดคุ้ม',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/packages'),
                  child: Text(
                    'ทั้งหมด ›',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 185,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: packs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _buildPackageCard(packs[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(_PackageInfo p) {
    final isFree      = p.salePrice == 0;
    final hasDiscount = p.originalPrice != null && p.originalPrice! > p.salePrice;

    return GestureDetector(
      onTap: () => context.push('/package', extra: p.id),
      child: Container(
        width: 172,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 95,
              child: Stack(
                children: [
                  if (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        p.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _pkgGradientBg(p),
                      ),
                    )
                  else
                    _pkgGradientBg(p),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.priceRed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.badge,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (isFree)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ฟรี',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isFree) ...[
                      Text(
                        'เรียนฟรี ไม่มีค่าใช้จ่าย',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '฿${_fmt(p.salePrice)}',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 4),
                            Text(
                              '฿${_fmt(p.originalPrice!)}',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 10,
                                color: AppTheme.textLight,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pkgGradientBg(_PackageInfo p) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: p.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(p.icon, size: 52, color: Colors.white.withOpacity(0.25)),
      ),
    );
  }

  String _fmt(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'คอร์สเรียนทั้งหมด',
            style: GoogleFonts.notoSansThai(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _categoryChip(0, 'ทั้งหมด'),
                ..._departments.map((d) {
                  final id   = (d['id'] as num?)?.toInt() ?? 0;
                  final name = (d['name_department'] as String?) ?? '';
                  return _categoryChip(id, name);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(int id, String label) {
    final selected = _selectedDeptId == id;
    return GestureDetector(
      onTap: () => _selectDept(id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansThai(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(icon: Icons.home_outlined,       activeIcon: Icons.home,       label: 'Home'),
      _NavItem(icon: Icons.menu_book_outlined,  activeIcon: Icons.menu_book,  label: 'My Courses'),
      _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Help'),
      _NavItem(icon: Icons.settings_outlined,  activeIcon: Icons.settings,   label: 'Setting'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item     = items[i];
              final selected = _currentIndex == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _currentIndex = i);
                  if (i == 1) _myCourseKey.currentState?.reload();
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color: selected ? AppTheme.primary : AppTheme.textLight,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 11,
                          color: selected ? AppTheme.primary : AppTheme.textLight,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Data models ─────────────────────────────────────────────────────────────

class _PackageInfo {
  final String badge;
  final String title;
  final int? originalPrice;
  final int salePrice;
  final List<Color> gradient;
  final IconData icon;
  final int id;
  final String? imageUrl;

  const _PackageInfo({
    required this.badge,
    required this.title,
    this.originalPrice,
    required this.salePrice,
    required this.gradient,
    required this.icon,
    required this.id,
    this.imageUrl,
  });
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;

  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
