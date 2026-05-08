import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class PackageDetailScreen extends StatelessWidget {
  const PackageDetailScreen({super.key});

  static const _courses = [
    _BundleCourse(
      order: 1,
      code: 'ADIN 4',
      title: 'ติว N4 N5 + A-Level ญี่ปุ่น ครูพี่โฮม',
      tag: 'ADINN5',
      price: 4500,
      gradient: [Color(0xFFFF7B8A), Color(0xFFE8273D)],
      icon: Icons.gps_fixed_rounded,
    ),
    _BundleCourse(
      order: 2,
      code: 'MINNA',
      title: 'Minna no Nihongo เล่ม 1-2 จาก 0 สู่ N5',
      tag: 'Minna',
      price: 2900,
      gradient: [Color(0xFFB58CFF), Color(0xFF7B3FE4)],
      icon: Icons.menu_book_rounded,
    ),
    _BundleCourse(
      order: 3,
      code: 'GRAMMAR',
      title: 'ไวยากรณ์ญี่ปุ่นพื้นฐาน พร้อมแบบฝึกหัด',
      tag: 'Grammar',
      price: 1990,
      gradient: [Color(0xFF59D6BE), Color(0xFF0B8F80)],
      icon: Icons.edit_note_rounded,
    ),
    _BundleCourse(
      order: 4,
      code: 'FIGHTO',
      title: 'เก็งข้อสอบ A-Level ภาษาญี่ปุ่น ออนไลน์',
      tag: 'FIGHTO PAT',
      price: 4500,
      gradient: [Color(0xFFFFB35C), Color(0xFFE85D04)],
      icon: Icons.workspace_premium_rounded,
    ),
    _BundleCourse(
      order: 5,
      code: 'KANJI',
      title: 'Reading คันจิ ศัพท์ A-Level ญี่ปุ่น N4 N5',
      tag: 'KanjiALevel',
      price: 1590,
      gradient: [Color(0xFF34D399), Color(0xFF047857)],
      icon: Icons.translate_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAF8),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  const SizedBox(height: 16),
                  _buildTitleBlock(),
                  const SizedBox(height: 14),
                  _buildPriceCard(),
                  const SizedBox(height: 16),
                  _buildBenefits(),
                  const SizedBox(height: 18),
                  _sectionTitle('ผู้สอน'),
                  const SizedBox(height: 10),
                  _buildTeacherCard(),
                  const SizedBox(height: 18),
                  _sectionTitle('คอร์สเรียนภายในแพ็กเกจสุดคุ้ม'),
                  const SizedBox(height: 4),
                  Text(
                    '5 คอร์ส · มูลค่ารวม ฿19,590',
                    style: GoogleFonts.sarabun(
                      fontSize: 12,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._courses.map(_courseCard),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBuyBar(context),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.primary,
                size: 26,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'แพ็กเกจสุดคุ้ม',
        style: GoogleFonts.sarabun(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHero() {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8FA0), Color(0xFFE83B52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE83B52).withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -18,
            child: _softCircle(96),
          ),
          Positioned(
            left: -28,
            bottom: -30,
            child: _softCircle(110),
          ),
          Positioned(
            right: 34,
            top: 42,
            child: Transform.rotate(
              angle: -0.18,
              child: const Icon(
                Icons.flag_circle_rounded,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 18,
            child: Row(
              children: [
                Text(
                  'ADMISSION',
                  style: GoogleFonts.sarabun(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                _heroBadge('1+2'),
              ],
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: _discountPill('-35%'),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '5 คอร์สรวม · ประหยัด ฿11,940',
                style: GoogleFonts.sarabun(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _softCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _heroBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.sarabun(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFE83B52),
        ),
      ),
    );
  }

  Widget _buildTitleBlock() {
    return Text(
      'ทดลองเรียน คอร์สเรียนภาษาญี่ปุ่นออนไลน์',
      style: GoogleFonts.sarabun(
        fontSize: 21,
        fontWeight: FontWeight.w900,
        color: AppTheme.textDark,
        height: 1.25,
      ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDF1EE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '฿7,650',
                      style: GoogleFonts.sarabun(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '฿19,590',
                      style: GoogleFonts.sarabun(
                        fontSize: 13,
                        color: AppTheme.textLight,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'เฉลี่ยเพียง ฿1,530 ต่อคอร์ส',
                  style: GoogleFonts.sarabun(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _discountPill('-35%'),
        ],
      ),
    );
  }

  Widget _discountPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5B72),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5B72).withOpacity(0.24),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.sarabun(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    const benefits = [
      'รวมคอร์สเลือกทุกระดับ จาก 0 - A-Level',
      'ราคาประหยัดกว่าซื้อแยก สูงสุด 35%',
      'ดูซ้ำได้ไม่จำกัด ตลอดอายุคอร์ส',
      'มี PDF ประกอบ + แบบฝึกหัดครบทุกบท',
      'ถาม-ตอบกับครูได้ ผ่าน Line OA',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _InfoChip(icon: Icons.layers_rounded, label: '5 คอร์ส'),
            _InfoChip(icon: Icons.event_available_rounded, label: '12 เดือน'),
            _InfoChip(icon: Icons.chat_rounded, label: 'ดูซ้ำได้'),
            _InfoChip(icon: Icons.description_rounded, label: 'ใบประกาศ'),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle('เกี่ยวกับแพ็กนี้'),
        const SizedBox(height: 10),
        ...benefits.map(
          (text) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 21,
                  height: 21,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.sarabun(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.sarabun(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE6A7),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
            child: const Icon(
              Icons.face_rounded,
              color: Color(0xFFE79500),
              size: 34,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ครูพี่โฮม ภาษาญี่ปุ่น',
                  style: GoogleFonts.sarabun(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ติว A-Level ญี่ปุ่น อันดับ 1 ของไทย',
                  style: GoogleFonts.sarabun(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppTheme.warning, size: 17),
              const SizedBox(width: 2),
              Text(
                '4.98',
                style: GoogleFonts.sarabun(
                  fontSize: 12,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _courseCard(_BundleCourse course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: course.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${course.order}',
                      style: GoogleFonts.sarabun(
                        fontSize: 12,
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -16,
                  top: -18,
                  child: _softCircle(82),
                ),
                Positioned(
                  right: 32,
                  top: 46,
                  child: Icon(
                    course.icon,
                    color: Colors.white.withOpacity(0.72),
                    size: 62,
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Text(
                    course.code,
                    style: GoogleFonts.sarabun(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: GoogleFonts.sarabun(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        course.tag,
                        style: GoogleFonts.sarabun(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '฿${_fmt(course.price)} บาท',
                      style: GoogleFonts.sarabun(
                        fontSize: 12,
                        color: AppTheme.priceRed,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBuyBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            SizedBox(
              width: 86,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '฿19,590',
                    style: GoogleFonts.sarabun(
                      fontSize: 11,
                      color: AppTheme.textLight,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Text(
                    '฿7,650',
                    style: GoogleFonts.sarabun(
                      fontSize: 20,
                      height: 1,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push('/payment', extra: {
                  'title': 'แพ็กเกจสุดคุ้ม ครูพี่โฮม All-in-One',
                  'price': 8990,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  'ซื้อแพ็กเกจสุดคุ้ม',
                  style: GoogleFonts.sarabun(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.sarabun(
              fontSize: 12,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleCourse {
  final int order;
  final String code;
  final String title;
  final String tag;
  final int price;
  final List<Color> gradient;
  final IconData icon;

  const _BundleCourse({
    required this.order,
    required this.code,
    required this.title,
    required this.tag,
    required this.price,
    required this.gradient,
    required this.icon,
  });
}
