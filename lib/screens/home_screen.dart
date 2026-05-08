import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../theme/app_theme.dart';
import '../widgets/course_card.dart';
import 'chat_screen.dart';
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
  final _bannerController = PageController();
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'ภาษาญี่ปุ่น', 'ภาษาเกาหลี', 'ภาษาจีน', 'ภาษาเยอรมัน', 'อื่นๆ'];

  final List<CourseModel> _courses = const [
    CourseModel(
      flashLabel: 'FLASH\nA-LEVEL',
      courseName: 'ติวโค้งสุดท้าย A-Level ญี่ปุ่น',
      rating: 5.0,
      students: 953,
      price: 3950,
      bgStart: Color(0xFFFF6B8A),
      bgEnd: Color(0xFFFF4757),
      icon: Icons.track_changes,
      tags: ['โค้งสุดท้าย'],
    ),
    CourseModel(
      flashLabel: 'FLASH\nA-LEVEL',
      courseName: 'ติวโค้งสุดท้าย A-Level ญี่ปุ่น Pro',
      rating: 5.0,
      students: 48,
      price: 3950,
      bgStart: Color(0xFFFF6B8A),
      bgEnd: Color(0xFFFF4757),
      icon: Icons.track_changes,
      tags: ['โค้งสุดท้าย'],
    ),
    CourseModel(
      flashLabel: 'FLASH\nN5',
      courseName: 'เรียนภาษาญี่ปุ่นเบื้องต้น N5',
      rating: 4.9,
      students: 1204,
      price: 2900,
      bgStart: Color(0xFF9B59B6),
      bgEnd: Color(0xFF6C3483),
      icon: Icons.local_florist,
      tags: ['N5 Basic'],
    ),
    CourseModel(
      flashLabel: 'FLASH\nเดือน',
      courseName: 'เรียนภาษาญี่ปุ่นพื้นฐาน 2 เดือน',
      rating: 4.8,
      students: 720,
      price: 2900,
      bgStart: Color(0xFFFF9F43),
      bgEnd: Color(0xFFEE5A24),
      icon: Icons.bolt,
      tags: ['Fast Track'],
    ),
  ];

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(),
          const MyCourseScreen(),
          const HelpScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomePage() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildBanner()),
          SliverToBoxAdapter(child: _buildPackages()),
          SliverToBoxAdapter(child: _buildCategorySection()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final filtered = _filteredCourses;
                  if (i >= filtered.length) return null;
                  return CourseCard(course: filtered[i]);
                },
                childCount: _filteredCourses.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  List<CourseModel> get _filteredCourses {
    if (_selectedCategory == 'All') return _courses;
    return _courses;
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryLight,
            child: Text(
              'K',
              style: GoogleFonts.sarabun(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POINT 509,849.5',
                  style: GoogleFonts.sarabun(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'kim kundad.,',
                  style: GoogleFonts.sarabun(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              ),
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

  Widget _buildBanner() {
    final banners = [
      _BannerData(
        label: 'Learnsbuy',
        title: 'ลด 40%',
        subtitle: 'แพ็คคู่ PAT + ญี่ปุ่น',
        note: 'PAT 300 เติมคะแนนประกวดประชัน',
        chips: ['G-MAN', 'dictasia', 'Dek-D'],
        gradient: [const Color(0xFF6C5CE7), const Color(0xFF4834D4)],
      ),
      _BannerData(
        label: 'โปรพิเศษ',
        title: 'N5 ฟรี!',
        subtitle: 'ลงทะเบียนวันนี้',
        note: 'เรียนได้ไม่จำกัด 30 วัน',
        chips: ['N5', 'Beginner'],
        gradient: [const Color(0xFF0FB5A6), const Color(0xFF0A8A7E)],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: banners.length,
              itemBuilder: (_, i) => _buildBannerCard(banners[i]),
            ),
          ),
          const SizedBox(height: 10),
          SmoothPageIndicator(
            controller: _bannerController,
            count: banners.length,
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

  Widget _buildBannerCard(_BannerData data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        data.label,
                        style: GoogleFonts.sarabun(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.title,
                  style: GoogleFonts.sarabun(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  data.subtitle,
                  style: GoogleFonts.sarabun(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: data.chips.map((chip) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      chip,
                      style: GoogleFonts.sarabun(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'อ้อมิ้ง\nสาระ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.sarabun(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'สุดคุ้ม',
                    style: GoogleFonts.sarabun(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: data.gradient.first,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackages() {
    final packages = [
      _PackageInfo(
        badge: 'พิเศษ 15%',
        title: 'AD1 + AD2 + เก็งข้อสอบ A-Level ญี่ปุ่น',
        originalPrice: 9000,
        salePrice: 7650,
        gradient: [const Color(0xFF2C3E7A), const Color(0xFF1a2460)],
        icon: Icons.school,
      ),
      _PackageInfo(
        badge: 'JAPAN ONLINE',
        title: 'เรียนภาษาญี่ปุ่นเบื้องต้นจาก 0 สู่ N4 (A-Level)',
        originalPrice: 14800,
        salePrice: 7400,
        gradient: [const Color(0xFFE8F4FF), const Color(0xFFBBDEFB)],
        icon: Icons.translate,
      ),
      _PackageInfo(
        badge: 'สอนสด',
        title: 'ติว A-Level ญี่ปุ่น สอนสด TCAS70 (เรียนออนไลน์ ย้อนได้) ครูพี่โฮม รีวิว',
        originalPrice: 5500,
        salePrice: 4950,
        gradient: [const Color(0xFF1a1a2e), const Color(0xFF16213e)],
        icon: Icons.live_tv,
      ),
      _PackageInfo(
        badge: 'NEW FIGHT',
        title: 'เก็งข้อสอบ A-Level ญี่ปุ่น สอนสด 2026 TCAS70',
        originalPrice: 5500,
        salePrice: 4950,
        gradient: [const Color(0xFF0F3460), const Color(0xFF533483)],
        icon: Icons.emoji_events,
      ),
      _PackageInfo(
        badge: 'FAST PASS N4',
        title: 'ติว N4 JLPT คอร์สติวสอบวัดระดับ N4 ภาษาญี่ปุ่น',
        originalPrice: 4500,
        salePrice: 3950,
        gradient: [const Color(0xFF6A0572), const Color(0xFF9B59B6)],
        icon: Icons.speed,
      ),
      _PackageInfo(
        badge: 'INTENSIVE N3',
        title: 'ติว N3 JLPT คอร์สติวสอบวัดระดับ N3 ภาษาญี่ปุ่น',
        originalPrice: 6500,
        salePrice: 5850,
        gradient: [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
        icon: Icons.menu_book,
      ),
      _PackageInfo(
        badge: 'FLASH A-LEVEL',
        title: 'ติว A-Level ภาษาญี่ปุ่น (จบใน 1 เดือน) ครูพี่โฮม',
        originalPrice: 4950,
        salePrice: 3950,
        gradient: [const Color(0xFFCC0000), const Color(0xFFFF4444)],
        icon: Icons.bolt,
      ),
      _PackageInfo(
        badge: 'ครูพี่โฮม',
        title: 'ทดลองเรียน คอร์สเรียนภาษาญี่ปุ่นออนไลน์ ฟรี',
        originalPrice: 0,
        salePrice: 0,
        gradient: [const Color(0xFF0FB5A6), const Color(0xFF0A8A7E)],
        icon: Icons.card_giftcard,
      ),
    ];

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
                  style: GoogleFonts.sarabun(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  'ทั้งหมด ›',
                  style: GoogleFonts.sarabun(
                    fontSize: 14,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: packages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _buildPackageCard(packages[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(_PackageInfo p) {
    final isFree = p.salePrice == 0;
    final hasDiscount = p.originalPrice != null && p.originalPrice! > p.salePrice;

    return GestureDetector(
      onTap: () => context.push('/package'),
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
          // Thumbnail
          SizedBox(
            height: 110,
            child: Stack(
              children: [
                Container(
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
                ),
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
                      style: GoogleFonts.sarabun(
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
                        style: GoogleFonts.sarabun(
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
          // Info
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
                      style: GoogleFonts.sarabun(
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
                      style: GoogleFonts.sarabun(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else ...[
                    if (hasDiscount)
                      Text(
                        'จากราคา ฿${_fmt(p.originalPrice!)}',
                        style: GoogleFonts.sarabun(
                          fontSize: 10,
                          color: AppTheme.textLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      'เหลือ ฿${_fmt(p.salePrice)}',
                      style: GoogleFonts.sarabun(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
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

  String _fmt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'คอร์สเรียนทั้งหมด',
            style: GoogleFonts.sarabun(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : AppTheme.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.border,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.sarabun(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppTheme.textMedium,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      _NavItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'My Course'),
      _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Help'),
      _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Setting'),
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
              final item = items[i];
              final selected = _currentIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
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
                        style: GoogleFonts.sarabun(
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

  Widget _buildPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.border),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.sarabun(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerData {
  final String label, title, subtitle, note;
  final List<String> chips;
  final List<Color> gradient;

  const _BannerData({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.note,
    required this.chips,
    required this.gradient,
  });
}

class _PackageInfo {
  final String badge;
  final String title;
  final int? originalPrice;
  final int salePrice;
  final List<Color> gradient;
  final IconData icon;

  const _PackageInfo({
    required this.badge,
    required this.title,
    this.originalPrice,
    required this.salePrice,
    required this.gradient,
    required this.icon,
  });
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;

  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
